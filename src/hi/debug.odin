package hi

import "core:fmt"
import "../core"

Debug_Draw_Type :: enum u8 {
    stats,      // Context stats: time, mouse, views, pixel scale etc.
    scissor,    // View's scissor
    padding,    // View's padding
    rect,       // View's solved rect
    info,       // View's name and size
    text,       // Solved rect of each View's text token
}

// Debug_Draw_Filter :: bit_set [Debug_Draw_Type]

_DEBUG_VIEW_COLOR       :: Color { 255, 255, 255, 255 }
_DEBUG_HIT_TEST_COLOR   :: Color { 255, 255,   0, 255 }
_DEBUG_PADDING_COLOR    :: Color { 255, 255, 255,  80 }
_DEBUG_SCISSOR_COLOR    :: Color {   0, 255, 255, 255 }
// _DEBUG_CAPTURE_COLOR :: Color { 255, 120, 120, 255 }
_DEBUG_TEXT_TOKEN_COLOR :: Color { 255,   0, 255, 255 }
_DEBUG_STATS_COLOR      :: Color { 255, 255, 255, 255 }

_debug_draw_stats :: proc (ctx: ^Context) {
    if ctx.debug_draw_text == nil do return

    text := fmt.tprintf(
        "ref_size: %vx%v\n" +
        "ref_font_height: %.0f\n" +
        "\n" +
        "screen_size: %.0fx%.0f\n" +
        "screen_top_left: %.0f,%.0f\n" +
        "screen_pixel_scale: %.2f\n" +
        "\n" +
        "time: %.3f (%ims)\n" +
        "mouse.screen_pos: %.0f,%.0f\n" +
        "mouse.ref_pos: %.0f,%.0f\n" +
        "mouse.lmb_down: %v\n" +
        "\n" +
        "views: %i of %i\n" +
        "views peak: %i\n" +
        "visible views: %i of %i\n" +
        "visible views peak: %i\n" +
        "visible text tokens: %i of %i\n" +
        "visible text tokens peak: %i",

        ctx.ref_size.x, ctx.ref_size.y,
        ctx.ref_font_height,

        ctx.screen_size.x, ctx.screen_size.y,
        ctx.screen_top_left.x, ctx.screen_top_left.y,
        ctx.screen_pixel_scale,

        ctx.time, int(ctx.dt*1000),
        ctx.mouse.screen_pos.x, ctx.mouse.screen_pos.y,
        ctx.mouse.ref_pos.x, ctx.mouse.ref_pos.y,
        ctx.mouse.lmb_down,

        core.sparse_array_len(ctx.views), core.sparse_array_cap(ctx.views),
        ctx.stats.views_peak,
        len(ctx.visible_views), cap(ctx.visible_views),
        ctx.stats.visible_views_peak,
        ctx.visible_text_tokens_used, cap(ctx.visible_text_tokens),
        ctx.stats.visible_text_tokens_peak,
    )

    pos := Vec2 {4,50}
    ctx.debug_draw_text(text, pos+1, core.brightness(_DEBUG_STATS_COLOR, -.8))
    ctx.debug_draw_text(text, pos, _DEBUG_STATS_COLOR)
}

_debug_draw_view :: proc (v: ^Visible_View, filter: bit_set [Debug_Draw_Type] = ~{}) {
    if .scissor in filter   do _debug_draw_view_scissor(v)
    if .padding in filter   do _debug_draw_view_padding(v)
    if .rect in filter      do _debug_draw_view_rect(v)
    if .info in filter      do _debug_draw_view_info(v)
    if .text in filter      do _debug_draw_view_text(v)
}

_debug_draw_view_scissor :: proc (v: ^View) {
    if .scissor not_in v.flags do return

    vr_s := ref_rect_to_screen(v.ctx, viewport_rect(v))
    core.rect_inflate(&vr_s, 8/4)
    _debug_draw_rect(v.ctx, vr_s, 8, _DEBUG_SCISSOR_COLOR)
}

_debug_draw_view_padding :: proc (v: ^View) {
    if v.padding == {} do return

    viewport_rect_ := viewport_rect(v)
    vlt := Vec2  { viewport_rect_.x, viewport_rect_.y }
    vbr := vlt + { viewport_rect_.w, viewport_rect_.h }
    s := v.ctx.screen_pixel_scale
    p := v.padding

    for i in ([?] [3] Vec2 { // i[0]=start, i[1]=end, i[2].x=thickness, i[2].y=not used
        { {vlt.x-p[0]/2,vlt.y}, {vlt.x-p[0]/2,vbr.y}, {p[0],0} }, // left
        { {vbr.x+p[2]/2,vlt.y}, {vbr.x+p[2]/2,vbr.y}, {p[2],0} }, // right
        { {vlt.x,vlt.y-p[1]/2}, {vbr.x,vlt.y-p[1]/2}, {p[1],0} }, // top
        { {vlt.x,vbr.y+p[3]/2}, {vbr.x,vbr.y+p[3]/2}, {p[3],0} }, // bottom
    }) {
        lt := ref_pos_to_screen(v.ctx, i[0])
        rb := ref_pos_to_screen(v.ctx, i[1])
        _debug_draw_line(v.ctx, lt, rb, s*i[2].x, _DEBUG_PADDING_COLOR)
    }
}

_debug_draw_view_rect :: proc (v: ^View) {
    rect_s := ref_view_to_screen(v)
    color := .hovered in v.flags ? _DEBUG_HIT_TEST_COLOR : _DEBUG_VIEW_COLOR
    thick: f32 = .hovered in v.flags ? 4 : 1
    _debug_draw_rect(v.ctx, rect_s, thick, color)
}

_debug_draw_view_info :: proc (v: ^View) {
    if v.ctx.debug_draw_text == nil do return

    text := fmt.tprintf("%s\n%vx%v", v.name, v.solved_rect.w, v.solved_rect.h)
    lt_s := ref_pos_to_screen(v.ctx, { v.solved_rect.x, v.solved_rect.y })
    color := .hovered in v.flags ? _DEBUG_HIT_TEST_COLOR : _DEBUG_VIEW_COLOR
    v.ctx.debug_draw_text(text, lt_s+4, color)
}

_debug_draw_view_text :: proc (v: ^Visible_View) {
    if .text not_in v.flags do return
    if v.ctx.debug_draw_line == nil do return

    it := visible_text_iterate(v, filter={.word,.whitespace,.custom}, in_scissor_only=false)
    for _, tok_rect in visible_text_next(&it) {
        tok_rect_s := ref_rect_to_screen(v.ctx, tok_rect)
        _debug_draw_rect(v.ctx, tok_rect_s, 1, _DEBUG_TEXT_TOKEN_COLOR)
    }
}

_debug_draw_rect :: proc (ctx: ^Context, rect_s: Rect, thick_s: f32, color: Color) {
    if ctx.debug_draw_line == nil do return

    l, t := rect_s.x, rect_s.y
    r, b := l+rect_s.w, t+rect_s.h

    ctx.debug_draw_line({l,t}, {r,t}, thick_s, color)
    ctx.debug_draw_line({l,t}, {l,b}, thick_s, color)
    ctx.debug_draw_line({r,b}, {l,b}, thick_s, color)
    ctx.debug_draw_line({r,b}, {r,t}, thick_s, color)
}

_debug_draw_line :: proc (ctx: ^Context, from_s, to_s: Vec2, thick_s: f32, color: Color) {
    if ctx.debug_draw_line == nil do return
    ctx.debug_draw_line(from_s, to_s, thick_s, color)
}
