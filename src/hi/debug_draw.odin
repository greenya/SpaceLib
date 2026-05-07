#+private
package hi

import "core:fmt"

DEBUG_VIEW_COLOR    :: [4] u8 { 255, 255,   0, 255 }
DEBUG_SCISSOR_COLOR :: [4] u8 {   0, 255, 255, 255 }

debug_draw_view :: proc (ctx: ^Context, id: ID) {
    if ctx.debug_draw_line == nil do return
    if ctx.debug_draw_text == nil do return
    v := &ctx.views[id]

    if v.padding != {} {
        content_rect := view_content_rect(ctx, v)
        rect := ref_rect_to_screen(ctx, content_rect)
        debug_draw_rect(ctx, rect, 1, DEBUG_SCISSOR_COLOR)
    }

    if .scissor in v.flags {
        content_rect := view_content_rect(ctx, v)
        rect := ref_rect_to_screen(ctx, content_rect)
        debug_draw_rect(ctx, rect, 3, DEBUG_SCISSOR_COLOR)
    }

    rect := ref_to_screen(ctx, v)
    debug_draw_rect(ctx, rect, 1, DEBUG_VIEW_COLOR)

    if id == 0 {
        text := fmt.tprintf(
            "ref_size: %vx%v\n" +
            "ref_font_height: %i\n" +
            "\n" +
            "screen_size: %.0fx%.0f\n" +
            "screen_top_left: %.0f,%.0f\n" +
            "screen_font_height: %i\n" +
            "screen_pixel_scale: %.2f\n" +
            "\n" +
            "mouse.screen_pos: %.0f,%.0f\n" +
            "mouse.ref_pos: %.0f,%.0f\n" +
            "mouse.lmb_down: %v\n" +
            "\n" +
            "time: %.3f (%ims)\n" +
            "views: %i",
            ctx.ref_size.x, ctx.ref_size.y,
            ctx.ref_font_height,
            ctx.screen_size.x, ctx.screen_size.y,
            ctx.screen_top_left.x, ctx.screen_top_left.y,
            ctx.screen_font_height,
            ctx.screen_pixel_scale,
            ctx.mouse.screen_pos.x, ctx.mouse.screen_pos.y,
            ctx.mouse.ref_pos.x, ctx.mouse.ref_pos.y,
            ctx.mouse.lmb_down,
            ctx.time, int(ctx.dt*1000),
            len(ctx.views),
        )
        ctx.debug_draw_text(text, {2,2}, DEBUG_VIEW_COLOR)
    } else {
        text := fmt.tprintf("%s\n%vx%v", v.name, v.solved.size.x, v.solved.size.y)
        ctx.debug_draw_text(text, {rect.x,rect.y}+{2,2}, DEBUG_VIEW_COLOR)
    }
}

debug_draw_rect :: proc (ctx: ^Context, screen_rect: Rect, thick: f32, color: [4] u8) {
    if ctx.debug_draw_line == nil do return
    l, t := screen_rect.x, screen_rect.y
    r, b := l+screen_rect.w, t+screen_rect.h
    ctx.debug_draw_line({l,t}, {r,t}, thick, color)
    ctx.debug_draw_line({l,t}, {l,b}, thick, color)
    ctx.debug_draw_line({r,b}, {l,b}, thick, color)
    ctx.debug_draw_line({r,b}, {r,t}, thick, color)
}
