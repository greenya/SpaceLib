package spacelib_raylib_res

import "base:runtime"
import "core:fmt"

File :: struct {
    name: string,
    data: [] byte,
}

add_file :: proc (res: ^Res, name: string, data: [] byte) {
    fmt.ensuref(name not_in res.files, `File "%s" is already added.`, name)
    file := File { name=name, data=data }
    res.files[name] = file
}

add_files :: proc (res: ^Res, files: [] runtime.Load_Directory_File) {
    for file in files do add_file(res, file.name, file.data)
}
