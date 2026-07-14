package hi

import "../core"

View_IDX :: distinct i32
View_SID :: distinct i32

View_Init :: struct {
    flags: Flags,

    using _: bit_field u16 {
        strata  : Strata    | 4,    // Elevation layer: drawing order goes low->high, mouse hit test order goes high->low. By default, the value is set to `parent.strata`. Non-native strata children are excluded from parent layout and input propagation.
        level   : int       | 12,   // Order within `strata`, 12 bits, approximate range -2000..+2000. If two views has same `strata` and `level`, the view with bigger `sid` considered to be higher. By default, the value is set to `parent.level`.
    },

    size    : Vec2,     // Width and height, assuming "fixed value" when `.fit_*` or `.fill_*` is not used; `.ratio_*` allows interpreting value as fraction of the parent
    place   : Place,    // Used only if parent has no layout, or for `.absolute` and non-native `strata` children
    opacity : f32,      // Opacity from fully transparent (`0.0`) to fully opaque (`1.0`, default value). The value affects `solved_opacity` of the view and all its children (all stratas).
    padding : Vec4,     // Padding for layout children and text content in order: 0=left, 1=top, 2=right, 3=bottom
    scroll  : Vec2,     // Offset for layout children
    layout  : Layout,   // Layout for children. Affects non-`.absolute` native strata children only.

    name    : string, // Optional name
    text    : string, // Text with rich formatting if `.text` is used
    user_ptr: rawptr,
    user_idx: int,

    // Event callback.
    //
    // - *Mouse Action* events (`.clicked`, `.wheeled`) propagate to native strata parents unless `consumed=true` is returned
    // - `.drop_query` return value defines drop acceptance of `Context.drag.source`
    //
    // Note: Most events are emitted during `update_context()`.
    // `.left` may also be emitted immediately by `set_parent()` when a hovered view is detached or re-parented.
    on_event: proc (v: ^View, event: Event) -> (consumed: bool),

    // Drawing callback.
    //
    // If not set and view is `.text`, `Context.on_draw_text()` will be used.
    //
    // Note: Called from within `draw_context()`.
    on_draw: proc (v: ^Visible_View),
}

View :: struct {
    using init: View_Init,

    ctx: ^Context,
    idx: View_IDX, // Reusable index in `ctx.views`. Value is `0` for the root.
    sid: View_SID, // Serial number. Each time view gets `set_parent()`, the new `sid` is assigned. The value is `0` for detached views and `1` for the root.

    parent      : ^View, // Value is `nil` for the root and detached views
    next_sibling: ^View,
    first_child : ^View,

    solved_rect                 : Rect, // Solved position and size in ref units
    solved_layout_child_count   : i32,  // Solved count of visible children affected by the parent layout
    solved_opacity              : f32,  // Solved combined hierarchical opacity (0 to 1)
}

Flags :: bit_set [Flag; u32]
Flag :: enum {
    // Core

    debug,      // The view drawing will be additionally overdrawn with debug information. Only works when `Context.debug_draw_*` callbacks are set. And the `Context.debug_draw_filter` specifies what is drawn.
    hidden,     // The view and all its children are hidden. `View.solved_*` are not updated for `.hidden` views.
    hitless,    // The view cannot be the direct target of mouse hit-test, but native strata children can still make it `.hovered` and can still bubble events through it
    updating,   // The view receives `.updated` every `update_context()` while visible
    scissor,    // The view clips native strata children. Layout children are clipped to `viewport_rect(parent)` and `.absolute` children are clipped to `parent.solved_rect`.
    absolute,   // Native strata layout escape: the view is positioned by `place` and skips parent layout, scroll and padding. The parent scissor is un-padded (equals to `parent.solved_rect`).
    intext,     // The view is positioned by a custom token in the parent `.text` view and excluded from normal layout. In a stable solve, the view provides token size while the token provides view position. With `.text_wordy` parents, token size is cached: use static `.intext` sizes, or call `set_text()` on the parent after an `.intext` child size changes. This flag must not be used with `.ratio_y` or `.fill_y`.
    intext_full,// Additionally to `.intext`, the view's solved width is set to take full text line. Text token also owns view width; view still owns height. Use only with `.intext`.
    _intext_bound, // Internal solver flag. Used for tracking `.intext` view is actually bound to a token of the parent `.text` view. If `.intext` view is not bound to a token, the view itself and its subtree gets removed from `Context.visible_views`.

    // Sizing

    ratio_x,    // `size.x` is a ratio (0.5 = 50%) relative to the parent. `parent.padding` is included only for layout children.
    ratio_y,    // `size.y` is a ratio (0.5 = 50%) relative to the parent. `parent.padding` is included only for layout children. This flag cannot be used with `.intext`.
    fill_x,     // Native strata layout sizing: `solved_rect.w` takes remaining parent viewport width. In row layout, remaining width is shared evenly between layout `.fill_x` children.
    fill_y,     // Native strata layout sizing: `solved_rect.h` takes remaining parent viewport height. In column layout, remaining height is shared evenly between layout `.fill_y` children. This flag cannot be used with `.intext`.
    fit_x,      // `solved_rect.w` is set to fit visible layout children width
    fit_y,      // `solved_rect.h` is set to fit visible layout children height

    // Text

    text,       // `View.text` is in Rich Text Format. The drawing procedure should use `Visible_View.solved_text_tokens` to draw the text. `View.solved_rect.h` is determined by measured height of all the text (flags `.fit_y`, `.fill_y`, `.ratio_y` are ignored).
    text_fit_x, // Text view measures `View.solved_rect.w` from the longest unwrapped text line. Overrides `.fit_x`, `.fill_x`, and `.ratio_x`; wrapping and horizontal alignment are disabled because the text defines its own width. Useful for one-line labels followed by other row-layout views. Use only with `.text`.
    text_raw,   // Text is processed exclusively in raw mode by the tokenizer. By default, raw mode is disabled until a `|raw|` tag is encountered. This flag forces the tokenizer to process `View.text` in raw mode from start to finish, ignoring any inner `|noraw|` tags. This allows displaying unformatted text contents as-is without requiring extra string manipulation. It should only be used with `.text`.
    text_wordy, // Text tokens of the view are stored in an external buffer provided by `Context.on_text_wordy()`. By default, all text tokens are stored in `Context.visible_text_tokens`, which has a contiguous but limited capacity. This flag allows a view to contain a large amount of static text, tokenized and measured tokens are cached. Use `set_text()` to set new text and invalidate all cached data. It should only be used with `.text`.

    // Behavior

    disabled,   // The view is disabled. It does not receive `.clicked`, `.wheeled`, or `.drop_query`, and cannot capture the mouse. `.clicked` and `.wheeled` continue propagating to interaction parents.
    hovered,    // The view or any native strata children is hovered by mouse cursor. This flag is retained between `.entered` and `.left` events.
    capture,    // The view can capture mouse on button press. The `.clicked` event is fired on mouse button release. The `.dragged` event continuously fired while mouse is captured. Only one view at any given time can capture the mouse.
    drop_target,// The view can be a drop target of a drag operation. The nearest `.drop_target` under the drag pointer becomes `Context.drag.target` and receives `.drop_query` every update, unless `.disabled`.
    selected,   // The view is "selected". It is up to the `on_draw()` to respect this state. The state toggling can be automated using `.check` or `.radio` flags.
    check,      // The view inverts `.selected` when clicked and emits `.selection_changed`. The `.clicked` event does not propagate to native strata parents.
    radio,      // The view sets own `.selected` when clicked and clears it for all `.radio` siblings. The `.selection_changed` is emitted for every view which actually got updated `.selected` flag. Emit order: all de-selections -> one selection. In most cases these are two views: one de-selected and one selected. The `.clicked` event does not propagate to native strata parents.
    page,       // The view hides all `.page` siblings when gets `show()`
    wheel_scroll_x, // The view scrolls itself horizontally on mouse wheel. If scrolling changes `View.scroll`, the wheel input is considered consumed after `.wheeled` is emitted. Use only one `wheel_scroll_*`.
    wheel_scroll_y, // The view scrolls itself vertically on mouse wheel. If scrolling changes `View.scroll`, the wheel input is considered consumed after `.wheeled` is emitted. Use only one `wheel_scroll_*`.
    wheel_scroll_layout, // The view scrolls itself in the direction of `View.layout.dir` on mouse wheel. If scrolling changes `View.scroll`, the wheel input is considered consumed after `.wheeled` is emitted. This flag works only if `View.layout.dir != .none`. Use only one `wheel_scroll_*`.
}

Strata :: enum i8 {
    background  = -1,   // For lowest and generally non-interactive views like artistic decorations, HUD, damage numbers, world object labels
    base        = 0,    // For the most views, e.g. panels, buttons, health bars, action bars, non-modal dialogs
    high        = 1,    // For elevated views of `.base` parent which should avoid parent layout and clipping
    overlay     = 2,    // For priority views like menus and dropdowns. For modal dialogs, requiring immediate attention often with screen darkening layer to focus attention and block input.
    tooltip     = 3,    // For topmost and generally non-interactive transient views like tooltips, notifications, system messages
}

Place :: struct {
    anchor  : Vec2, // Parent point (0 to 1)
    pivot   : Vec2, // Local point (0 to 1)
    offset  : Vec2, // Extra offset
}

Layout :: struct {
    dir     : Layout_Direction, // Direction of the main axis. If `.none`, the layout is not used and all the fields are ignored.
    justify : Layout_Alignment, // Alignment along the main axis
    align   : Layout_Alignment, // Alignment along the cross axis
    gap     : f32,              // Spacing between adjacent children
}

Layout_Direction :: enum u8 {
    none,   // No layout. Children positioned by their `place`.
    row,    // Children arranged in a row. Their `place` is ignored.
    column, // Children arranged in a column. Their `place` is ignored.
}

Layout_Alignment :: enum u8 {
    start,  // Children aligned to the "top" or "left", depending on the axis.
    end,    // Children aligned to the "bottom" or "right" depending on the axis.
    center,
}

Event :: struct {
    type: Event_Type,
}

Event_Type :: enum u8 {
    // Core

    shown,      // The view became shown, e.g. lost `.hidden` flag. The view may not be visible still (parent is `.hidden` or clipped out by the parent scissor).
    hidden,     // The view gained `.hidden` flag
    updated,    // Continuously fired at the end of `update_context()`. Only for *visible* and `.updating` views.

    // Mouse

    entered,    // *Mouse Status* event. Fired when mouse cursor enters the view or any native strata children. Fired once for each newly-hovered view in the hit path. This event cannot be consumed.
    left,       // *Mouse Status* event. Fired when mouse cursor leaves the view and all native strata children. Fired once for each previously-hovered view that is no longer in the current hit path. This event cannot be consumed. This event might be emitted immediately when you do view tree modification, e.g. `set_parent()`, `remove_view()`. So if you do such action outside of `update_context()`, expect this event to fire also outside of `update_context()`.
    clicked,    // Propagable *Mouse Action* event. Fired when mouse clicked the view. The event is not fired for `.disabled` views. The event is fired immediately on mouse button press for non-`.capture` views, otherwise it is fired on mouse button release over the view.
    dragged,    // Continuously fired for `Context.drag.source` while drag operation is `.active`
    drop_query, // Continuously fired for the nearest `.drop_target` under the drag pointer. Does not propagate. Return `consumed=true` to accept `Context.drag.source`.
    wheeled,    // Propagable *Mouse Action* event. Fired when mouse wheel is used over the view. The event is not fired for `.disabled` views.

    // Behavior

    scrolled,   // `View.scroll` has changed. Note: solve-time clamping is silent.
    selection_changed,  // `.selected` has changed
}

// Following properties are auto-set:
// - `strata` and `level` are inherited from `parent` if not set
// - `opacity` set to `1.0` if not set
add_view :: proc (parent: ^View, init: View_Init) -> ^View {
    v := add_view_detached(parent.ctx, init)
    set_parent(v, parent)
    if v.strata == {} do v.strata = parent.strata
    if v.level == {} do v.level = parent.level
    return v
}

add_view_detached :: proc (ctx: ^Context, init: View_Init) -> ^View {
    v_idx, v := core.sparse_array_add(&ctx.views, View { init=init })
    v.idx = View_IDX(v_idx)
    v.ctx = ctx
    if v.opacity == 0 do v.opacity = 1

    ctx.stats.views_peak = max(ctx.stats.views_peak, core.sparse_array_len(ctx.views))
    return v
}

// Detaches view from its current parent and attaches it to the new parent.
// The view becomes the last child of the new parent.
//
// Pass `nil` to keep view detached.
// Detached views are effectively unreachable for `solve_context()` which uses `Context.root` to traverse the tree.
// Detached views are still part of the Context, and will be destroyed on `destroy_context()`.
set_parent :: proc (v, new_parent: ^View) {
    ensure(v.idx != 0, "Cannot re-parent or detach the root view")

    if v.parent == new_parent do return

    ensure(v != new_parent, "The new parent cannot be the view itself")
    ensure(v.parent != nil || v.parent == nil && v.next_sibling == nil, "Detached view cannot have next_sibling set")
    ensure(!view_tree_contains(v, new_parent), "The new parent cannot be a child of the view")
    ensure(new_parent == nil || v.ctx == new_parent.ctx, "Cannot parent a view to a view from another context") // This can be allowed (?). I don't see issues updating context of the view. The view and whole subtree should be moved between contexts (sparse array slots). If we ever allow it, we need to ensure both contexts are not running solve_context(). Probably if allow, make separate proc like move_view_to_context(), and this "ensure" message should hint it.
    ensure(!v.ctx.solving, "Cannot modify view tree while solve_context() is running")

    _hit_clear_if_view_tree_contains_hit(v)

    // Detach from current parent
    if v.parent != nil {
        if v.parent.first_child == v {
            v.parent.first_child = v.next_sibling
        } else {
            prev := prev_sibling(v)
            prev.next_sibling = v.next_sibling
        }
        v.parent = nil
        v.next_sibling = nil
        v.sid = 0
    }

    // Attach to new parent
    if new_parent != nil {
        new_parent_last_child := last_child(new_parent)
        if new_parent_last_child != nil {
            new_parent_last_child.next_sibling = v
        } else {
            new_parent.first_child = v
        }
        v.parent = new_parent
        v.sid = _next_view_sid(v.ctx)
    }

    queue_solve_context(v.ctx)
}

remove_view :: proc (v: ^View) {
    set_parent(v, nil)
    _remove_detached_view_tree(v)
    queue_solve_context(v.ctx)
}

_remove_detached_view_tree :: proc (v: ^View) {
    for c := v.first_child; c != nil; c = c.next_sibling {
        _remove_detached_view_tree(c)
    }

    // Clear cached wordy tokens before freeing the sparse-array slot.
    // User may key `on_text_wordy` storage by `^View`; if this slot is reused,
    // a future `.text_wordy` view could receive a non-empty stale buffer,
    // which is treated as already tokenized and measured.
    // P.S.: Maybe we need some `._text_dirty` flag to handle this more cleanly.
    if .text_wordy in v.flags do clear(_text_wordy_buffer(v))

    core.sparse_array_remove(&v.ctx.views, int(v.idx))
}

remove_children :: proc (v: ^View) {
    for v.first_child != nil {
        remove_view(v.first_child)
    }
}

// Returns index of `v` in `v.parent` children.
// - Panics if `v.parent` is not set.
// - Panics if `v.parent` children has no `v`.
@require_results
view_index :: proc (v: ^View) -> int {
    ensure(v.parent != nil)
    i: int
    for c := v.parent.first_child; c != nil; c = c.next_sibling {
        if c == v do return i
        i += 1
    }
    panic("Integrity error. View.parent doesn't contain the child. Please use `set_parent()` to correctly re-parent a view.")
}

// Returns child at given index; `v.first_child` has `index == 0`
@require_results
child_by_index :: proc (v: ^View, index: int) -> ^View {
    i: int
    for c := v.first_child; c != nil; c = c.next_sibling {
        if i == index do return c
        i += 1
    }
    return nil
}

// Returns first child with given name
@require_results
child_by_name :: proc (v: ^View, name: string) -> ^View {
    for c := v.first_child; c != nil; c = c.next_sibling {
        if c.name == name do return c
    }
    return nil
}

// Returns first child with any flag in `flags` set
@require_results
child_by_any_flags :: proc (v: ^View, flags: Flags) -> ^View {
    for c := v.first_child; c != nil; c = c.next_sibling {
        if c.flags & flags != {} do return c
    }
    return nil
}

// Returns first child which has none of `flags` set.
// Returns `v.first_child` if `flags` is empty.
@require_results
child_by_no_flags :: proc (v: ^View, flags: Flags) -> ^View {
    if flags == {} do return v.first_child
    for c := v.first_child; c != nil; c = c.next_sibling {
        if c.flags & flags == {} do return c
    }
    return nil
}

// Returns first child with all `flags` set.
// Returns `nil` if `flags` is empty.
@require_results
child_by_all_flags :: proc (v: ^View, flags: Flags) -> ^View {
    if flags == {} do return nil
    for c := v.first_child; c != nil; c = c.next_sibling {
        if c.flags & flags == flags do return c
    }
    return nil
}

@require_results
child_count :: proc (v: ^View) -> (count: int) {
    for c := v.first_child; c != nil; c = c.next_sibling do count += 1
    return
}

@require_results
last_child :: proc (v: ^View) -> ^View {
    for c := v.first_child; c != nil; c = c.next_sibling {
        if c.next_sibling == nil do return c
    }
    return nil
}

@require_results
prev_sibling :: proc (v: ^View) -> ^View {
    if v.parent.first_child != v {
        for c := v.parent.first_child; c != nil; c = c.next_sibling {
            if c.next_sibling == v do return c
        }
    }
    return nil
}

// Moves `v` to become `v.parent.first_child`
bring_to_start :: proc (v: ^View) {
    ensure(v.parent != nil)
    ensure(!v.ctx.solving, "Cannot modify view tree while solve_context() is running")

    if v.parent.first_child == v do return

    prev := prev_sibling(v)
    prev.next_sibling = v.next_sibling
    v.next_sibling = v.parent.first_child
    v.parent.first_child = v

    queue_solve_context(v.ctx)
}

// Moves `v` to become `last_child(v.parent)`
bring_to_end :: proc (v: ^View) {
    ensure(v.parent != nil)
    ensure(!v.ctx.solving, "Cannot modify view tree while solve_context() is running")

    if v.next_sibling == nil do return

    prev := prev_sibling(v)
    if prev != nil {
        prev.next_sibling = v.next_sibling
    } else {
        v.parent.first_child = v.next_sibling
    }

    last := last_child(v.parent)
    last.next_sibling = v
    v.next_sibling = nil

    queue_solve_context(v.ctx)
}

// Returns true if `child` is `v` or inside its subtree
@require_results
view_tree_contains :: proc (v, child: ^View) -> bool {
    for c := child; c != nil; c = c.parent {
        if c == v do return true
    }
    return false
}

// Returns the next parent in the interaction path.
//
// Interaction propagation stops at strata boundaries, because non-native strata
// views are elevated out of the parent's layout/clipping/input flow.
@require_results
_interaction_parent :: proc (v: ^View) -> ^View {
    if v.parent != nil && v.parent.strata == v.strata do return v.parent
    return nil
}

// Returns `v` or its first interaction parent containing any `include` flag
// and none of the `exclude` flags. Empty flag sets are ignored.
@require_results
_interaction_parent_by_any_flags :: proc (v: ^View, include := Flags {}, exclude := Flags {}) -> ^View {
    for p := v; p != nil; p = _interaction_parent(p) {
        if (include == {} || p.flags & include != {}) &&
           (exclude == {} || p.flags & exclude == {}) {
            return p
        }
    }
    return nil
}

// Returns true if `parent` is `v` or inside its interaction path
@require_results
_interaction_path_contains :: proc (v, parent: ^View) -> bool {
    for p := v; p != nil; p = _interaction_parent(p) {
        if p == parent do return true
    }
    return false
}

_hit_clear_if_view_tree_contains_hit :: proc (v: ^View) {
    if v.ctx.hit != nil && view_tree_contains(v, v.ctx.hit) {
        _hit_set_view(v.ctx, nil)
    }
}

_clear_children_intext_bound_flag :: proc (v: ^View) {
    for c := v.first_child; c != nil; c = c.next_sibling {
        if .intext in c.flags do c.flags -= { ._intext_bound }
    }
}

Child_Iterator :: struct {
    next_child      : ^View,
    next_child_i    : int,
    strata_filter   : bit_set [Strata],
}

// If `strata_filter` is empty, it defaults to native strata children only
@require_results
child_iterate :: proc (v: ^View, strata_filter := bit_set [Strata] {}) -> (iter: Child_Iterator) {
    return {
        next_child = v.first_child,
        strata_filter = strata_filter != {} ? strata_filter : { v.strata },
    }
}

@require_results
child_next :: proc (it: ^Child_Iterator) -> (c: ^View, i: int, ok: bool) {
    for c = it.next_child; c != nil; c = c.next_sibling {
        if c.strata in it.strata_filter {
            ok = true
            i = it.next_child_i
            it.next_child_i += 1
            it.next_child = c.next_sibling
            return
        }
    }
    return
}

Set_Filter :: bit_set [enum { self, children }]

set_debug :: proc (v: ^View, on: bool, filter: bit_set [enum { self, children }] = ~{}) {
    set :: proc (v: ^View, on: bool) { if on { v.flags+={.debug} } else { v.flags-={.debug} } }
    if .self in filter do set(v, on)
    if .children in filter do for c := v.first_child; c != nil; c = c.next_sibling {
        set(c, on)
        if c.first_child != nil do set_debug(c, on, { .children })
    }
}

set_strata :: proc (v: ^View, strata: Strata, filter := ~Set_Filter{}) {
    if .self in filter do v.strata = strata
    if .children in filter do for c := v.first_child; c != nil; c = c.next_sibling {
        c.strata = strata
        if c.first_child != nil do set_strata(c, strata, { .children })
    }
    queue_solve_context(v.ctx)
}

set_text :: proc (v: ^View, text: string) {
    ensure(!v.ctx.solving)
    ensure(!v.ctx.drawing)
    v.text = text
    if .text_wordy in v.flags do clear(_text_wordy_buffer(v))
    queue_solve_context(v.ctx)
}

_text_wordy_buffer :: proc (v: ^View) -> (buf: ^[dynamic] Text_Token) {
    assert(v.ctx.on_text_wordy != nil, "Context.on_text_wordy must be set when using .text_wordy views")
    buf = v.ctx.on_text_wordy(v)
    assert(buf != nil, "Context.on_text_wordy must not return nil")
    return
}

_emit :: proc (v: ^View, e: Event) -> (consumed: bool) {
    return v.on_event != nil ? v->on_event(e) : false
}

show :: proc (v: ^View) {
    if .hidden in v.flags {
        v.flags -= { .hidden }
        _emit(v, { type=.shown })
        queue_solve_context(v.ctx)
    }

    if .page in v.flags && v.parent != nil {
        for s := v.parent.first_child; s != nil; s = s.next_sibling {
            if s != v && .page in s.flags do hide(s)
        }
    }
}

hide :: proc (v: ^View) {
    if .hidden not_in v.flags {
        v.flags += { .hidden }
        _emit(v, { type=.hidden })
        queue_solve_context(v.ctx)
    }
}

// Fires `.clicked` event for the view as it would be clicked with a mouse.
//
// The event will be propagated to native strata parents until consumed.
// If you're in a parent view and want to re-route the event to a child view
// (which might not consume the event), you can `click_one()` to avoid recursive propagation.
click :: proc (v: ^View) -> (consumed: bool) {
    for i := v; i != nil; i = _interaction_parent(i) do if click_one(i) do return true
    return
}

// Fires `.clicked` event for the view as it would be clicked with a mouse.
// No propagation.
click_one :: proc (v: ^View) -> (consumed: bool) {
    if .disabled in v.flags do return false

    check_consumed: bool
    if .check in v.flags {
        v.flags ~= { .selected }
        _emit(v, { type=.selection_changed })
        check_consumed = true
    }

    radio_consumed: bool
    if .radio in v.flags && v.parent != nil {
        for s := v.parent.first_child; s != nil; s = s.next_sibling {
            if s != v && .selected in s.flags {
                s.flags -= { .selected }
                _emit(s, { type=.selection_changed })
            }
        }

        if .selected not_in v.flags {
            v.flags += { .selected }
            _emit(v, { type=.selection_changed })
        }

        radio_consumed = true
    }

    clicked_consumed := _emit(v, { type=.clicked })
    return check_consumed || radio_consumed || clicked_consumed
}

// Fires `.wheeled` event for the view as it would be scrolled with a mouse wheel.
//
// The event will be propagated to native strata parents until consumed.
// If you're in a parent view and want to re-route the event to a child view
// (which might not consume the event), you can `wheel_one()` to avoid recursive propagation.
wheel :: proc (v: ^View) -> (consumed: bool) {
    for i := v; i != nil; i = _interaction_parent(i) do if wheel_one(i) do return true
    return
}

// Fires `.wheeled` event for the view as it would be scrolled with a mouse wheel.
// No propagation.
wheel_one :: proc (v: ^View) -> (consumed: bool) {
    if .disabled in v.flags do return false

    scrolled: bool
    switch {
    case .wheel_scroll_x in v.flags:
        scrolled = scroll_by_step(v, { v.ctx.mouse.wheel_delta, 0 })
    case .wheel_scroll_y in v.flags:
        scrolled = scroll_by_step(v, { 0, v.ctx.mouse.wheel_delta })
    case .wheel_scroll_layout in v.flags:
        if v.layout.dir != .none {
            scrolled = scroll_layout_by_step(v, v.ctx.mouse.wheel_delta)
        }
    }

    wheeled_consumed := _emit(v, { type=.wheeled })
    return scrolled || wheeled_consumed
}

// Padded viewport rect for layout children.
// Also a scissor rect for them in case `.scissor` flag is used.
@require_results
viewport_rect :: proc (v: ^View) -> Rect {
    return {
        v.solved_rect.x + v.padding[0],
        v.solved_rect.y + v.padding[1],
        max(0, v.solved_rect.w - (v.padding[0] + v.padding[2])),
        max(0, v.solved_rect.h - (v.padding[1] + v.padding[3])),
    }
}

// Total size needed to fit all layout children
@require_results
content_size :: proc (v: ^View) -> Vec2 {
    bottom_right := content_bottom_right(v)
    top_left := content_top_left(v)
    return {
        max(0, bottom_right.x - top_left.x),
        max(0, bottom_right.y - top_left.y),
    }
}

// Padded and scrolled top-left point for layout children
@require_results
content_top_left :: proc (v: ^View) -> Vec2 {
    return {
        v.solved_rect.x + v.padding[0] + v.scroll.x,
        v.solved_rect.y + v.padding[1] + v.scroll.y,
    }
}

// Farthest bottom-right point of layout children
@require_results
content_bottom_right :: proc (v: ^View) -> (result: Vec2) {
    for c := v.first_child; c != nil; c = c.next_sibling {
        if .hidden in c.flags || !_is_layout_child(c) do continue
        result.x = max(result.x, c.solved_rect.x + c.solved_rect.w)
        result.y = max(result.y, c.solved_rect.y + c.solved_rect.h)
    }
    return
}

// Scroll minimum value.
// Returned components are always `<=0`.
//
// The scrolling offset `View.scroll` moves in range `scroll_min()...{0,0}`, that is why there is
// no "scroll_max()" as it is always zero. Content without any scroll is sitting at zero (maximum scroll).
@require_results
scroll_min :: proc (v: ^View) -> Vec2 {
    viewport_rect_ := viewport_rect(v)
    content_size_ := content_size(v)
    return {
        -max(0, content_size_.x - viewport_rect_.w),
        -max(0, content_size_.y - viewport_rect_.h),
    }
}

scroll_to :: proc (v: ^View, value: Vec2) -> (scrolled: bool) {
    scroll_min_ := scroll_min(v)
    new_scroll := Vec2 {
        clamp(value.x, scroll_min_.x, 0),
        clamp(value.y, scroll_min_.y, 0),
    }

    if new_scroll != v.scroll {
        v.scroll = new_scroll
        queue_solve_context(v.ctx)
        _emit(v, { type=.scrolled })
        scrolled = true
    }

    return
}

scroll_by :: proc (v: ^View, offset: Vec2) -> (scrolled: bool) {
    return scroll_to(v, v.scroll + offset)
}

scroll_by_step :: proc (v: ^View, magnitude: Vec2) -> (scrolled: bool) {
    step := v.ctx.scroll_step != {}\
        ? v.ctx.scroll_step\
        : { v.ctx.ref_font_height, v.ctx.ref_font_height }
    return scroll_by(v, magnitude * step)
}

scroll_to_start :: proc (v: ^View) {
    scroll_to(v, {})
}

scroll_to_end :: proc (v: ^View) {
    scroll_to(v, scroll_min(v))
}

scroll_layout_to_start :: proc (v: ^View) {
    switch v.layout.dir {
    case .none  : panic("The view has no layout")
    case .row   : scroll_to(v, { 0, v.scroll.y })
    case .column: scroll_to(v, { v.scroll.x, 0 })
    }
}

scroll_layout_to_end :: proc (v: ^View) {
    switch v.layout.dir {
    case .none  : panic("The view has no layout")
    case .row   : scroll_to(v, { scroll_min(v).x, v.scroll.y })
    case .column: scroll_to(v, { v.scroll.x, scroll_min(v).y })
    }
}

scroll_layout_by_step :: proc (v: ^View, magnitude: f32) -> (scrolled: bool) {
    switch v.layout.dir {
    case .none  : panic("The view has no layout")
    case .row   : return scroll_by_step(v, { magnitude, 0 })
    case .column: return scroll_by_step(v, { 0, magnitude })
    }
    return
}
