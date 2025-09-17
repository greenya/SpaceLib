#+build !js
#+private
package userfs

import "core:fmt"
import "core:path/filepath"
import os "core:os/os2"

@private
_app_name: string

_init :: proc (app_name: string) -> (err: os.Error) {
    _app_name = app_name

    path := _abs_path("", context.temp_allocator)
    fmt.printfln("[userfs] Using path: %s", path)

    if !os.exists(path) {
        err = os.make_directory_all(path)
        if err != nil do fmt.eprintfln("[userfs] Failed to os.make_directory_all(): %v", err)
    }

    return
}

_read :: proc (key: string, allocator := context.allocator) -> (data: [] byte, err: os.Error) {
    ensure(key != "")
    path := _abs_path(key, context.temp_allocator)
    if os.exists(path) {
        data, err = os.read_entire_file(path, allocator)
        if err != nil do fmt.eprintfln("[userfs] Failed to os.read_entire_file(): %v", err)
    }
    return
}

_write :: proc (key: string, data: [] byte) -> (err: os.Error) {
    ensure(key != "")
    path := _abs_path(key, context.temp_allocator)
    err = os.write_entire_file(path, data)
    if err != nil do fmt.eprintfln("[userfs] Failed to os.write_entire_file(): %v", err)
    return
}

_delete :: proc (key: string) -> (err: os.Error) {
    ensure(key != "")
    path := _abs_path(key, context.temp_allocator)
    err = os.remove(path)
    if err != nil do fmt.eprintfln("[userfs] Failed to os.remove(): %v", err)
    return
}

_reset :: proc () -> (err: os.Error) {
    path := _abs_path("", context.temp_allocator)
    err = os.remove_all(path)
    if err != nil do fmt.eprintfln("[userfs] Failed to os.remove_all(): %v", err)
    return
}

@private
_abs_path :: proc (key: string, allocator := context.allocator) -> string {
    ensure(_app_name != "", "app_name must be set; use init() once before any userfs calls")

    user_data_dir, err := os.user_data_dir(context.temp_allocator, roaming=true)
    if err != nil {
        fmt.eprintfln("[userfs] Failed to os.user_data_dir(): %v", err)
        user_data_dir = "userfs" // fallback to something, which is going to be near the executable
    }

    parts: [] string = key != ""\
        ? { user_data_dir, _app_name, key }\
        : { user_data_dir, _app_name }

    return filepath.join(parts[:], allocator)
}
