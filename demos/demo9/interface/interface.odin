package interface

// import "core:fmt"
import rl "vendor:raylib"

import "spacelib:core"
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
            return &fonts.get_by_name(name).font_tr
        },
        terse_query_color_proc = proc (name: string) -> core.Color {
            return colors.get_by_name(name)
        },
        terse_draw_proc = proc (terse: ^terse.Terse) {
            partials.draw_terse(terse)
        },
        frame_overdraw_proc = partials.frame_overdraw,
        scissor_set_proc    = partials.scissor_set,
        scissor_clear_proc  = partials.scissor_clear,
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
