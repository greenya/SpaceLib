package interface

import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:terse"
import "spacelib:ui"

import "../colors"
import "../fonts"
import "../partials"

import "../screens/conversation"
import "../screens/credits"
import "../screens/deposit"
import "../screens/home"
import "../screens/player"
import "../screens/settings"

import "dev"

@private ui_: ^ui.UI

create :: proc () {
    assert(ui_ == nil)

    terse.query_font = proc (name: string) -> ^terse.Font {
        return &fonts.get_by_name(name).font_tr
    }

    terse.query_color = proc (name: string) -> core.Color {
        return colors.get_by_name(name)
    }

    ui_ = ui.create(
        root_rect = { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) },
        terse_draw_proc = #force_inline proc (f: ^ui.Frame) {
            partials.draw_terse(f)
        },
        scissor_set_proc = #force_inline proc (r: core.Rect) {
            if !rl.IsKeyDown(.LEFT_CONTROL) do rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h))
        },
        scissor_clear_proc = #force_inline proc () {
            if !rl.IsKeyDown(.LEFT_CONTROL) do rl.EndScissorMode()
        },
        frame_overdraw_proc = #force_inline proc (f: ^ui.Frame) {
            if !rl.IsKeyDown(.LEFT_CONTROL) do return
            draw.debug_frame(f)
        },
    )

    add_screens_layer       (order=1, curtain_order=8)
    add_dropdowns_layer     (order=2)
    add_modals_layer        (order=3)
    add_tooltips_layer      (order=4)
    add_notifications_layer (order=5)

    conversation.add(screens.layer)
    credits.add(screens.layer)
    deposit.add(screens.layer)
    home.add(screens.layer)
    player.add(screens.layer)
    settings.add(screens.layer)

    dev.add_layer(ui_, order=99)
}

destroy :: proc () {
    destroy_dropdowns_layer()
    destroy_modals_layer()
    destroy_notifications_layer()

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
    dev.draw_ended()
}
