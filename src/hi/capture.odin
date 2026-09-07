package hi

Capture_State :: struct {
    phase               : Capture_Phase, // If `.none`, all other fields are invalid (zero)
    lmb_controlled      : bool,     // Capture ends on LMB release. Explicit `drag_start()` is not LMB-controlled.

    start_ref_pos       : Vec2,     // `Context.mouse.ref_pos` when capture started; preserved when pressing becomes dragging
    total_offset        : Vec2,     // Current `Context.mouse.ref_pos - start_ref_pos`
    delta               : Vec2,     // Change in `total_offset` since the previous update

    source              : ^View,    // The view that owns the press or drag
    source_start_scroll : Vec2,     // `source.scroll` when capture started
    source_start_pos    : Vec2,     // Starting mouse position relative to the top-left of `source.solved_rect`
    source_pos          : Vec2,     // Current mouse position relative to the top-left of `source.solved_rect`

    // Drag-only state. Zero during the press phase; retained through the terminal drag frame.
    drag_flags          : Drag_Flags,
    drag_cancel_reason  : Drag_Cancel_Reason, // Set only for a `.canceled` drag
    target              : ^View,    // Nearest eligible `.drop_target` in the hit path; nil while the pointer is over the source
    target_pos          : Vec2,     // Current mouse position relative to the top-left of `target.solved_rect`
    target_accepts_source: bool,    // `.drop_query` result from `target`
}

Capture_Phase :: enum u8 {
    none,
    press,  // Pending mouse press. Can click only with `.press`, or become a drag only with `.drag`.
    drag,   // Committed drag, including its terminal frame. This interaction can no longer emit `.clicked`.
}

Drag_Flags :: bit_set [Drag_Flag; u8]
Drag_Flag :: enum u8 {
    active,     // Set on every drag frame, including started and terminal frames. Never set during the press phase.
    started,    // Initial `.active` frame
    dropped,    // Terminal `.active` frame: completed with `target` and `target_accepts_source` set
    canceled,   // Terminal `.active` frame: canceled because of `drag_cancel_reason`
}

Drag_Cancel_Reason :: enum u8 {
    none,
    no_target,  // Released without an eligible `.drop_target`, excluding `source`. When self targeting, `.target_self` reason is used.
    target_self,// Released over `source` itself which is also a `.drop_target`, essentially no-op. Note: `.drag_query` is not emitted when self targeting.
    rejected,   // Released over a `.drop_target` that rejected `source`
    requested,  // Canceled programmatically with `drag_cancel()`
}

_capture_cleanup_state_from_prev_frame :: proc (ctx: ^Context) {
    if ctx.capture.phase != .drag do return
    if ctx.capture.drag_flags & { .dropped, .canceled } != {} {
        ctx.capture = {}
    } else {
        ctx.capture.drag_flags -= { .started }
    }
}

@require_results
_capture_in_progress :: proc (ctx: ^Context) -> bool {
    return ctx.capture.phase != .none
}

_capture_start :: proc (ctx: ^Context, source: ^View, hit: ^View, lmb_controlled := true) {
    assert(!_capture_in_progress(ctx))

    source_start_pos := ctx.mouse.ref_pos - { source.solved_rect.x, source.solved_rect.y }
    ctx.capture = {
        phase               = .press,
        lmb_controlled      = lmb_controlled,
        start_ref_pos       = ctx.mouse.ref_pos,
        source              = source,
        source_start_scroll = source.scroll,
        source_start_pos    = source_start_pos,
        source_pos          = source_start_pos,
    }

    if lmb_controlled {
        _capture_step(ctx, hit)
    } else {
        _drag_start(ctx, hit)
    }
}

// Starts dragging immediately, regardless of `.press`, `.drag`, or `Context.drag_threshold`.
// End this drag explicitly with `drag_drop()` or `drag_cancel()`; LMB release does not end it.
drag_start :: proc (v: ^View) {
    _capture_start(v.ctx, source=v, hit=v.ctx.hit, lmb_controlled=false)
}

// True while the view owns a pending mouse press, including a `.drag`-only view waiting for the threshold.
// Becomes false when dragging starts or the mouse button is released.
pressed :: proc (v: ^View) -> bool {
    assert(v != nil)
    return v == v.ctx.capture.source && v.ctx.capture.phase == .press
}

// True while the view owns an actual drag, including its started and terminal frames.
dragged :: proc (v: ^View) -> bool {
    assert(v != nil)
    return v == v.ctx.capture.source && v.ctx.capture.phase == .drag
}

// Drag target status of the view
drag_targeted :: proc (v: ^View) -> (targeted: bool, accepted: bool) {
    assert(v != nil)
    if v.ctx.capture.phase == .drag {
        return v == v.ctx.capture.target, v.ctx.capture.target_accepts_source
    }
    return
}

_capture_update :: proc (ctx: ^Context, hit: ^View) {
    assert(_capture_in_progress(ctx))

    // offsets

    new_total_offset := ctx.mouse.ref_pos - ctx.capture.start_ref_pos
    ctx.capture.delta = new_total_offset - ctx.capture.total_offset
    ctx.capture.total_offset = new_total_offset

    // source view

    ctx.capture.source_pos = ctx.mouse.ref_pos - { ctx.capture.source.solved_rect.x, ctx.capture.source.solved_rect.y }

    if ctx.capture.phase == .drag {
        _drag_update(ctx, hit)
    }
}

_capture_step :: proc (ctx: ^Context, hit: ^View) {
    switch ctx.capture.phase {
    case .none:
        panic("Capture is not in progress")
    case .press:
        if !ctx.mouse.lmb_down {
            _press_stop(ctx, hit)
        } else if .drag in ctx.capture.source.flags {
            offset := ctx.capture.total_offset
            offset_threshold := abs(offset.x) + abs(offset.y)
            if offset_threshold >= ctx.drag_threshold {
                _drag_start(ctx, hit)
            }
        }
    case .drag:
        _drag_step(ctx, hit)
    }
}

_press_stop :: proc (ctx: ^Context, hit: ^View) {
    assert(ctx.capture.phase == .press)
    source := ctx.capture.source
    should_click := .press in source.flags && _interaction_path_contains(hit, source)

    // End the press before clicking, so its handler can start an explicit drag.
    ctx.capture = {}
    if should_click do click(source)
}

_drag_start :: proc (ctx: ^Context, hit: ^View) {
    assert(ctx.capture.phase == .press)
    ctx.capture.phase = .drag
    ctx.capture.drag_flags = { .active, .started }
    _drag_update(ctx, hit)
    _drag_step(ctx, hit)
}

_drag_update :: proc (ctx: ^Context, hit: ^View) {
    assert(ctx.capture.phase == .drag)

    ctx.capture.target_pos = {}
    ctx.capture.target_accepts_source = false
    ctx.capture.target = nil
    if _interaction_path_contains(hit, ctx.capture.source) do return

    ctx.capture.target = _interaction_parent_by_any_flags(hit, include={ .drop_target })
    if ctx.capture.target != nil {
        ctx.capture.target_pos = ctx.mouse.ref_pos - { ctx.capture.target.solved_rect.x, ctx.capture.target.solved_rect.y }
        if .disabled not_in ctx.capture.target.flags {
            ctx.capture.target_accepts_source = _emit(ctx.capture.target, { type=.drop_query })
        }
    }
}

_drag_step :: proc (ctx: ^Context, hit: ^View) {
    if ctx.capture.drag_flags & { .dropped, .canceled } != {} do return

    if .drag_pan in ctx.capture.source.flags {
        scroll_to(ctx.capture.source, ctx.capture.source_start_scroll + ctx.capture.total_offset)
    }

    if ctx.capture.lmb_controlled && !ctx.mouse.lmb_down {
        _drag_stop(ctx, hit)
    } else {
        _emit(ctx.capture.source, { type=.dragged })
    }
}

_drag_stop :: proc (ctx: ^Context, hit: ^View) {
    assert(ctx.capture.phase == .drag)

    switch {
    case _interaction_path_contains(hit, ctx.capture.source):
        _drag_cancel(ctx, .target_self)

    case ctx.capture.target == nil:
        _drag_cancel(ctx, .no_target)

    case !ctx.capture.target_accepts_source:
        _drag_cancel(ctx, .rejected)

    case:
        drag_drop(ctx)
    }
}

drag_drop :: proc (ctx: ^Context) {
    assert(ctx.capture.phase == .drag)
    assert(ctx.capture.target != nil, "The target must exist")
    assert(ctx.capture.target_accepts_source, "The target doesn't accept the source. Did you mean `drag_cancel()`?")
    if ctx.capture.drag_flags & { .dropped, .canceled } != {} do return

    ctx.capture.drag_flags += { .dropped }
    _emit(ctx.capture.source, { type=.dragged })
}

drag_cancel :: proc (ctx: ^Context) {
    _drag_cancel(ctx, .requested)
}

_drag_cancel :: proc (ctx: ^Context, reason: Drag_Cancel_Reason) {
    assert(ctx.capture.phase == .drag)
    assert(reason != .none)
    if ctx.capture.drag_flags & { .dropped, .canceled } != {} do return

    ctx.capture.drag_flags += { .canceled }
    ctx.capture.drag_cancel_reason = reason
    _emit(ctx.capture.source, { type=.dragged })
}
