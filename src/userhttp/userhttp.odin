package userhttp

import "core:mem"

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
