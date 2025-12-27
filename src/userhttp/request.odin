package userhttp

import "core:mem"
// import "core:strings"
import "core:time"

Request :: struct {
    allocator: mem.Allocator,

    handle: Platform_Handle,

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
    // For `Platform_Error`, the value is platform dependent:
    // - on the desktop, it is `curl.code` and `error_msg` contains value from `curl.easy_strerror()`
    // - on the web, this value is `.error` and `error_msg` contains exception message
    //
    // For `Status_Code`, the value will be set only when `status_code_category() != .success`,
    // e.g. it is not `2xx`. If you need to know exact code like "200 OK" or "202 Accepted",
    // see `response.status`.
    error: Error,

    // Error message of the `send()` call.
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

    // Received response after `send()` call.
    //
    // Only valid if call was successful or the `error` is a `Status_Code` error.
    response: Response,

    // Maximum time allowed for the request.
    //
    // If `0`, no timeout will be set (not recommended).
    timeout: time.Duration,

    ready: proc (req: ^Request),
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
    // `Allocator_Error` or `Platform_Error`.
    time: time.Duration,
}

// Sends the request. Also cleans up previous error and response details of the `req`.
//
// - On success, `err == nil` and `content == req.response.content`
// - On failure, `err != nil` and `content == nil`; additionally:
//      - `req.error == err`
//      - `req.error_msg` will be set in case error is a `Platform_Error`
//      - `req.response` will be set in case error is a `Status_Code` error
//
// On the web (Fetch API), requests are subject to browser CORS rules. Requests that succeed
// on native platforms may fail or be unreadable in browsers.
//
// More: [Cross-Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS)
// send :: proc (req: ^Request) {
//     err := reset_request(req)
//     if err != nil {
//         req.error = err
//         return
//     }

//     platform_send(req)

//     // start := time.now()
//     // platform_send(req)

//     // if req.error == nil {
//     //     req.response.time = time.since(start)
//     //     assert(req.response.status != .None)
//     //     if status_code_category(req.response.status) != .Successful {
//     //         req.error = req.response.status
//     //     }
//     // }

//     // return\
//     //     req.error == nil ? req.response.content : nil,
//     //     req.error
// }

// @private
// reset_request :: proc (req: ^Request) -> (err: Error) {
//     delete_params(req.response.headers) or_return
//     delete_(req.response.content) or_return
//     req.response = {}

//     delete_(req.error_msg) or_return
//     req.error_msg = ""
//     req.error = nil

//     req.handle = {}

//     return
// }
