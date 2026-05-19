package hi

import "core:fmt"
import "../core"

_DEBUG_ROOT_COLOR       :: Color { 255, 255, 255, 80 }
_DEBUG_VIEW_COLOR       :: Color { 255, 255,   0, 255 }
_DEBUG_SCISSOR_COLOR    :: Color {   0, 255, 255, 255 }

_debug_draw_view :: proc (v: ^View) {
    if v.ctx.debug_draw_line == nil do return
    if v.ctx.debug_draw_text == nil do return

    content_rect := ref_rect_to_screen(v.ctx, content_rect(v))

    if .scissor in v.flags {
        _debug_draw_rect(v.ctx, content_rect, 4, _DEBUG_SCISSOR_COLOR)
    } else if v.padding != {} {
        _debug_draw_rect(v.ctx, content_rect, 1, _DEBUG_SCISSOR_COLOR)
    }

    rect := ref_view_to_screen(v)

    if v.idx == 0 {
        _debug_draw_rect(v.ctx, core.rect_inflated(rect, -4), 4, _DEBUG_ROOT_COLOR)
        text := fmt.tprintf(
            "ref_size: %vx%v\n" +
            "ref_font_height: %i\n" +
            "\n" +
            "screen_size: %.0fx%.0f\n" +
            "screen_top_left: %.0f,%.0f\n" +
            "screen_font_height: %i\n" +
            "screen_pixel_scale: %.2f\n" +
            "\n" +
            "time: %.3f (%ims)\n" +
            "mouse.screen_pos: %.0f,%.0f\n" +
            "mouse.ref_pos: %.0f,%.0f\n" +
            "mouse.lmb_down: %v\n" +
            "\n" +
            "visible views: %i of %i\n" +
            "views limit: %i",
            v.ctx.ref_size.x, v.ctx.ref_size.y,
            v.ctx.ref_font_height,
            v.ctx.screen_size.x, v.ctx.screen_size.y,
            v.ctx.screen_top_left.x, v.ctx.screen_top_left.y,
            v.ctx.screen_font_height,
            v.ctx.screen_pixel_scale,
            v.ctx.time, int(v.ctx.dt*1000),
            v.ctx.mouse.screen_pos.x, v.ctx.mouse.screen_pos.y,
            v.ctx.mouse.ref_pos.x, v.ctx.mouse.ref_pos.y,
            v.ctx.mouse.lmb_down,
            len(v.ctx.visible_views), core.sparse_array_len(v.ctx.views),
            core.sparse_array_cap(v.ctx.views),
        )
        v.ctx.debug_draw_text(text, {2,2}, _DEBUG_VIEW_COLOR)
    } else {
        _debug_draw_rect(v.ctx, rect, 1, _DEBUG_VIEW_COLOR)
        text := fmt.tprintf("%s\n%vx%v", v.name, v.solved.rect.w, v.solved.rect.h)
        v.ctx.debug_draw_text(text, {rect.x,rect.y}+{2,2}, _DEBUG_VIEW_COLOR)
    }
}

_debug_draw_rect :: proc (ctx: ^Context, screen_rect: Rect, thick: f32, color: Color) {
    if ctx.debug_draw_line == nil do return
    l, t := screen_rect.x, screen_rect.y
    r, b := l+screen_rect.w, t+screen_rect.h
    ctx.debug_draw_line({l,t}, {r,t}, thick, color)
    ctx.debug_draw_line({l,t}, {l,b}, thick, color)
    ctx.debug_draw_line({r,b}, {l,b}, thick, color)
    ctx.debug_draw_line({r,b}, {r,t}, thick, color)
}
