package userhttp

import "base:builtin"
import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strings"
import "core:time"

@private make_      :: builtin.make
@private delete_    :: builtin.delete

Request :: struct {
    allocator: mem.Allocator,

    // Request method.
    //
    // - `GET` (default)
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
    //
    // If set, the `Content-Type` header is required, and if missing the value will be auto-assigned:
    // - `Content_Type_Params` for `[] Param`
    // - `Content_Type_Binary` for `[] byte`
    // - `Content_Type_Text` for `string`
    content: Content,

    // Error of the `send()` call.
    //
    // This is `nil` for no error. Meaning the `send()` call was successful and `response` contains
    // the result.
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
    error_msg: string,

    // Total time taken by `send()`.
    // This includes sending the request and receiving the very last byte of the response.
    time: time.Duration,

    // Received response after `send()` call.
    //
    // Only valid if call was successful or the `error` is a `Status_Code` error.
    response: Response,
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

    // Received content, expected to be in form of `Content-Type` header.
    content: [] byte,
}

Param :: struct {
    name    : string,
    value   : Param_Value,
}

Param_Value :: union { i64, f64, string }

Content :: union {
    [] Param,
    [] byte,
    string,
}

make :: proc (init: Request, allocator := context.allocator) -> (req: Request, err: mem.Allocator_Error) #optional_allocator_error {
    req.allocator = allocator
    context.allocator = allocator

    content_type: string
    if header(init.headers, "content-type") == nil do switch _ in init.content {
    case [] Param   : content_type = Content_Type_Params
    case [] byte    : content_type = Content_Type_Binary
    case string     : content_type = Content_Type_Text
    }

    req.method  = strings.clone(init.method != "" ? init.method : "GET") or_return
    req.url     = strings.clone(init.url) or_return
    req.query   = params_clone(init.query) or_return
    req.headers = params_clone(init.headers, append_content_type=content_type) or_return
    req.content = content_clone(init.content) or_return

    return
}

delete :: proc (req: Request) -> (err: mem.Allocator_Error) {
    delete_(req.method) or_return
    delete_(req.url) or_return
    // delete_params(req.query) or_return
    // delete_params(req.headers) or_return
    // delete_content(req.content) or_return
    return
}

// Sends the request.
//
// - On success, `ok == true` and `content == req.response.content`
// - On failure, `ok == false` and `content == nil`; additionally:
//      - the `req.error_msg` will be set in case error is a `Network_Error`
//      - the `req.response` will be set in case error is a `Status_Code` error
//
// Note: Returned `content` is the same slice as `req.response.content`, and it will be deallocated
// on `delete(req)`, so clone it in case you need to keep it.
send :: proc (req: ^Request) -> (content: [] byte, ok: bool) {
    fmt.println(#procedure)
    fmt.println("req", req)

    start := time.now()
    platform_send(req)
    req.time = time.since(start)

    // if no allocator error and no network error -- check http status
    if req.error == nil && status_code_category(req.response.status) != .successful {
        assert(req.response.status != .None)
        req.error = req.response.status
    }

    ok = req.error == nil
    if ok do content = req.response.content
    return
}

// delete_response :: proc (res: Response) -> (err: mem.Allocator_Error) {
//     context.allocator = res.allocator

//     for h in res.headers {
//         delete(h.name) or_return
//         if v, ok := h.value.(string); ok do delete(v) or_return
//     }

//     delete(res.error_msg) or_return
//     delete(res.headers) or_return
//     delete(res.content) or_return

//     return
// }

header :: proc (headers: [] Param, name: string) -> Param_Value {
    for h in headers {
        if strings.equal_fold(name, h.name) {
            return h.value
        }
    }
    return nil
}

// @private
// param_as_string :: proc (params: [] Param, name: string, case_sensitive := false, allocator := context.allocator) -> (result: string, err: mem.Allocator_Error) {
//     for p in params {
//         if case_sensitive {
//             if name == p.name
//         }
//     }
// }

@private
params_clone :: proc (params: [] Param, append_content_type := "") -> (result: [] Param, err: mem.Allocator_Error) {
    count := len(params) + (append_content_type != "" ? 1 : 0)

    result = make_([] Param, count) or_return
    for p, i in params {
        result[i].name = strings.clone(p.name) or_return
        switch v in p.value {
        case i64, f64   : result[i].value = v
        case string     : result[i].value = strings.clone(v) or_return
        }
    }

    if append_content_type != "" {
        result[count-1] = {
            name    = strings.clone("Content-Type"),
            value   = strings.clone(append_content_type),
        }
    }

    return
}

@private
content_clone :: proc (content: Content) -> (result: Content, err: mem.Allocator_Error) {
    switch v in content {
    case [] Param   : result = params_clone(v) or_return
    case [] byte    : result = slice.clone(v) or_return
    case string     : result = strings.clone(v) or_return
    }
    return
}
