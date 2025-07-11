package demo9_interface

import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:terse"
import "spacelib:ui"

import "../colors"
import "../fonts"

import "partials"
import "screens/credits"
import "screens/home"
import "screens/player"
import "screens/settings"

@private ui_: ^ui.UI

get_ui :: #force_inline proc () -> ^ui.UI {
    assert(ui_ != nil)
    return ui_
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

    add_screens_layer()
    add_dropdowns_layer()
    // add_tooltips_layer()
    // add_notifications_layer()

    credits.add(screens_layer)
    home.add(screens_layer)
    player.add(screens_layer)
    settings.add(screens_layer)

    // ui.print_frame_tree(ui_.root /*, depth_max=2*/)
}

destroy :: proc () {
    delete(dropdowns_data)

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
