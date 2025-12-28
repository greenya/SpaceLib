#+build !js
#+private
package userhttp

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import "core:slice"
import "core:strings"
import "vendor:curl"

Platform_Error :: curl.code

Platform_Handle :: struct {
    easy: ^curl.CURL,
}

Buffer :: struct {
    arena           : vmem.Arena,
    headers_list    : ^curl.slist,
    header          : [dynamic] byte,
    content         : [dynamic] byte,
}

buffers: map [^curl.CURL] ^Buffer

multi: ^curl.CURLM

platform_init :: proc (allocator := context.allocator) -> (err: Platform_Error) {
    curl.global_init(curl.GLOBAL_DEFAULT) or_return

    multi = curl.multi_init()
    if multi == nil do return .E_FAILED_INIT

    buffers = make(map [^curl.CURL] ^Buffer, allocator)

    return
}

platform_destroy :: proc () {
    delete(buffers)
    buffers = nil

    curl.multi_cleanup(multi)
    multi = nil

    curl.global_cleanup()
}

platform_send :: proc (req: ^Request) {
    req.error = curl_send(req)

    if err_net, ok := req.error.(Platform_Error); ok {
        assert(err_net != .E_OK)
        cstr := curl.easy_strerror(err_net)
        req.error_msg = strings.clone_from(cstr, req.allocator) or_else panic("allocator error")
    }
}

platform_tick :: proc () -> (err: Error) {
    running_handles: c.int // not used
    multi_err := curl.multi_perform(multi, &running_handles)
    #partial switch multi_err {
    case .OK, .CALL_MULTI_PERFORM: // nothing
    case: fmt.panicf("Failed to curl.multi_perform(): %v", multi_err)
    }

    // we expect this proc to be called quite often, so we process only one message per call

    msgs_in_queue: c.int // not used
    msg := curl.multi_info_read(multi, &msgs_in_queue)
    if msg != nil && msg.msg == .DONE {
        curl_ready(msg.easy_handle, msg.data.result) or_return
    }

    return
}

curl_send :: proc (req: ^Request) -> (err: Error) {
    easy := curl.easy_init()
    req.handle = { easy=easy }

    buf, buf_allocator := add_buffer(easy) or_return

    // setup method

    req_method_lower := strings.to_lower(req.method, context.temp_allocator) or_return
    custom_request: string

    switch req_method_lower {
    case "get"  : // do nothing, cURL default method is GET
    case "post" : curl.easy_setopt(easy, .POST, c.long(1)) or_return
    case        : custom_request = req.method
    }

    if custom_request != "" {
        cstr := strings.clone_to_cstring(custom_request, buf_allocator) or_return
        curl.easy_setopt(easy, .CUSTOMREQUEST, cstr) or_return
    }

    // setup url and query params

    query_params_encoded := percent_encoded_params(req.query, context.temp_allocator) or_return
    url := len(query_params_encoded) > 0\
        ? fmt.tprintf("%s?%s", req.url, query_params_encoded)\
        : req.url
    url_cstr := strings.clone_to_cstring(url, buf_allocator) or_return

    curl.easy_setopt(easy, .URL, url_cstr) or_return

    // setup headers

    for p in req.headers {
        cstr := fmt.ctprintf("%s: %s", p.name, p.value)
        buf.headers_list = curl.slist_append(buf.headers_list, cast ([^] byte) cstr)
    }

    if buf.headers_list != nil {
        curl.easy_setopt(easy, .HTTPHEADER, buf.headers_list)
    }

    // setup content

    if req.content != nil {
        post_fields: [] byte

        switch v in req.content {
        case [] Param:
            encoded := percent_encoded_params(v, buf_allocator) or_return
            post_fields = transmute ([] byte) encoded

        case [] byte:
            post_fields = v

        case string:
            post_fields = transmute ([] byte) v
        }

        if post_fields != nil {
            curl.easy_setopt(easy, .POSTFIELDS, raw_data(post_fields)) or_return
            curl.easy_setopt(easy, .POSTFIELDSIZE, c.long(len(post_fields))) or_return
        }
    }

    // setup extra options

    // allow auto process redirects (3xx status codes)
    curl.easy_setopt(easy, .FOLLOWLOCATION, c.long(1)) or_return

    if req.timeout_ms > 0 {
        curl.easy_setopt(easy, .TIMEOUT_MS, c.long(req.timeout_ms)) or_return
        curl.easy_setopt(easy, .CONNECTTIMEOUT_MS, c.long(min(req.timeout_ms, 10_000))) or_return
    }

    // setup header and data buffers

    curl.easy_setopt(easy, .HEADERFUNCTION, header_function_callback) or_return
    curl.easy_setopt(easy, .HEADERDATA, &buf.header) or_return

    curl.easy_setopt(easy, .WRITEFUNCTION, write_function_callback) or_return
    curl.easy_setopt(easy, .WRITEDATA, &buf.content) or_return

    // add "easy" handle to "multi" handle

    curl.multi_add_handle(multi, easy)

    return
}

curl_ready :: proc (easy: ^curl.CURL, code: curl.code) -> (err: Error) {
    defer {
        multi_err := curl.multi_remove_handle(multi, easy)
        if multi_err != .OK {
            fmt.panicf("Failed to curl.multi_remove_handle(): %v", multi_err)
        }

        curl.easy_cleanup(easy)
        remove_buffer(easy)
    }

    req, _ := find_request_by_handle({ easy=easy })
    assert(req != nil)

    req.handle = {}

    buf := buffers[easy]

    if req.error != nil {
        // the error was in the preparation phase, e.g. anything before curl.multi_add_handle() call;
        // we do nothing here, only cleanup at the end; the error is unchanged for the user to check
    } else {
        if code == .E_OK {
            assert(buf.header != nil)
            assert(buf.content != nil)

            response_code: c.long
            curl.easy_getinfo(easy, .RESPONSE_CODE, &response_code) or_return

            req.response = {
                status  = Status_Code(response_code),
                headers = create_headers_from_text(string(buf.header[:]), req.allocator) or_return,
                content = slice.clone(buf.content[:], req.allocator) or_return,
            }
        } else {
            req.error = code
            cstr := curl.easy_strerror(code)
            req.error_msg = strings.clone_from(cstr, req.allocator) or_return
        }
    }

    return
}

add_buffer :: proc (easy: ^curl.CURL) -> (buf: ^Buffer, buf_allocator: mem.Allocator, err: Allocator_Error) {
    buf = new(Buffer) or_return
    buf_allocator = vmem.arena_allocator(&buf.arena)

    buf.header = make([dynamic] byte, buf_allocator) or_return
    buf.content = make([dynamic] byte, buf_allocator) or_return

    assert(easy not_in buffers)
    buffers[easy] = buf

    return
}

remove_buffer :: proc (easy: ^curl.CURL) {
    buf := buffers[easy]
    assert(buf != nil)

    delete_key(&buffers, easy)

    if buf.headers_list != nil {
        curl.slist_free_all(buf.headers_list)
    }

    vmem.arena_destroy(&buf.arena)
    free(buf)
}

curl_escape :: proc (s: string, allocator := context.allocator) -> (result: string, err: Allocator_Error) {
    // Since 7.82.0, the cURL handle (1st parameter) is ignored.
    cstr := curl.easy_escape(nil, cstring(raw_data(s)), c.int(len(s)))
    result = strings.clone_from_cstring(cstr, allocator) or_return
    curl.free(rawptr(cstr))
    return
}

percent_encoded_params :: proc (params: [] Param, allocator := context.allocator) -> (result: string, err: Allocator_Error) {
    if len(params) == 0 do return "", .None

    sb := strings.builder_make(allocator) or_return

    for p in params {
        separator := strings.builder_len(sb) > 0 ? "&" : ""
        name_encoded := curl_escape(p.name, context.temp_allocator) or_return
        value_encoded := curl_escape(fmt.tprintf("%v", p.value), context.temp_allocator) or_return
        fmt.sbprintf(&sb, "%s%s=%s", separator, name_encoded, value_encoded)
    }

    result = strings.to_string(sb)
    return
}

header_function_callback :: proc "c" (buffer: [^] byte, size: c.size_t, n_items: c.size_t, outstream: rawptr) -> c.size_t {
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

write_function_callback :: proc "c" (buffer: [^] byte, size: c.size_t, n_items: c.size_t, outstream: rawptr) -> c.size_t {
    context = runtime.default_context()

    buffer_size := size * n_items
    stream := cast (^[dynamic] byte) outstream
    append(stream, ..buffer[:buffer_size])

    return buffer_size
}
