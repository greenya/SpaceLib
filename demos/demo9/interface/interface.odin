package interface

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:raylib/env"
import "spacelib:terse"
import "spacelib:ui"

import "../colors"
import "../fonts"
import "../partials"

import "../screens/conversation"
import "../screens/credits"
import "../screens/home"
import "../screens/player"
import "../screens/settings"

import "dev"

@private ui_: ^ui.UI

create :: proc () {
    assert(ui_ == nil)

    ui_ = ui.create(
        root_rect = core.rect_from_size(env.window_size()),
        terse_query_font_proc = #force_inline proc (name: string) -> ^terse.Font {
            return &fonts.get_by_name(name).font_tr
        },
        terse_query_color_proc = #force_inline proc (name: string) -> core.Color {
            return colors.get_by_name(name)
        },
        terse_draw_proc = #force_inline proc (f: ^ui.Frame) {
            partials.draw_terse(f)
        },
        scissor_set_proc = #force_inline proc (r: core.Rect) {
            if !env.key_down(.LEFT_CONTROL) do env.scissor_set(r)
        },
        scissor_clear_proc = #force_inline proc () {
            if !env.key_down(.LEFT_CONTROL) do env.scissor_clear()
        },
        frame_overdraw_proc = #force_inline proc (f: ^ui.Frame) {
            if !env.key_down(.LEFT_CONTROL) do return
            draw.debug_frame(f)
            draw.debug_frame_scissor(f)
            draw.debug_frame_anchors(f)
            draw.debug_frame_layout(f)
        },
    )

    add_screens_layer(order=1, curtain_order=8)
    // add_notifications_layer(order=2)
    add_modals_layer(order=3)
    add_dropdowns_layer(order=4)
    // add_tooltips_layer(order=5)

    conversation.add(screens.layer)
    credits.add(screens.layer)
    home.add(screens.layer)
    player.add(screens.layer)
    settings.add(screens.layer)

    dev.add_layer(ui_, order=99)
}

destroy :: proc () {
    delete(dropdowns.data)

    ui.destroy(ui_)
    ui_ = nil
}

tick :: proc () {
    ui.tick(ui_,
        root_rect   = core.rect_from_size(env.window_size()),
        mouse       = {
            pos         = env.mouse_pos(),
            wheel_dy    = env.mouse_wheel_dy(),
            lmb_down    = env.mouse_button_down(.LEFT),
        },
    )
}

draw :: proc () {
    ui.draw(ui_)
    dev.draw_ended()
}
