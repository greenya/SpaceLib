package hi

Drag_State :: struct {
    flags               : Drag_Flags, // If `.active`, drag operation is happening now
    cancel_reason       : Drag_Cancel_Reason, // Set only for `.canceled` drag operation

    start_ref_pos       : Vec2,     // `Context.mouse.ref_pos` when the drag started
    total_offset        : Vec2,     // Current `Context.mouse.ref_pos - start_ref_pos`
    delta               : Vec2,     // Change in `total_offset` since the previous update

    source              : ^View,    // The view the drag started from
    source_start_scroll : Vec2,     // `source.scroll` when the drag started
    source_start_pos    : Vec2,     // Starting mouse position relative to the top-left of `source.solved_rect`
    source_pos          : Vec2,     // Current mouse position relative to the top-left of `source.solved_rect`

    target              : ^View,    // The view the drag is targeting now. Set to the nearest `.drop_target` in the hit path if any.
    target_pos          : Vec2,     // Current mouse position relative to the top-left of `target.solved_rect`
    target_accepts_source: bool,    // `.drop_query` result from `target`
}

Drag_Flags :: bit_set [Drag_Flag; u8]
Drag_Flag :: enum u8 {
    active,         // Set on every drag frame, including started and terminal frames. If this flag is not set, all other fields of `Context.drag` are invalid (zero)
    lmb_controlled, // The drag automatically ends when LMB is released. It can still be ended earlier with `drag_drop()` or `drag_cancel()`.
    started,        // Initial `.active` frame
    dropped,        // Terminal `.active` frame: completed with `target` and `target_accepts_source` set
    canceled,       // Terminal `.active` frame: canceled because of `cancel_reason`
}

Drag_Cancel_Reason :: enum u8 {
    none,
    clicked,    // Released over `source` and `.clicked` was emitted
    no_target,  // Released without any `.drop_target` under the pointer
    rejected,   // Released over a `.drop_target` that rejected `source`
    requested,  // Canceled programmatically with `drag_cancel()`
}

_drag_cleanup_state_from_prev_frame :: proc (ctx: ^Context) {
    if .active not_in ctx.drag.flags do return
    if ctx.drag.flags & { .dropped, .canceled } != {} {
        ctx.drag = {}
    } else {
        ctx.drag.flags -= { .started }
    }
}

_drag_start :: proc (ctx: ^Context, source: ^View, hit: ^View, lmb_controlled: bool) {
    assert(.active not_in ctx.drag.flags)

    source_start_pos := ctx.mouse.ref_pos - { source.solved_rect.x, source.solved_rect.y }
    ctx.drag = {
        flags               = { .active, .started },
        start_ref_pos       = ctx.mouse.ref_pos,
        source              = source,
        source_start_scroll = source.scroll,
        source_start_pos    = source_start_pos,
        source_pos          = source_start_pos,
    }

    if lmb_controlled do ctx.drag.flags += { .lmb_controlled }

    _drag_update(ctx, hit)

    _emit(source, { type=.dragged })
}

drag_start :: proc (v: ^View) {
    _drag_start(v.ctx, source=v, hit=v.ctx.hit, lmb_controlled=false)
}

_drag_update :: proc (ctx: ^Context, hit: ^View) {
    assert(.active in ctx.drag.flags)

    // offsets

    new_total_offset := ctx.mouse.ref_pos - ctx.drag.start_ref_pos
    ctx.drag.delta = new_total_offset - ctx.drag.total_offset
    ctx.drag.total_offset = new_total_offset

    // source view

    ctx.drag.source_pos = ctx.mouse.ref_pos - { ctx.drag.source.solved_rect.x, ctx.drag.source.solved_rect.y }

    // target view

    ctx.drag.target_pos = {}
    ctx.drag.target_accepts_source = false
    ctx.drag.target = _interaction_parent_by_any_flags(hit, include={ .drop_target })

    if ctx.drag.target != nil {
        ctx.drag.target_pos = ctx.mouse.ref_pos - { ctx.drag.target.solved_rect.x, ctx.drag.target.solved_rect.y }
        if .disabled not_in ctx.drag.target.flags {
            ctx.drag.target_accepts_source = _emit(ctx.drag.target, { type=.drop_query })
        }
    }
}

_drag_step :: proc (ctx: ^Context, hit: ^View) {
    if .drag_pan in ctx.drag.source.flags {
        scroll_to(ctx.drag.source, ctx.drag.source_start_scroll + ctx.drag.total_offset)
    }

    if .lmb_controlled in ctx.drag.flags && !ctx.mouse.lmb_down {
        _drag_stop(ctx, hit)
    } else {
        _emit(ctx.drag.source, { type=.dragged })
    }
}

_drag_stop :: proc (ctx: ^Context, hit: ^View) {
    assert(.active in ctx.drag.flags)

    switch {
    case _interaction_path_contains(hit, ctx.drag.source):
        click(ctx.drag.source)
        _drag_cancel(ctx, .clicked)

    case ctx.drag.target == nil:
        _drag_cancel(ctx, .no_target)

    case !ctx.drag.target_accepts_source:
        _drag_cancel(ctx, .rejected)

    case:
        drag_drop(ctx)
    }
}

drag_drop :: proc (ctx: ^Context) {
    assert(.active in ctx.drag.flags)
    assert(ctx.drag.target != nil, "The target must exist")
    assert(ctx.drag.target_accepts_source, "The target doesn't accept the source. Did you mean `drag_cancel()`?")

    ctx.drag.flags += { .dropped }
    _emit(ctx.drag.source, { type=.dragged })
}

drag_cancel :: proc (ctx: ^Context) {
    _drag_cancel(ctx, .requested)
}

_drag_cancel :: proc (ctx: ^Context, reason: Drag_Cancel_Reason) {
    assert(.active in ctx.drag.flags)
    assert(reason != .none)

    ctx.drag.flags += { .canceled }
    ctx.drag.cancel_reason = reason
    _emit(ctx.drag.source, { type=.dragged })
}
