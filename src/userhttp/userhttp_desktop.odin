#+build !js
#+private
package userhttp

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strings"
import "core:time"
import "vendor:curl"

Network_Error :: curl.code

platform_init :: proc () -> Network_Error {
    return curl.global_init(curl.GLOBAL_DEFAULT)
}

platform_destroy :: proc () {
    curl.global_cleanup()
}

platform_send :: proc (req: ^Request) {
    req.error = _curl_send(req)

    if err_net, ok := req.error.(Network_Error); ok {
        assert(err_net != .E_OK)
        cstr := curl.easy_strerror(err_net)
        req.error_msg = strings.clone_from(cstr, req.allocator) // ignore allocator error
    }
}

// TODO: use req.content
_curl_send :: proc (req: ^Request) -> (err: Error) {
    context.allocator = context.temp_allocator

    cu := curl.easy_init()
    defer curl.easy_cleanup(cu)

    // setup method

    req_method_lower := strings.to_lower(req.method) or_return
    custom_request: string

    switch req_method_lower {
    case "get"  : // do nothing, cURL default method is GET
    case "post" : curl.easy_setopt(cu, .POST, c.long(1)) or_return
    case        : custom_request = req.method
    }

    if custom_request != "" {
        custom_request_cstr := strings.clone_to_cstring(custom_request) or_return
        curl.easy_setopt(cu, .CUSTOMREQUEST, custom_request_cstr) or_return
    }

    // setup url and query params

    query_params_encoded := _percent_encoded_params(req.query) or_return
    url := len(query_params_encoded) > 0\
        ? fmt.tprintf("%s?%s", req.url, query_params_encoded)\
        : req.url
    url_cstr := strings.clone_to_cstring(url) or_return

    curl.easy_setopt(cu, .URL, url_cstr) or_return

    // setup headers

    cu_headers: ^curl.slist
    defer if cu_headers != nil do curl.slist_free_all(cu_headers)

    for p in req.headers {
        cstr := fmt.ctprintf("%s: %s", p.name, p.value)
        cu_headers = curl.slist_append(cu_headers, cast ([^] byte) cstr)
    }

    if cu_headers != nil {
        curl.easy_setopt(cu, .HTTPHEADER, cu_headers)
    }

    // setup content

    if req.content != nil do switch v in req.content {
    case [] Param:
        encoded := _percent_encoded_params(v) or_return
        encoded_cstr := strings.clone_to_cstring(encoded) or_return
        curl.easy_setopt(cu, .POSTFIELDS, encoded_cstr) or_return

    case [] byte:   // TODO: impl
    case string:    // TODO: impl
    }

    // setup extra details

    curl.easy_setopt(cu, .FOLLOWLOCATION, c.long(1)) or_return // allow auto process redirects (3xx status codes)

    if req.timeout > 0 {
        // if timeout is set, use at least 1ms, so its not rounded to 0 and have no effect
        timeout_ms := max(1, time.duration_milliseconds(req.timeout))
        curl.easy_setopt(cu, .TIMEOUT_MS, c.long(timeout_ms)) or_return
        curl.easy_setopt(cu, .CONNECTTIMEOUT_MS, c.long(min(timeout_ms, 5000))) or_return
    }

    // setup buffer for response header block

    header := make_([dynamic] byte) or_return

    curl.easy_setopt(cu, .HEADERFUNCTION, _header_callback) or_return
    curl.easy_setopt(cu, .HEADERDATA, &header) or_return

    // setup buffer for response content block

    content := make_([dynamic] byte) or_return

    curl.easy_setopt(cu, .WRITEFUNCTION, _write_callback) or_return
    curl.easy_setopt(cu, .WRITEDATA, &content) or_return

    // perform the request

    curl.easy_perform(cu) or_return

    // collect response code

    response_code: c.long
    curl.easy_getinfo(cu, .RESPONSE_CODE, &response_code) or_return

    // fill the response

    req.response = {}
    req.response.status = Status_Code(response_code)
    req.response.headers = create_headers_from_text(string(header[:]), req.allocator) or_return
    req.response.content = slice.clone(content[:], req.allocator) or_return

    return
}

_curl_escape :: proc (s: string, allocator := context.allocator) -> (result: string, err: mem.Allocator_Error) {
    // Since 7.82.0, the cURL handle (1st parameter) is ignored.
    cstr := curl.easy_escape(nil, cstring(raw_data(s)), c.int(len(s)))
    result = strings.clone_from_cstring(cstr, allocator) or_return
    curl.free(rawptr(cstr))
    return
}

_percent_encoded_params :: proc (params: [] Param, allocator := context.allocator) -> (result: string, err: mem.Allocator_Error) {
    if len(params) == 0 do return "", .None

    context.allocator = context.temp_allocator

    sb := strings.builder_make(allocator) or_return

    for p in params {
        separator := strings.builder_len(sb) > 0 ? "&" : ""
        name_encoded := _curl_escape(p.name) or_return
        value_encoded := _curl_escape(fmt.tprintf("%v", p.value)) or_return
        fmt.sbprintf(&sb, "%s%s=%s", separator, name_encoded, value_encoded)
    }

    result = strings.to_string(sb)
    return
}

_header_callback :: proc "c" (buffer: [^] byte, size: c.size_t, n_items: c.size_t, outstream: rawptr) -> c.size_t {
    context = runtime.default_context()

    buffer_size := size * n_items
    stream := cast (^[dynamic] byte) outstream

    // Check if buffer starts with "HTTP/", so this is the beginning of a new response.
    // There can be multiple headers, depends on redirects made by cURL automatically,
    // as we are using `FOLLOWLOCATION` option.
    if buffer_size>5 && buffer[0]=='H' && buffer[1]=='T' && buffer[2]=='T' && buffer[3]=='P' && buffer[4]=='/' {
        clear(stream)
    }

    append(stream, ..buffer[:buffer_size])

    return buffer_size
}

_write_callback :: proc "c" (buffer: [^] byte, size: c.size_t, n_items: c.size_t, outstream: rawptr) -> c.size_t {
    context = runtime.default_context()

    buffer_size := size * n_items
    stream := cast (^[dynamic] byte) outstream
    append(stream, ..buffer[:buffer_size])

    return buffer_size
}
