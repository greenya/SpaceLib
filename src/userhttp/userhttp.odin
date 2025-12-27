package userhttp

import "base:builtin"
import "core:mem"
import "core:strings"

@private make_              :: builtin.make
@private delete_            :: builtin.delete
@private Allocator_Error    :: mem.Allocator_Error

requests: [dynamic] ^Request

init :: proc () -> Platform_Error {
    return platform_init()
}

destroy :: proc () {
    platform_destroy()
}

tick :: proc () {
    // TODO: poll requests status
}

// Send the request.
//
// Allocates new request instance. Call `destroy_request()` to deallocate it later.
//
// If `method` is empty, it will be auto-set to:
// - "GET" if `content == nil`
// - "POST" if `content != nil`
//
// If `content != nil` and no "Content-Type" `header` is set, it will be auto-added with value:
// - `Content_Type_Params` for `content` of type `[] Param`
// - `Content_Type_Binary` for `content` of type `[] byte`
// - `Content_Type_JSON` for `content` of type `string` starts with `{` character
// - `Content_Type_XML` for `content` of type `string` starts with `<` character
// - `Content_Type_Text` for `content` of type `string` otherwise
send_request :: proc (init: Request, allocator := context.allocator) -> (req: ^Request, err: Allocator_Error) #optional_allocator_error {
    context.allocator = allocator

    init_method := init.method
    if init_method == "" {
        init_method = init.content == nil ? "GET" : "POST"
    }

    content_type: string
    if !param_exists(init.headers, "Content-Type") do switch v in init.content {
    case [] Param                               : content_type = Content_Type_Params
    case [] byte                                : content_type = Content_Type_Binary
    case string:
        v_trimmed := strings.trim_left(v, "\n\t ")
        switch {
        case strings.has_prefix(v_trimmed, "{") : content_type = Content_Type_JSON
        case strings.has_prefix(v_trimmed, "<") : content_type = Content_Type_XML
        case                                    : content_type = Content_Type_Text
        }
    }

    req = new(Request)
    req^ = {
        allocator   = allocator,
        method      = strings.clone(init_method) or_return,
        url         = strings.clone(init.url) or_return,
        query       = clone_params(init.query) or_return,
        headers     = clone_params(init.headers, append_content_type=content_type) or_return,
        content     = clone_content(init.content) or_return,
        timeout     = init.timeout,
    }

    append(&requests, req) or_return
    platform_send(req)

    return
}

destroy_request :: proc (req: ^Request) -> (err: Allocator_Error) {
    delete_         (req.method)            or_return
    delete_         (req.url)               or_return
    delete_params   (req.query)             or_return
    delete_params   (req.headers)           or_return
    delete_content  (req.content)           or_return
    delete_         (req.error_msg)         or_return
    delete_params   (req.response.headers)  or_return
    delete_         (req.response.content)  or_return
    return
}

@private
find_request_by_handle :: proc (handle: Platform_Handle) -> (req: ^Request, idx: int) {
    for r, i in requests do if r.handle == handle do return r, i
    return nil, -1
}

@private
destroy_request_by_handle :: proc (handle: Platform_Handle) {
    req, idx := find_request_by_handle(handle)
    if req != nil && idx >= 0 {
        unordered_remove(&requests, idx)
        destroy_request(req)
    }
}
