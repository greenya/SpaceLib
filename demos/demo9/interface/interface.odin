package interface

// import "core:fmt"
import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:terse"
import "spacelib:ui"

import "../colors"
import "../fonts"
import "../partials"

@private ui_: ^ui.UI

get_ui :: #force_inline proc () -> ^ui.UI {
    assert(ui_ != nil)
    return ui_
}

get_screens_layer :: #force_inline proc () -> ^ui.Frame {
    assert(screens.layer != nil)
    return screens.layer
}

create :: proc () {
    assert(ui_ == nil)

    ui_ = ui.create(
        terse_query_font_proc = proc (name: string) -> ^terse.Font {
            return &fonts.get(name).font_tr
        },
        terse_query_color_proc = proc (name: string) -> core.Color {
            return colors.get(name)
        },
        terse_draw_proc = proc (terse: ^terse.Terse) {
            partials.draw_terse(terse)
        },
        overdraw_proc = proc (f: ^ui.Frame) {
            if !rl.IsKeyDown(.LEFT_CONTROL) do return
            draw.debug_frame(f)
            draw.debug_frame_layout(f)
            draw.debug_frame_anchors(f)
        },
        scissor_set_proc = proc (r: core.Rect) {
            if rl.IsKeyDown(.LEFT_CONTROL) do return
            rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h))
        },
        scissor_clear_proc = proc () {
            if rl.IsKeyDown(.LEFT_CONTROL) do return
            rl.EndScissorMode()
        },
    )

    add_screens_layer(order=0, curtain_order=8)
    add_dropdowns_layer(order=1)
    // add_notifications_layer(order=2)
    // add_tooltips_layer(order=3)
    add_modals_layer(order=9)
}

destroy :: proc () {
    delete(dropdowns.data)

    ui.destroy(ui_)
    ui_ = nil
}

tick :: proc () {
    ui.tick(ui_,
        root_rect   = { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) },
        mouse       = {
            pos         = rl.GetMousePosition(),
            wheel_dy    = rl.GetMouseWheelMove(),
            lmb_down    = rl.IsMouseButtonDown(.LEFT),
        },
    )
}

draw :: proc () {
    ui.draw(ui_)
}
