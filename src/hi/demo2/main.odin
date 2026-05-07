package main

import "core:fmt"
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
        debug_draw_rect = proc (rect: hi.Rect, thick: f32, color: [4] u8) {
            k2.draw_rect_outline(k2.Rect(rect), thick, color)
        },
    })

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
    if k2.key_is_held(.Left_Control) do ctx.views[0].flags += { .debug }; else do ctx.views[0].flags -= { .debug }
    hi.update_context(ctx, screen_size, {}, dt)

    return
}

main_draw :: proc () {
    k2.clear(k2.DARK_GRAY)

    hi.draw_context(ctx)

    k2.draw_text(fmt.tprintf("time: %.3f", k2.get_time()), {10,10}, 20, k2.LIGHT_GRAY)
    k2.draw_text(fmt.tprintf("dt: %.3f", k2.get_frame_time()), {10,30}, 20, k2.LIGHT_GRAY)
    k2.present()
}

on_draw_view :: proc (v: ^hi.View) {
    rect := k2.Rect(hi.ref_to_screen(ctx, v))
    k2.draw_rect(rect, {180,220,250,80})
    k2.draw_rect_outline(rect, 3, {180,220,250,80})
}
