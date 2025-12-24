package userhttp

import "base:builtin"
import "core:mem"

@private make_              :: builtin.make
@private delete_            :: builtin.delete
@private Allocator_Error    :: mem.Allocator_Error

init :: proc () -> Network_Error {
    return platform_init()
}

destroy :: proc () {
    platform_destroy()
}
