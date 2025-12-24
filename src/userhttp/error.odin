package userhttp

import "core:fmt"

Error :: union #shared_nil {
    // Memory allocation error.
    Allocator_Error,

    // Network error:
    // - on the desktop, it equals to cURL's Error Code
    // - on the web, it is a simple enum with `.None` and `.Error`
    //
    // `Response.error_msg` contains the details on this type of error.
    Network_Error,

    // HTTP error (status code):
    // Status codes 200-299 are not used here and considered to be "no error" codes.
    Status_Code,
}

print_error :: proc (error: Error, error_msg := "") {
    if error == nil do return

    type_name := error_type_name(error)
    if error_msg != "" {
        fmt.printfln("%s: (%i) %v: %s", type_name, error, error, error_msg)
    } else {
        fmt.printfln("%s: (%i) %v", type_name, error, error)
    }
}

@private
error_type_name :: proc (error: Error) -> string {
    switch v in error {
    case Allocator_Error    : return "Allocator Error"
    case Network_Error      : return "Network Error"
    case Status_Code        : return "HTTP Error"
    case                    : unimplemented()
    }
}
