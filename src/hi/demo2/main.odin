package main

import "core:fmt"
import hi ".."
import k2 "../../../../karl2d"

ctx: hi.Context

main :: proc () {
    k2.init(1280, 720, "demo", { window_mode=.Windowed_Resizable })

    ctx = hi.create_context({
        ref_size = {400,225},
        ref_font_height = 16,
        align_center = true,
        aspect_ratio_matching = -1,
        on_draw_view = draw_view,
    })

    context.user_ptr = hi.begin_scope(&ctx)
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

    // hi.update_context(&ctx, {1280,720}, {}, 0.01)
    // hi.print_tree(ctx)

    for main_update() {
        main_draw()
        free_all(context.temp_allocator)
    }

    hi.destroy_context(&ctx)
    k2.shutdown()
}

main_update :: proc () -> (keep_running: bool) {
    keep_running = k2.update() && !k2.key_went_down(.Escape)

    dt := k2.get_frame_time()
    screen_size := k2.get_screen_size()
    hi.update_context(&ctx, screen_size, {}, dt)

    return
}

main_draw :: proc () {
    k2.clear(k2.DARK_GRAY)

    hi.draw_context(ctx)

    pos := hi.ref_to_screen(ctx, 0)
    size := ctx.ref_size * ctx.screen_pixel_scale
    rect := k2.Rect { pos.x, pos.y, size.x, size.y }
    k2.draw_rect_outline(rect, 3, k2.YELLOW)

    k2.draw_text(fmt.tprintf("time: %.3f", k2.get_time()), {10,10}, 20, k2.LIGHT_GRAY)
    k2.draw_text(fmt.tprintf("dt: %.3f", k2.get_frame_time()), {10,30}, 20, k2.LIGHT_GRAY)
    k2.present()
}

draw_view :: proc (v: ^hi.View) {
    c := &v.computed
    pos := hi.ref_to_screen(ctx, c.pos)
    size := c.size * ctx.screen_pixel_scale
    rect := k2.Rect { pos.x, pos.y, size.x, size.y }
    k2.draw_rect_outline(rect, 1, k2.LIGHT_BLUE)
}
