package partials

import rl "vendor:raylib"

import "spacelib:raylib/draw"
import "spacelib:ui"

scissor_set :: #force_inline proc (r: Rect) {
    if rl.IsKeyDown(.LEFT_CONTROL) do return
    rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h))
}

scissor_clear :: #force_inline proc () {
    if rl.IsKeyDown(.LEFT_CONTROL) do return
    rl.EndScissorMode()
}

frame_overdraw :: #force_inline proc (f: ^ui.Frame) {
    if !rl.IsKeyDown(.LEFT_CONTROL) do return
    draw.debug_frame(f)
    draw.debug_frame_layout(f)
    draw.debug_frame_anchors(f)
}
