#+build js
#+private
package userhttp

foreign import "userhttp"

@(default_calling_convention="contextless")
foreign userhttp {
    userhttp_send :: proc (req: [] byte, res: [] byte) -> i32 ---
}

Network_Error :: enum {
    ok,
    error,
}

platform_init :: proc () -> Network_Error {
    // nothing
    return .ok
}

platform_destroy :: proc () {
    // nothing
}

platform_send :: proc (req: Request, res: ^Response) {
    unimplemented()
}
