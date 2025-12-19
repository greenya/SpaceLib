package userhttp

import "core:fmt"

Request :: struct {
    method  : string,
    url     : string,
    query   : [] Param,
    headers : [] Param,
    content : Content,
}

Response :: struct {
    status  : int,
    headers : [] Param,
    content : Content,
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
Content_Type_Params :: "application/x-www-form-urlencoded; charset=UTF-8" // For content params
Content_Type_JSON   :: "application/json" // JSON is in UTF-8 by the standard. RFC 8259: No "charset" parameter is defined for this registration.
Content_Type_XML    :: "application/xml; charset=UTF-8"
Content_Type_Text   :: "text/plain; charset=UTF-8"

send :: proc (req: Request) -> Response {
    fmt.println(#procedure)
    fmt.println("req", req)
    return {}
}
