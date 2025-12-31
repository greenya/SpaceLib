package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:terse"
import "spacelib:ui"
import "spacelib:userhttp"
import "res"

Vec2    :: core.Vec2
Vec3    :: core.Vec3
Rect    :: core.Rect
Color   :: core.Color

log     :: fmt.println
logf    :: fmt.printfln

log_build_info :: proc () {
    log("------------------------------------")
    log("ODIN_OS                :", ODIN_OS)
    log("ODIN_ARCH              :", ODIN_ARCH)
    log("ODIN_BUILD_MODE        :", ODIN_BUILD_MODE)
    log("ODIN_DEBUG             :", ODIN_DEBUG)
    log("ODIN_OPTIMIZATION_MODE :", ODIN_OPTIMIZATION_MODE)
    log("ODIN_DISABLE_ASSERT    :", ODIN_DISABLE_ASSERT)
    log("ODIN_NO_BOUNDS_CHECK   :", ODIN_NO_BOUNDS_CHECK)
    log("ODIN_NO_TYPE_ASSERT    :", ODIN_NO_TYPE_ASSERT)
    log("ODIN_VERSION           :", ODIN_VERSION)
    log("raylib.VERSION         :", rl.VERSION)
    log("------------------------------------")
}

log_request :: proc (req: ^userhttp.Request) {
    // userhttp.print_request(req)
    context.allocator = context.temp_allocator
    logf("[request] %s %s %s [%s; %M]",
        req.method,
        req.url,
        userhttp.request_state_text(req),
        userhttp.param_as_string(req.response.headers, "content-type"),
        len(req.response.content),
    )
}

open_url :: proc (url_name: string) {
    url := res.url(url_name, context.temp_allocator)
    cstr := strings.clone_to_cstring(url, context.temp_allocator)
    log(#procedure, cstr)
    rl.OpenURL(cstr)
}

click_terse_frame :: proc (f: ^ui.Frame) {
    hit_group := terse.group_hit(f.terse, f.ui.mouse.pos)
    if hit_group != nil && strings.has_prefix(hit_group.name, "link_") {
        open_url(hit_group.name)
    }
}
