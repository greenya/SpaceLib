package userhttp

import "core:mem"
import "core:strings"
import "core:time"

Request :: struct {
    allocator: mem.Allocator,

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

    // Error of the `send()` call.
    //
    // This is `nil` for no error. Meaning the `send()` call was successful and `response`
    // contains the result.
    //
    // For `Network_Error`, the value is platform dependent:
    // - on the desktop, it is `curl.code` and `error_msg` contains value from `curl.easy_strerror()`
    // - on the web, this value is `.error` and `error_msg` contains exception message
    //
    // For `Status_Code`, the value will be set only when `status_code_category() != .success`,
    // e.g. it is not `2xx`. If you need to know exact code like "200 OK" or "202 Accepted",
    // see `response.status`.
    error: Error,

    // Error message of the `send()` call.
    //
    // Only used with `Network_Error`, and contains platform dependent details (error message).
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

    // Received response after `send()` call.
    //
    // Only valid if call was successful or the `error` is a `Status_Code` error.
    response: Response,

    // Maximum time allowed for the request.
    //
    // If `0`, no timeout will be set (not recommended).
    timeout: time.Duration,
}

Response :: struct {
    // Received HTTP status code.
    status: Status_Code,

    // Received headers.
    //
    // - on the desktop, cURL returns all the headers
    // - on the web, Fetch API doesn't return all the headers (e.g. `Set-Cookie`)
    //
    // More:
    // - [Forbidden response header name](https://developer.mozilla.org/en-US/docs/Glossary/Forbidden_response_header_name)
    // - [Field Name Registry](https://www.iana.org/assignments/http-fields/http-fields.xhtml)
    headers: [] Param,

    // Received content, expected to be in form of "Content-Type" header.
    content: [] byte,

    // Total time taken by `send()`.
    //
    // This includes sending the request and receiving the very last byte of the response.
    // This value is set only after response is received. It will not be set on any
    // `Allocator_Error` or `Network_Error`.
    time: time.Duration,
}

// Allocates new request instance. Call `delete()` to deallocate it later.
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
make :: proc (init: Request, allocator := context.allocator) -> (req: Request, err: Allocator_Error) #optional_allocator_error {
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

    req.allocator   = allocator
    req.method      = strings.clone(init_method) or_return
    req.url         = strings.clone(init.url) or_return
    req.query       = clone_params(init.query) or_return
    req.headers     = clone_params(init.headers, append_content_type=content_type) or_return
    req.content     = clone_content(init.content) or_return
    req.timeout     = init.timeout

    return
}

// Deallocates request instance previously allocated by `make()`.
delete :: proc (req: Request) -> (err: Allocator_Error) {
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

// Sends the request. Also cleans up previous error and response details of the `req`.
//
// - On success, `err == nil` and `content == req.response.content`
// - On failure, `err != nil` and `content == nil`; additionally:
//      - `req.error == err`
//      - `req.error_msg` will be set in case error is a `Network_Error`
//      - `req.response` will be set in case error is a `Status_Code` error
//
// On the web (Fetch API), requests are subject to browser CORS rules. Requests that succeed
// on native platforms may fail or be unreadable in browsers.
//
// More: [Cross-Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS)
send :: proc (req: ^Request) -> (content: [] byte, err: Error) {
    err = clean_up_previous_response(req)
    if err != nil {
        req.error = err
        return
    }

    start := time.now()
    platform_send(req)

    if req.error == nil {
        req.response.time = time.since(start)
        assert(req.response.status != .None)
        if status_code_category(req.response.status) != .Successful {
            req.error = req.response.status
        }
    }

    return\
        req.error == nil ? req.response.content : nil,
        req.error
}

@private
clean_up_previous_response :: proc (req: ^Request) -> (err: Error) {
    delete_params(req.response.headers) or_return
    delete_(req.response.content) or_return
    req.response = {}

    delete_(req.error_msg) or_return
    req.error_msg = ""
    req.error = nil

    return
}
