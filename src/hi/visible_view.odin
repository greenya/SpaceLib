package hi

import "../core"

// A solved visible view.
//
// Do not store `Visible_View` references: all visible views are rebuilt on every `solve_context()`.
//
// A view is considered *invisible* and omitted from the final visible state if:
// - the view itself or any of its parents is `.hidden`
// - the view does not intersect `solved_scissor` (completely clipped out)
// - the view is a child of an *invisible* view
//
// Note: Zero `View.opacity` alone does not make the view *invisible*.
Visible_View :: struct {
    using view          : ^View,
    solved_scissor      : Rect,             // Scissor rect this view is clipped by in UI units. Used only if `scissor_enabled()`.
    solved_text_tokens  : [] Text_Token,    // Text tokens of this view. Only for `.text` views.
}

Visible_Text_Iterator :: struct {
    using token_it  : Text_Token_Iterator,
    content_origin  : Vec2,
    measurable_only : bool, // If true, skip tokens with zero size
    in_scissor_only : bool, // If true, skip tokens clipped out by `visible_view.solved_scissor` if it is used
    scissor_rect    : Rect,
}

@require_results
visible_text_iterate :: proc (
    v               : ^Visible_View,
    filter          := bit_set [Text_Token_Type] { .word, .custom },
    measurable_only := true,
    in_scissor_only := true,
) -> (it: Visible_Text_Iterator) {
    assert(filter != {})

    it = {
        token_it        = text_token_iterate(v, filter),
        measurable_only = measurable_only,
        content_origin  = content_origin(v),
    }

    if in_scissor_only && scissor_enabled(v.solved_scissor) {
        it.scissor_rect = v.solved_scissor
        it.in_scissor_only = true
    }

    return
}

@require_results
visible_text_next :: proc (it: ^Visible_Text_Iterator) -> (tok: ^Text_Token, tok_rect: Rect, ok: bool) #no_bounds_check {
    for tok_ in text_token_next(&it.token_it) {
        if it.measurable_only && (tok_.size=={} || ._trimmed in tok_.flags) do continue

        tok_rect = Rect {
            tok_.solved_pos.x + it.content_origin.x,
            tok_.solved_pos.y + it.content_origin.y,
            tok_.solved_width,
            tok_.size.y,
        }

        if it.in_scissor_only && (\
            !scissor_has_area(it.scissor_rect) ||
            !core.rects_intersect(it.scissor_rect, tok_rect)
        ) {
            continue
        }

        tok = tok_
        ok = true
        return
    }
    return
}

Visible_Text_Hit :: struct {
    tok     : ^Text_Token,
    rect    : Rect,
    spans   : [dynamic; TEXT_SPAN_STACK_SIZE] Text_Span, // In order of encounter (from outermost to innermost)
}

// Performs hit test on the given `.text` visible view and returns token hit, including stack
// of spans. Can hit only tokens which has physical size: words, whitespaces and custom tokens
// with physical size. Respects scissor. All the pointers of the returned `hit` are valid until
// the solved text is rebuilt (possibly in the same frame).
// - `require_enabled`, if set, hit tests only if view is not `.disabled`
// - `require_hovered`, if set, hit tests only if view is `.hovered`
@require_results
visible_text_hit_test :: proc (
    v               : ^Visible_View,
    pos             : Vec2,
    require_enabled := true,
    require_hovered := true,
) -> (hit: Visible_Text_Hit, ok: bool) {
    assert(.text in v.flags)

    if require_enabled && .disabled in v.flags do return
    if require_hovered && .hovered not_in v.flags do return

    if scissor_enabled(v.solved_scissor) {
        if !scissor_has_area(v.solved_scissor) || !core.pos_in_rect(pos, v.solved_scissor) {
            return
        }
    }

    it := visible_text_iterate(v, filter={ .word, .whitespace, .custom })
    for tok, rect in visible_text_next(&it) {
        if rect.w <= 0 || rect.h <= 0 do continue
        if core.pos_in_rect(pos, rect) {
            return { tok=tok, rect=rect, spans=it.spans }, true
        }
    }

    return
}

// Returns the innermost enclosing span whose opening `token.text` matches `token_text`
@require_results
visible_text_hit_test_token :: proc (
    v               : ^Visible_View,
    pos             : Vec2,
    token_text      : string,
    require_enabled := true,
    require_hovered := true,
) -> (hit_span: Text_Span, ok: bool) {
    if hit, hit_ok := visible_text_hit_test(v, pos, require_enabled, require_hovered); hit_ok {
        #reverse for span in hit.spans {
            if span.token.text == token_text do return span, true
        }
    }
    return
}

SCISSOR_DISABLED :: Rect { 0, 0, -1, -1 }

@require_results
scissor_enabled :: proc (scissor_rect: Rect) -> bool {
    return scissor_rect.w >= 0 && scissor_rect.h >= 0
}

@require_results
scissor_has_area :: proc (scissor_rect: Rect) -> bool {
    return scissor_rect.w > 0 && scissor_rect.h > 0
}
