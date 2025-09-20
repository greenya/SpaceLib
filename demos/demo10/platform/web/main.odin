package main_web

import "base:runtime"
import "core:log"
import "core:mem"

import app "../.."

web_context: runtime.Context

@export
platform_init :: proc "c" () {
    context = runtime.default_context()

    // The WASM allocator doesn't seem to work properly in combination with
    // emscripten. There is some kind of conflict with how the manage memory.
    // So this sets up an allocator that uses emscripten's malloc.
    context.allocator = emscripten_allocator()
    runtime.init_global_temporary_allocator(1*mem.Megabyte)

    context.logger = log.create_console_logger()

    web_context = context
    app.app_startup()
}

@export
platform_shutdown :: proc "c" () {
    context = web_context
    app.app_shutdown()
}

@export
platform_running :: proc "c" () -> bool {
    context = web_context
    return app.app_running()
}

@export
platform_update :: proc "c" () {
    context = web_context
    app.app_tick()
    app.app_draw()
}

@export
platform_resized :: proc "c" (w, h: i32) {
    context = web_context
    app.app_resized(w, h)
}
