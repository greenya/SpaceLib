package main

import "core:fmt"
import "../../core"
import "../../core/tracking_allocator"
import hi ".."
import k2 "../../../../karl2d"

App :: struct {
    ui: ^hi.Context,
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
        on_measure_text = proc (ctx: ^hi.Context, style: hi.Text_Style, type: hi.Text_Token_Type, text: string) -> (size: [2] f32) {
            font_size := f32(ctx.ref_font_height)
            size = k2.measure_text(text, font_size)
            return
        },
        on_draw_text = proc (v: ^hi.Active_View) {
            it := hi.active_view_text_token_iterate(v)
            for tok, tok_rect in hi.active_view_text_token_next(&it) {
                tok_rect_s := hi.ref_rect_to_screen(v.ctx, tok_rect)
                font_size_s := f32(v.ctx.screen_font_height) * it.style.font_scale
                k2.draw_text(tok.text, {tok_rect_s.x,tok_rect_s.y}, f32(v.ctx.screen_font_height), it.style.color)
                k2.draw_rect(k2.Rect(tok_rect_s), {100,0,0,80})
            }
        },
        debug_draw_line = proc (from, to: [2] f32, thick: f32, color: [4] u8) {
            k2.draw_line(from, to, thick, color)
        },
        debug_draw_text = proc (text: string, pos: [2] f32, color: [4] u8) {
            k2.draw_text(text, pos, 20, color)
        },
    })

    hi.set_debug(app.ui.root, true)
    hi.solve_context(app.ui)
    hi.print_view_tree(app.ui.root)
    hi.print_active_views(app.ui)

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

draw_view :: proc (v: ^hi.Active_View) {
    rect := k2.Rect(v.solved_rect)
    alpha := u8(v.solved_opacity * 255)
    k2.draw_rect(rect, {30,80,50,alpha})
    k2.draw_rect_outline(rect, 4, {30,180,50,alpha})
}
