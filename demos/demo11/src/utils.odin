package main

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:core"

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
