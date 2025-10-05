package spacelib_raylib_res2

import "base:runtime"
import "core:strings"

import "spacelib:core"

image_file_extensions := [] string { ".png", ".jpg", ".jpeg" }

@private Rect :: core.Rect
@private File :: runtime.Load_Directory_File

file_name :: proc (full_name: string) -> string {
    first_dot_idx := strings.index_byte(full_name, '.')
    return first_dot_idx >= 0 ? full_name[:first_dot_idx] : full_name
}

file_dot_ext :: proc (full_name: string) -> string {
    last_dot_idx := strings.last_index_byte(full_name, '.')
    return last_dot_idx >= 0 ? full_name[last_dot_idx:len(full_name)] : ""
}
