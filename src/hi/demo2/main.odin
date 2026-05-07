package main

import hi ".."
import k2 "../../../../karl2d"

ctx: ^hi.Context

main :: proc () {
    k2.init(1280, 720, "demo", { window_mode=.Windowed_Resizable })

    ctx = hi.create_context({
        ref_size = {320,180},
        ref_font_height = 16,
        align_center = true,
        aspect_ratio_matching = -1,
        continuous_solving = true,
        debug_draw_line = proc (from, to: [2] f32, thick: f32, color: [4] u8) {
            k2.draw_line(from, to, thick, color)
        },
        debug_draw_text = proc (text: string, pos: [2] f32, color: [4] u8) {
            k2.draw_text(text, pos, 20, color)
        },
    })

    ctx.views[0].flags += { .debug }

    context.user_ptr = hi.begin_scope(ctx)
    add_dialog(
        name = "dialog_exit_game",
        title = "Exit Game?",
        content = "All unsaved progress will be lost. Proceed?",
        button1 = "Yes",
        button2 = "No",
        button3 = "Maybe",
        with_header_close_button = true,
    )
    hi.end_scope()

    hi.solve_context(ctx)
    hi.print_context(ctx)

    for main_update() {
        main_draw()
        free_all(context.temp_allocator)
    }

    hi.destroy_context(ctx)
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
    hi.update_context(ctx, screen_size, mouse_input, dt)

    return
}

main_draw :: proc () {
    k2.clear(k2.DARK_GRAY)
    hi.draw_context(ctx)
    k2.present()
}

on_draw_view :: proc (v: ^hi.View) {
    rect := k2.Rect(hi.ref_to_screen(ctx, v))
    k2.draw_rect(rect, {180,220,250,80})
}
