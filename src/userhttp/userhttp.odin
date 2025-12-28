package userhttp

import "core:mem"
import "core:strings"

requests: [dynamic] ^Request

init :: proc (allocator := context.allocator) -> (err: Error) {
    requests = make([dynamic] ^Request, allocator) or_return
    platform_init() or_return
    return
}

destroy :: proc () -> (err: Allocator_Error) {
    platform_destroy()
    for req in requests do destroy_request(req) or_return
    delete(requests) or_return
    return
}

// Checks request status and calls `Request.ready()` callback.
tick :: proc () -> (err: Error) {
    platform_tick() or_return

    #reverse for req, idx in requests {
        if req.error != nil || req.response.status != .None {
            if req.ready != nil {
                req.ready(req)
            }
            unordered_remove(&requests, idx)
            destroy_request(req) or_return
        }
    }

    return
}

// Sends the request.
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
//
// The request will be allocated and sent; the `tick()` call will update its progress, once
// it is resolved (succeeded or failed), `req.ready()` callback will be called from `tick()`.
// The request will be deallocated by `tick()` right after `req.ready()` returns.
send_request :: proc (init: Request_Init) -> (err: Allocator_Error) {
    context.allocator = allocator()

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

    req := new(Request) or_return
    req^ = {
        method      = strings.clone(init_method) or_return,
        url         = strings.clone(init.url) or_return,
        query       = clone_params(init.query) or_return,
        headers     = clone_params(init.headers, append_content_type=content_type) or_return,
        content     = clone_content(init.content) or_return,
        timeout_ms  = init.timeout_ms,
        ready       = init.ready,
    }

    append(&requests, req) or_return
    platform_send(req)

    return
}

@private
find_request_by_handle :: proc (handle: Platform_Handle) -> (req: ^Request, idx: int) {
    for r, i in requests do if r.handle == handle do return r, i
    return nil, -1
}

@private
destroy_request :: proc (req: ^Request) -> (err: Allocator_Error) {
    delete          (req.method)            or_return
    delete          (req.url)               or_return
    delete_params   (req.query)             or_return
    delete_params   (req.headers)           or_return
    delete_content  (req.content)           or_return
    delete          (req.error_msg)         or_return
    delete_params   (req.response.headers)  or_return
    delete          (req.response.content)  or_return
    free            (req)                   or_return
    return
}

@private
allocator :: #force_inline proc () -> mem.Allocator {
    assert(requests.allocator != {}, "Allocator not set. Did you forget to call `userhttp.init()`?")
    return requests.allocator
}
