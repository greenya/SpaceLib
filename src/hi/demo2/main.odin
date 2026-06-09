// |-raw-|
package main

import "../../core"
import "../../core/tracking_allocator"
import hi ".."
import k2 "../../../../karl2d"

App :: struct {
    ui: ^hi.Context,
    EXAMPLE: bit_field u8 {
        AAA: int | 2,
        BBB: int | 3,
        CCC: int | 3,
    },
}

app: App

main :: proc () {
    context.allocator = tracking_allocator.init(verbosity=.minimal)
    defer {
        tracking_allocator.print()
        tracking_allocator.destroy()
    }

    k2.init(1280, 720, "demo2", { window_mode=.Windowed_Resizable })

    app.ui = hi.create_context({
        ref_font_height = 20,
        on_scissor = proc (ctx: ^hi.Context, scissor: hi.Rect) {
            k2.set_scissor_rect(scissor != {} ? k2.Rect(scissor) : nil)
        },
        on_text_measure = proc (ctx: ^hi.Context, style: hi.Text_Style, type: hi.Text_Token_Type, text: string) -> [2] f32 {
            return k2.measure_text(text, ctx.ref_font_height)
        },
        on_draw_text = proc (v: ^hi.Visible_View) {
            it := hi.visible_text_iterate(v, filter={.word})
            for tok, tok_rect in hi.visible_text_next(&it) {
                k2.draw_text(tok.text, {tok_rect.x,tok_rect.y}, v.ctx.ref_font_height, it.style.color)
            }
        },
        debug_draw_line = proc (from, to: [2] f32, thick: f32, color: [4] u8) {
            k2.draw_line(from, to, thick, color)
        },
        debug_draw_text = proc (text: string, pos: [2] f32, color: [4] u8) {
            k2.draw_text(text, pos, 20, color)
        },
    })

    hi.add_view(app.ui.root, { text=#load("main.odin"), flags={.text,.fill_x} })

    hi.set_debug(app.ui.root, true)
    hi.solve_context(app.ui)
    hi.print_view_tree(app.ui.root)
    hi.print_visible_views(app.ui)

    for main_update() {
        main_draw()
        free_all(context.temp_allocator)
    }

    hi.destroy_context(app.ui)
    k2.shutdown()
}

main_update :: proc () -> (keep_running: bool) {
    keep_running = k2.update() && !k2.key_went_down(.Escape)

    dt := k2.get_frame_time()
    screen_size := k2.get_screen_size()
    mouse_input := hi.Mouse_Input {
        lmb_down = k2.mouse_button_is_held(.Left),
        screen_pos = k2.get_mouse_position(),
        wheel_delta = k2.get_mouse_wheel_delta(),
    }

    app.ui.ref_size = screen_size
    hi.update_context(app.ui, screen_size, mouse_input, dt)

    return
}

main_draw :: proc () {
    k2.clear(k2.DARK_GRAY)
    hi.draw_context(app.ui)
    k2.present()
}

draw_view :: proc (v: ^hi.Visible_View) {
    rect := k2.Rect(v.solved_rect)
    alpha := u8(v.solved_opacity * 255)
    k2.draw_rect(rect, {30,80,50,alpha})
    k2.draw_rect_outline(rect, 4, {30,180,50,alpha})
}
