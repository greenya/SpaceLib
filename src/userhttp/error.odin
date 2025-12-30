package userhttp

import "core:mem"

@private Allocator_Error :: mem.Allocator_Error

Error :: union #shared_nil {
    // Memory allocation error.
    Allocator_Error,

    // Platform error:
    // - on the desktop, it equals to cURL's Error Code
    // - on the web, it is a simple enum
    //
    // `Response.error_msg` contains the details on this type of error.
    Platform_Error,

    // HTTP error (status code):
    // Status codes 200-299 are not used here and considered to be "no error" codes.
    Status_Code,
}

@private
error_type_name :: proc (error: Error) -> string {
    switch v in error {
    case Allocator_Error    : return "Allocator Error"
    case Platform_Error     : return "Platform Error"
    case Status_Code        : return "HTTP Error"
    case                    : unimplemented()
    }
}
