package hi

import "../core"

// A view that is most likely visible right now.
//
// A view is considered *invisible* and skipped by the solver if:
// - the view itself or any its parent is `.hidden`
// - the view does not intersect `solved_scissor` (completely clipped out)
// - the view is a child of *invisible* view
//
// Note: Zero `View.opacity` alone does not make the view *invisible*.
Visible_View :: struct {
    using view          : ^View,
    solved_scissor      : Rect,             // Scissor rect this view is clipped by in ref units. If empty, the scissor is disabled.
    solved_text_tokens  : [] Text_Token,    // Text tokens of this view. Only for `.text` views.
}

Visible_Text_Iterator :: struct {
    using token_it  : Text_Token_Iterator,
    content_top_left: Vec2,
    measurable_only : bool, // If true, skip tokens with zero size
    in_scissor_only : bool, // If true, skip tokens clipped out by `visible_view.solved_scissor` if it is used
    scissor_rect    : Rect,
}

@require_results
visible_text_iterate :: proc (
    visible_view    : ^Visible_View,
    filter          := bit_set [Text_Token_Type] { .word, .custom },
    measurable_only := true,
    in_scissor_only := true,
) -> (it: Visible_Text_Iterator) {
    assert(filter != {})

    it = {
        token_it        = text_token_iterate(visible_view.ctx, visible_view.solved_text_tokens, filter),
        measurable_only = measurable_only,
        content_top_left= content_top_left(visible_view),
    }

    if in_scissor_only && visible_view.solved_scissor != {} {
        it.scissor_rect = visible_view.solved_scissor
        it.in_scissor_only = true
    }

    return
}

@require_results
visible_text_next :: proc (it: ^Visible_Text_Iterator) -> (tok: ^Text_Token, tok_rect: Rect, ok: bool) #no_bounds_check {
    for tok_ in text_token_next(&it.token_it) {
        if it.measurable_only && tok_.size == {} do continue

        tok_rect = Rect {
            tok_.solved_pos.x + it.content_top_left.x,
            tok_.solved_pos.y + it.content_top_left.y,
            tok_.size.x,
            tok_.size.y,
        }

        if it.in_scissor_only && !core.rects_intersect(it.scissor_rect, tok_rect) do continue

        tok = tok_
        ok = true
        return
    }
    return
}

@require_results
visible_text_font_size :: proc (it: Visible_Text_Iterator) -> f32 {
    return it.style.font_scale * it.ctx.ref_font_height
}

@require_results
visible_text_font_size_screen :: proc (it: Visible_Text_Iterator) -> f32 {
    return it.style.font_scale * it.ctx.ref_font_height * it.ctx.screen_pixel_scale
}
