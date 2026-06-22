package main

import "core:fmt"

import "../../core"
import "../../core/tracking_allocator"
import hi ".."
import k2 "../../../../karl2d"

log :: fmt.println
logf :: fmt.printfln

App :: struct {
    ui: ^hi.Context,
    panels_container: ^hi.View,
    panels: [dynamic] ^Panel,
}

app: App

main :: proc () {
    context.allocator = tracking_allocator.init(verbosity=.minimal)
    defer {
        tracking_allocator.print()
        tracking_allocator.destroy()
    }

    k2.init(1280, 720, "demo3", { window_mode=.Windowed_Resizable })
    defer k2.shutdown()

    app.ui = hi.create_context({
        ref_font_height = 20,
        on_scissor = proc (ctx: ^hi.Context, scissor: hi.Rect) {
            k2.set_scissor_rect(scissor != {} ? k2.Rect(scissor) : nil)
        },
        on_text_measure = proc (ctx: ^hi.Context, style: hi.Text_Style, type: hi.Text_Token_Type, text: string) -> [2] f32 {
            font_height := style.font_scale * ctx.screen_font_height
            return k2.measure_text(text, font_height)
        },
        on_draw_text = proc (v: ^hi.Visible_View) {
            it := hi.visible_text_iterate(v, filter={.word})
            for tok, tok_rect in hi.visible_text_next(&it) {
                font_height := it.style.font_scale * v.ctx.screen_font_height
                k2.draw_text(tok.text, {tok_rect.x,tok_rect.y}, font_height, it.style.color)
            }
        },
        scroll_step = 40,
    })
    defer hi.destroy_context(app.ui)

    app.panels_container = hi.add_view(app.ui.root, {
        flags   = { .fill_x, .fill_y, .scissor, .wheel_scroll_layout },
        layout  = { dir=.row, gap=10 },
        on_draw = proc (v: ^hi.Visible_View) {
            rect := k2.Rect(hi.viewport_rect(v))
            k2.draw_rect(rect, core.gray1)
        },
    })

    append(&app.panels, panel_create(app.panels_container, ""))
    defer {
        for p in app.panels do panel_destroy(p)
        delete(app.panels)
    }

    for main_update() {
        main_draw()
        free_all(context.temp_allocator)
    }
}

main_update :: proc () -> (keep_running: bool) {
    keep_running = k2.update() && !k2.key_went_down(.Escape)

    dt := k2.get_frame_time()
    screen_size := k2.get_screen_size()
    wheel_delta := k2.get_mouse_wheel_delta()
    mouse_input := hi.Mouse_Input {
        lmb_down = k2.mouse_button_is_held(.Left),
        screen_pos = k2.get_mouse_position(),
        wheel_delta = wheel_delta,
    }

    app.ui.ref_size = screen_size
    hi.update_context(app.ui, screen_size, mouse_input, dt)

    return
}

main_draw :: proc () {
    k2.clear(core.gray2)
    hi.draw_context(app.ui)
    k2.present()
}
