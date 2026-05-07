#+private
package hi

DEBUG_VIEW_COLOR    :: [4] u8 { 255, 255,   0, 255 }
DEBUG_SCISSOR_COLOR :: [4] u8 {   0, 255, 255, 255 }

debug_draw_view :: proc (ctx: ^Context, id: ID) {
    if ctx.debug_draw_rect == nil do return
    v := &ctx.views[id]

    if .scissor in v.flags {
        scissor_rect := view_scissor_rect(ctx, v)
        rect := ref_rect_to_screen(ctx, scissor_rect)
        ctx.debug_draw_rect(rect, 3, DEBUG_SCISSOR_COLOR)
    }

    {
        rect := ref_to_screen(ctx, v)
        ctx.debug_draw_rect(rect, 1, DEBUG_VIEW_COLOR)
    }
}
