package main

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strings"
import "core:os"

import "../../core"
import "../../core/tracking_allocator"
import k2 "../../../../karl2d"

App :: struct {
    arena: mem.Dynamic_Arena,
    allocator: mem.Allocator,

    path: string,
    files: [] os.File_Info,
}

app: App

main :: proc () {
    context.allocator = tracking_allocator.init(verbosity=.minimal)
    defer {
        tracking_allocator.print()
        tracking_allocator.destroy()
    }

    k2.init(1280, 720, "demo3", { window_mode=.Windowed_Resizable })

    mem.dynamic_arena_init(&app.arena)
    app.allocator = mem.dynamic_arena_allocator(&app.arena)
    defer mem.dynamic_arena_destroy(&app.arena)

    home_path, _ := os.user_home_dir(context.temp_allocator)
    nav_to_path(home_path)

    for main_update() {
        main_draw()
        free_all(context.temp_allocator)
    }

    k2.shutdown()
}

main_update :: proc () -> (keep_running: bool) {
    keep_running = k2.update() && !k2.key_went_down(.Escape)

    return
}

main_draw :: proc () {
    k2.clear(core.gray2)
    k2.present()
}

nav_to_path :: proc (new_path: string) {
    fmt.println(#procedure, new_path)

    delete(app.path)
    delete(app.files)

    app.path = strings.clone(new_path, app.allocator)

    err: os.Error
    app.files, err = os.read_all_directory_by_path(app.path, context.temp_allocator)
    assert(err == nil)

    slice.sort_by(app.files, less=proc (i, j: os.File_Info) -> bool {
        switch {
        case i.type == .Directory && j.type == .Directory   : fallthrough
        case i.type != .Directory && j.type != .Directory   : return i.name < j.name
        case                                                : return i.type == .Directory
        }
    })

    for i in app.files {
        fmt.printfln("|%10v| %m %#v", i.type, i.size, i.name)
    }
}
