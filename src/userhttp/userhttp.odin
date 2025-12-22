package userhttp

import "core:mem"
import "core:slice"
import "core:strings"

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
    // `Response.error_msg` contains the details on this type of error.
    Network_Error,

    // HTTP error (status code):
    // Status codes 200-299 are not used here and considered to be "no error" codes.
    Status_Code,
}

init :: proc () -> Network_Error {
    return platform_init()
}

destroy :: proc () {
    platform_destroy()
}

@private
create_headers_from_text :: proc (text: string, allocator: mem.Allocator) -> (headers: [] Param, err: mem.Allocator_Error) {
    headers_temp := make_([dynamic] Param, context.temp_allocator) or_return

    for line in strings.split_lines(text, context.temp_allocator) or_return {
        if line == "" do continue

        pair := strings.split_n(line, ":", 2, context.temp_allocator) or_return
        if len(pair) != 2 do continue

        name := strings.trim(pair[0], " \t")
        if name == "" do continue

        value := strings.trim(pair[1], " \t")
        if value == "" do continue

        append(&headers_temp, Param {
            name    = strings.clone(name, allocator) or_return,
            value   = strings.clone(value, allocator) or_return,
        })
    }

    headers = slice.clone(headers_temp[:], allocator)
    return
}
