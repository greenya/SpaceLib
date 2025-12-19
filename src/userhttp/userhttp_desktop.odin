#+build !js
#+private
package userhttp

import "base:runtime"
import "core:c"
import "core:slice"
import "core:strings"
import "vendor:curl"

Network_Error :: curl.code

platform_init :: proc () -> Network_Error {
    return curl.global_init(curl.GLOBAL_DEFAULT)
}

platform_destroy :: proc () {
    curl.global_cleanup()
}

platform_send :: proc (req: Request, res: ^Response) {
    res.error = _curl_send(req, res)

    if err_net, ok := res.error.(Network_Error); ok {
        assert(err_net != .E_OK)
        cstr := curl.easy_strerror(err_net)
        res.error_msg = strings.clone_from(cstr, res.allocator) // ignore allocator error
    }
}

// TODO: use req.query
// TODO: use req.headers
// TODO: use req.content
_curl_send :: proc (req: Request, res: ^Response) -> (err: Error) {
    cu := curl.easy_init()
    defer curl.easy_cleanup(cu)

    // setup method

    req_method_lower := strings.to_lower(req.method, context.temp_allocator) or_return
    custom_request: string

    switch req_method_lower {
    case "get"  : // do nothing, cURL default method is GET
    case "post" : curl.easy_setopt(cu, .POST, c.long(1)) or_return
    case        : custom_request = req.method
    }

    if custom_request != "" {
        custom_request_cstr := strings.clone_to_cstring(custom_request, context.temp_allocator) or_return
        curl.easy_setopt(cu, .CUSTOMREQUEST, custom_request_cstr) or_return
    }

    // setup request details

    url_cstr := strings.clone_to_cstring(req.url, context.temp_allocator) or_return

    curl.easy_setopt(cu, .URL, url_cstr) or_return
    curl.easy_setopt(cu, .FOLLOWLOCATION, c.long(1)) or_return // allow auto process redirects (3xx status codes)

    // setup buffer for response header block

    header := make([dynamic] byte, context.temp_allocator) or_return

    curl.easy_setopt(cu, .HEADERFUNCTION, _header_callback) or_return
    curl.easy_setopt(cu, .HEADERDATA, &header) or_return

    // setup buffer for response content block

    content := make([dynamic] byte, context.temp_allocator) or_return

    curl.easy_setopt(cu, .WRITEFUNCTION, _write_callback) or_return
    curl.easy_setopt(cu, .WRITEDATA, &content) or_return

    // perform the request

    curl.easy_perform(cu) or_return

    // collect response code

    response_code: c.long
    curl.easy_getinfo(cu, .RESPONSE_CODE, &response_code) or_return

    // fill the response

    res.status = Status_Code(response_code)
    res.headers = create_headers_from_text(string(header[:]), res.allocator) or_return
    res.content = slice.clone(content[:], res.allocator) or_return

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
