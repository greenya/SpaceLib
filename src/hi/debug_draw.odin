#+private
package hi

import "core:fmt"
import "../core"

DEBUG_VIEW_COLOR    :: [4] u8 { 255, 255,   0, 255 }
DEBUG_SCISSOR_COLOR :: [4] u8 {   0, 255, 255, 255 }

debug_draw_view :: proc (v: ^View) {
    if v.ctx.debug_draw_line == nil do return
    if v.ctx.debug_draw_text == nil do return

    if v.padding != {} {
        content_rect := view_content_rect(v)
        rect := ref_rect_to_screen(v.ctx, content_rect)
        debug_draw_rect(v.ctx, rect, 1, DEBUG_SCISSOR_COLOR)
    }

    if .scissor in v.flags {
        content_rect := view_content_rect(v)
        rect := ref_rect_to_screen(v.ctx, content_rect)
        debug_draw_rect(v.ctx, rect, 3, DEBUG_SCISSOR_COLOR)
    }

    rect := ref_view_to_screen(v)
    debug_draw_rect(v.ctx, rect, 1, DEBUG_VIEW_COLOR)

    if v.id == ROOT_VIEW_ID {
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
            v.ctx.ref_size.x, v.ctx.ref_size.y,
            v.ctx.ref_font_height,
            v.ctx.screen_size.x, v.ctx.screen_size.y,
            v.ctx.screen_top_left.x, v.ctx.screen_top_left.y,
            v.ctx.screen_font_height,
            v.ctx.screen_pixel_scale,
            v.ctx.mouse.screen_pos.x, v.ctx.mouse.screen_pos.y,
            v.ctx.mouse.ref_pos.x, v.ctx.mouse.ref_pos.y,
            v.ctx.mouse.lmb_down,
            v.ctx.time, int(v.ctx.dt*1000),
            core.sparse_array_len(v.ctx.views),
        )
        v.ctx.debug_draw_text(text, {2,2}, DEBUG_VIEW_COLOR)
    } else {
        text := fmt.tprintf("%s\n%vx%v", v.name, v.solved.size.x, v.solved.size.y)
        v.ctx.debug_draw_text(text, {rect.x,rect.y}+{2,2}, DEBUG_VIEW_COLOR)
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
