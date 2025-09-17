package userfs

// Common usage:
//
//      import "spacelib:userfs"
//      main :: proc () {
//          userfs.init("MyAppName")
//          ...
//          bytes := userfs.read("options.file", context.temp_allocator)
//          if bytes != nil {
//              ...use bytes...
//          }
//          ...
//          userfs.write("options.file", bytes)
//      }

init :: proc (app_name: string) {
    _init(app_name)
}

read :: proc (key: string, allocator := context.allocator) -> [] byte {
    data, _ := _read(key, allocator)
    return data
}

write :: proc (key: string, data: [] byte) {
    _write(key, data)
}

delete :: proc (key: string) {
    _delete(key)
}

reset :: proc () {
    _reset()
}
