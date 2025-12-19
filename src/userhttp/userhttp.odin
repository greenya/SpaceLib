package userhttp

import "core:fmt"
import "core:mem"

Request :: struct {
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
}

Response :: struct {
    allocator: mem.Allocator,

    // Error.
    //
    // This is the same value as returned by `send()`.
    error: Error,

    // Error message.
    //
    // Only used with `Network_Error`, and contains platform dependent details (error message).
    // For `Allocator_Error` and `Status_Code` errors, the value is empty.
    error_msg: string,

    // HTTP status code.
    //
    // - `1xx`: Informational - Request received, continuing process
    // - `2xx`: Success - The action was successfully received, understood, and accepted
    // - `3xx`: Redirection - Further action must be taken in order to complete the request
    // - `4xx`: Client Error - The request contains bad syntax or cannot be fulfilled
    // - `5xx`: Server Error - The server failed to fulfill an apparently valid request
    //
    // Note: In practice the codes `1xx` and `3xx` will not be returned; when redirection response
    // received, it will be followed automatically, and only the final response will be returned.
    //
    // More: [Status Code Registry](https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml)
    status: Status_Code,

    // Received headers.
    //
    // Notes:
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
    value   : union { i64, f64, string },
}

Content :: union {
    [] Param,
    [] byte,
    string,
}

Content_Type_Binary :: "application/octet-stream"
Content_Type_Params :: "application/x-www-form-urlencoded; charset=UTF-8"
Content_Type_JSON   :: "application/json" // JSON is in UTF-8 by the standard. RFC 8259: No "charset" parameter is defined for this registration.
Content_Type_XML    :: "application/xml; charset=UTF-8"
Content_Type_Text   :: "text/plain; charset=UTF-8"

Error :: union #shared_nil {
    // Memory allocation error.
    mem.Allocator_Error,

    // Network error:
    // - on the desktop, it equals to cURL's Error Code
    // - on the web, it is a simple enum with `.ok` and `.error`
    //
    // Note: `Response.error_msg` contains the details on this type of error.
    Network_Error,

    // HTTP error (status code):
    // Status codes 200-299 are not used here and considered to be "no error" codes.
    Status_Code,
}

// Sends the request.
//
// - `res` should be deleted via `delete_response()` regardless of `ok` and `res.error`
// - `ok` is:
//      - `true` if the response was successfully received and `status_code_kind(res.status) == .success`;
//      if you need to know exact code like "200 OK" or "202 Accepted", see the `res.status`
//      - `false` if there was an error, which can be one of:
//          - `Allocator_Error`: `res` is fully invalid
//          - `Network_Error`: `res` is partially valid, only `res.error` and `res.error_msg` are valid
//          - `Status_Code`: `res` is fully valid
send :: proc (req: Request, allocator := context.allocator) -> (res: Response, ok: bool) {
    fmt.println(#procedure)
    fmt.println("req", req)

    res.allocator = allocator
    // res.headers = ...
    // res.content = ...

    return
}

delete_response :: proc (res: Response) -> (err: mem.Allocator_Error) {
    delete(res.error_msg, res.allocator) or_return
    delete(res.headers, res.allocator) or_return
    delete(res.content, res.allocator) or_return
    return
}
