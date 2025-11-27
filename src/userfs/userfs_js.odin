#+build js
#+private
package userfs

import "core:mem"

foreign import "userfs"

@(default_calling_convention="contextless")
foreign userfs {
    userfs_init     :: proc (app_name: string)                      ---
    userfs_read     :: proc (key: string, data: [] byte) -> i32     ---
    userfs_write    :: proc (key: string, data: [] byte)            ---
    userfs_delete   :: proc (key: string)                           ---
    userfs_reset    :: proc ()                                      ---
}

_init :: proc (app_name: string) {
    userfs_init(app_name)
}

// we use "_not_used_: bool" because importing "core:os/os2" in web build gives a lot of errors,
// so we cannot properly return os2.Error type
_read :: proc (key: string, allocator := context.allocator) -> (data: [] byte, _not_used_: bool) {
    buffer := make([] byte, 16*mem.Kilobyte, context.temp_allocator)
    buffer_used := userfs_read(key, buffer)

    if buffer_used < 0 {
        // buffer too small, retry with exact needed size
        buffer_size_needed := abs(buffer_used)
        buffer = make([] byte, buffer_size_needed, context.temp_allocator)
        buffer_used = userfs_read(key, buffer)
    }

    if buffer_used > 0 {
        ensure(int(buffer_used) <= len(buffer))
        data = make([] byte, buffer_used, allocator)
        mem.copy_non_overlapping(raw_data(data), raw_data(buffer), int(buffer_used))
    }

    return
}

_write :: proc (key: string, data: [] byte) {
    userfs_write(key, data)
}

_delete :: proc (key: string) {
    userfs_delete(key)
}

_reset :: proc () {
    userfs_reset()
}
