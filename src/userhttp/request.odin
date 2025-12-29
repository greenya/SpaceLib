package userhttp

import "core:mem"
import "core:strings"

Request_Init :: struct {
    // Request method.
    //
    // - `GET`
    // - `POST`
    // - `PUT`
    // - `PATCH`
    // - `DELETE`
    // - `OPTIONS`
    // - `HEAD`
    //
    // More:
    // - [Fetch: Cross-Origin Requests](https://javascript.info/fetch-crossorigin)
    // - [Method Registry](https://www.iana.org/assignments/http-methods/http-methods.xhtml)
    method: string,

    // Request URL.
    //
    // More: [What is URL?](https://developer.mozilla.org/en-US/docs/Learn_web_development/Howto/Web_mechanics/What_is_a_URL)
    url: string,

    // Query parameters to be percent-encoded and sent as part of the `url`.
    query: [] Param,

    // Request headers.
    //
    // More:
    // - [Forbidden request header](https://developer.mozilla.org/en-US/docs/Glossary/Forbidden_request_header)
    // - [Field Name Registry](https://www.iana.org/assignments/http-fields/http-fields.xhtml)
    headers: [] Param,

    // The content.
    content: Content,

    // Maximum time allowed for the request. `0` for no timeout (not recommended).
    timeout_ms: int,

    // Optional callback. Called from `tick()` when request is resolved (succeeded or failed).
    // Once this callback is finished, `tick()` will deallocated the request automatically.
    //
    // IMPORTANT: Request pointer is only valid during ready(). Clone values if you need.
    ready: Ready_Proc,
}

Request :: struct {
    allocator   : mem.Allocator,
    handle      : Platform_Handle,
    using init  : Request_Init,

    // Error status.
    //
    // For `Platform_Error`, the value is platform dependent:
    // - on the desktop, it is `curl.code` and `error_msg` contains value from `curl.easy_strerror()`
    // - on the web, this value is `.error` and `error_msg` contains exception message
    //
    // For `Status_Code`, the value will be set only when `status_code_category() != .success`,
    // e.g. it is not `2xx`. If you need to know exact code like "200 OK" or "202 Accepted",
    // see `response.status`.
    error: Error,

    // Error message.
    //
    // Only used with `Platform_Error`, and contains platform dependent details (error message).
    // For other errors (`Allocator_Error`, `Status_Code`) this value is empty.
    //
    // On the web (Fetch API), this value might be very general, like "TypeError: Failed to fetch",
    // which might indicate variety of issues:
    // - CORS rejection
    // - DNS failure
    // - TLS failure
    // - Network unreachable
    // - Connection refused
    // - Mixed content block
    // - Ad blocker / extension interference
    //
    // The issue itself can only be seen in the browser console (e.g. "net::ERR_NAME_NOT_RESOLVED").
    //
    // More: [Window: fetch() method](https://developer.mozilla.org/en-US/docs/Web/API/Window/fetch)
    error_msg: string,

    // Received response.
    //
    // Only valid if `error == nil` or it is a `Status_Code` error.
    response: Response,
}

Ready_Proc :: proc (req: ^Request)

@private
create_request :: proc (init: Request_Init, allocator := context.allocator) -> (req: ^Request, err: Allocator_Error) {
    init_method := init.method
    if init_method == "" {
        init_method = init.content == nil ? "GET" : "POST"
    }

    auto_content_type: string
    if !param_exists(init.headers, "Content-Type") do switch v in init.content {
    case [] Param                               : auto_content_type = Content_Type_Params
    case [] byte                                : auto_content_type = Content_Type_Binary
    case string:
        v_trimmed := strings.trim_left(v, "\n\t ")
        switch {
        case strings.has_prefix(v_trimmed, "{") : auto_content_type = Content_Type_JSON
        case strings.has_prefix(v_trimmed, "<") : auto_content_type = Content_Type_XML
        case                                    : auto_content_type = Content_Type_Text
        }
    }

    if init.content != nil {
        if  strings.equal_fold(init_method, "GET")\
        ||  strings.equal_fold(init_method, "HEAD") {
            panic("A request using the GET or HEAD method cannot have a content")
        }
    }

    req             = new(Request) or_return
    req.allocator   = allocator
    req.method      = strings.clone(init_method, allocator)
    req.url         = strings.clone(init.url, allocator) or_return
    req.query       = clone_params(init.query, allocator=allocator) or_return
    req.headers     = clone_params(init.headers, append_content_type=auto_content_type, allocator=allocator) or_return
    req.content     = clone_content(init.content, allocator) or_return
    req.timeout_ms  = init.timeout_ms
    req.ready       = init.ready

    return
}

@private
destroy_request :: proc (req: ^Request) -> (err: Allocator_Error) {
    // horrible list of deallocations of things that has same life time;
    // i tried to use vmem.Arena but it doesn't work with web build

    delete          (req.method)            or_return
    delete          (req.url)               or_return
    delete_params   (req.query)             or_return
    delete_params   (req.headers)           or_return
    delete_content  (req.content)           or_return
    delete          (req.error_msg)         or_return
    delete_params   (req.response.headers)  or_return
    delete          (req.response.content)  or_return

    req^ = {}   // zero memory, so if user stores pointer after ready(),
                // it better crash as soon as possible

    free            (req)                   or_return

    return
}
