package hi

import "../core"

// An active view. A view that is most likely visible right now.
//
// A view is considered *inactive* and skipped by the solver if:
// - the view itself or any parent of the view is `.hidden`
// - the view does not intersect `solved_scissor` (completely clipped out)
// - the view is a child of an *inactive* view
//
// Note: Zero `View.opacity` alone does not make the view *inactive*.
Active_View :: struct {
    using view          : ^View,
    solved_scissor      : Rect,             // Scissor rect this view is clipped by in ref units. If empty, the scissor is disabled.
    solved_text_tokens  : [] Text_Token,    // Text tokens of this view. Only for `.text` views.
}

Active_View_Text_Iterator :: struct {
    active_view     : ^Active_View,
    next_i          : int,
    filter          : bit_set [Text_Token_Type],
    measurable_only : bool, // If true, skip tokens with zero size
    in_scissor_only : bool, // If true, skip tokens clipped out by `active_view.solved_scissor` if it is used
    content_rect    : Rect,
}

@require_results
active_view_text_token_iterate :: proc (
    active_view     : ^Active_View,
    filter          := bit_set [Text_Token_Type] { .word, .custom },
    measurable_only := true,
    in_scissor_only := true,
) -> (it: Active_View_Text_Iterator) {
    assert(filter != {})
    return {
        active_view         = active_view,
        filter              = filter,
        measurable_only     = measurable_only,
        in_scissor_only     = in_scissor_only && active_view.solved_scissor != {},
        content_rect        = content_rect(active_view),
    }
}

@require_results
active_view_text_token_next :: proc (it: ^Active_View_Text_Iterator) -> (tok: ^Text_Token, screen_pos: Vec2, screen_rect: Rect, ok: bool) #no_bounds_check {
    for i := it.next_i; i < len(it.active_view.solved_text_tokens); i += 1 {
        tok = &it.active_view.solved_text_tokens[i]

        if tok.type not_in it.filter do continue
        if it.measurable_only && tok.size == {} do continue

        tok_pos := tok.solved_pos + { it.content_rect.x, it.content_rect.y }
        tok_rect := Rect { tok_pos.x, tok_pos.y, tok.size.x, tok.size.y }
        if it.in_scissor_only && !core.rects_intersect(it.content_rect, tok_rect) do continue

        it.next_i = i + 1
        screen_pos = ref_pos_to_screen(it.active_view.ctx, tok_pos)
        screen_rect = ref_rect_to_screen(it.active_view.ctx, tok_rect)
        ok = true
        return
    }
    return
}
