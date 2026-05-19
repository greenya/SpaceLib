package hi

import "../core"

View_IDX :: distinct i32
View_UID :: distinct i32

View_Init :: struct {
    flags: bit_set [Flag; u16],

    using bits: bit_field u16 {
        strata  : Strata    | 4,    // Elevation layer: drawing order goes low->high, mouse hit test order goes high->low
        level   : int       | 12,   // Order within `strata`, 12 bits, approx. range -2000..+2000
    },

    size    : Vec2,     // Width and height, assuming "fixed value" when `.fit_*` or `.fill_*` is not used; `.ratio_*` allows to interpret value as fraction of the parent
    place   : Place,    // Used only if parent has no layout or for non-native `strata`
    padding : Vec4,     // Padding for native strata children in order: 0=left, 1=top, 2=right, 3=bottom
    scroll  : Vec2,     // Offset for native strata children
    layout  : Layout,   // Layout for native strata children

    on_draw: proc (v: ^View),
    // on_state: (show/hide/select/deselect)
    // on_mouse: (status: enter/leave), (action: click/wheel/drag)
    // TODO: maybe combine all events into on_event, the pro: less callbacks and less size of View, the con: more false calls

    // USER DATA
    name: string,
    // user_idx: int,
    // user_ptr: rawptr,
}

View :: struct {
    using init: View_Init,

    ctx: ^Context,
    idx: View_IDX,  // Reusable index in the `ctx.views`
    uid: View_UID,  // Unique ID for the whole runtime

    parent      : ^View,
    next_sibling: ^View,
    first_child : ^View,

    // Solver result in ref units. Not updated for invisible views.
    solved: struct {
        rect                : Rect,
        parent_scissor      : Rect, // Scissor rect this view is clipped by. If empty, the scissor is disabled.
        layout_child_count  : i32,  // Count of visible native strata children affected by the `layout`
    },
}

Flag :: enum {
    // Core

    hidden,     // The view and all its children are hidden. `View.solved` is not updated for `.hidden` views.
    debug,      // The view drawing will be additionally overdrawn via `Context.debug_draw_rect()`.
    scissor,    // The view clips native strata children. The clipping is applied according to the `content_rect()`. // TODO: should affect drawing and mouse hit test

    // Sizing

    ratio_x,    // `size.x` is a ratio (0.5 = 50%) relative to the parent. The `parent.padding` included only for native strata children.
    ratio_y,    // `size.y` is a ratio (0.5 = 50%) relative to the parent. The `parent.padding` included only for native strata children.
    fit_x,      // `solved.rect.w` is set to fit native strata children width
    fit_y,      // `solved.rect.h` is set to fit native strata children height
    fill_x,     // `solved.rect.w` is set to all remaining parent width. Space is shared evenly between all `.fill_x` native strata views.
    fill_y,     // `solved.rect.h` is set to all remaining parent height. Space is shared evenly between all `.fill_y` native strata views.

    // Behavior

    // TODO: All events should be given from the top visible view to the bottom (root)
    // - if view doesn't have on_*, the event keeps propagation to the next (bottom) view
    // - if view has on_*, the event callback is executed and the event considered to be consumed, propagation stops
    //      // TODO: maybe add return value (keep_bubbling_up: bool), or flag into Event struct, or something,
    //               to allow receiving event and keep propagation, so for example adding fullscreen top most view
    //               can catch all the events (for debugging maybe) and all the views below still receive events and work
    //               Maybe instead of return bool, this can be done via extra Flag, e.g. ".observer"
    //      With this approach we don't need "pass" or "pass_self" or "block_wheel" flags (like spacelib:ui does)

    disabled,   // FIX: [NOT IMPLEMENTED] The view is disabled, it will not receive Mouse Action Events (click, wheel, drag)
    capture,    // FIX: [NOT IMPLEMENTED] The view can capture mouse when clicked; the click event will be fired on mouse button release
    selected,   // The view is "selected". It is up to the `View.on_draw()` to respect this state. The state toggling can be automated using `.check` or `.radio` flags
    check,      // FIX: [NOT IMPLEMENTED] The view inverts `.selected` when clicked
    radio,      // FIX: [NOT IMPLEMENTED] The view sets own `.selected` when clicked and clears it for all `.radio` siblings
    // auto_hide // TODO: think more on auto_hide flag.
    //              In spacelib:ui, this flag was intended to be used for dropdown menus and similar popups
    //              which should be closed if clicked outside; the task apparently wasn't that simple and
    //              obvious, and the flag wasn't very useful.
    //              Before this flag, we need to think about tooltips and dropdowns, they are special and should be drawn above
    //              other elements. In spacelib:ui's demo this was manually solved by creating and managing a separate layer,
    //              because if we open dropdown inside list of items, the next item in the list will be drawn above the items
    //              of the dropdown as it is spawned just after the list item. "Separate layer" in spacelib:ui was working because
    //              it supports anchoring of frames to any frame, not just parent. In this library we have only child-parent anchoring.
}

Strata :: enum {
    background  = -1,   // For lowest and generally non-interactive views like artistic decorations, HUD, damage numbers, world object labels
    base        = 0,    // For the most views, e.g. panels, buttons, health bars, action bars, non-modal dialogs
    overlay     = 1,    // For priority views like menus and dropdowns which should avoid parent clipping (if parent uses different strata). For modal dialogs, requiring immediate attention often with screen darkening layer to focus attention and block input.
    tooltip     = 2,    // For topmost and generally non-interactive transient views like tooltips, notifications, system messages
}

Place :: struct {
    anchor  : Vec2, // Parent point (0 to 1)
    pivot   : Vec2, // Local point (0 to 1)
    offset  : Vec2, // Extra offset
}

Layout :: struct {
    dir     : Layout_Direction, // Direction of the main axis
    justify : Layout_Alignment, // Alignment along the main axis
    align   : Layout_Alignment, // Alignment along the cross axis
    gap     : f32,              // Spacing between adjacent children
}

Layout_Direction :: enum u8 {
    none,   // Children positioned by their `place`.
    row,    // Children arranged in a row. Their `place` is ignored.
    column, // Children arranged in a column. Their `place` is ignored.
}

Layout_Alignment :: enum u8 {
    start,  // Children aligned to the "top" or "left", depending on the axis.
    end,    // Children aligned to the "bottom" or "right" depending on the axis.
    center,
}

add_view :: proc (parent: ^View, init: View_Init) -> ^View {
    v := add_view_detached(parent.ctx, init)
    set_parent(v, parent)
    if v.strata == {} do v.strata = parent.strata
    return v
}

add_view_detached :: proc (ctx: ^Context, init: View_Init) -> ^View {
    v_idx, v := core.sparse_array_add(&ctx.views, View { init=init })
    v.idx = View_IDX(v_idx)
    v.uid = ctx.next_view_uid
    ctx.next_view_uid += 1
    v.ctx = ctx
    return v
}

// Detaches view from its current parent and attaches it to the new parent.
// The view becomes the last child of the new parent.
//
// Pass `nil` to keep view detached.
// Detached views are effectively unreachable for `solve_context()` which uses `Context.root` to traverse the tree.
// Detached views are still part of the Context, and will be destroyed on `destroy_context()`.
set_parent :: proc (v, new_parent: ^View) {
    if v.parent == new_parent do return

    ensure(v != new_parent, "The new parent cannot be the view itself")
    ensure(v.parent != nil || v.parent == nil && v.next_sibling == nil, "Detached view cannot have next_sibling set")

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
    }

    v.ctx.solved = false
}

remove_view :: proc (v: ^View) {
    set_parent(v, nil)
    _remove_detached_view_tree(v)
    v.ctx.solved = false
}

_remove_detached_view_tree :: proc (v: ^View) {
    for c := v.first_child; c != nil; c = c.next_sibling {
        _remove_detached_view_tree(c)
    }
    core.sparse_array_remove(&v.ctx.views, int(v.idx))
}

last_child :: proc (v: ^View) -> ^View {
    for c := v.first_child; c != nil; c = c.next_sibling {
        if c.next_sibling == nil do return c
    }
    return nil
}

prev_sibling :: proc (v: ^View) -> ^View {
    if v.parent.first_child != v {
        for c := v.parent.first_child; c != nil; c = c.next_sibling {
            if c.next_sibling == v do return c
        }
    }
    return nil
}

Child_Iterator :: struct {
    next_child      : ^View,
    strata_filter   : bit_set [Strata],
}

// If `strata_filter` is empty, it defaults to native strata children only
child_iterate :: proc (v: ^View, strata_filter := bit_set [Strata] {}) -> (iter: Child_Iterator) {
    return {
        next_child = v.first_child,
        strata_filter = strata_filter != {} ? strata_filter : { v.strata },
    }
}

child_next :: proc (it: ^Child_Iterator) -> (v: ^View, ok: bool) {
    for c := it.next_child; c != nil; c = c.next_sibling {
        if c.strata in it.strata_filter {
            it.next_child = c.next_sibling
            return c, true
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
    v.ctx.solved = false
}

content_rect :: proc (v: ^View) -> Rect {
    return {
        v.solved.rect.x + v.padding[0],
        v.solved.rect.y + v.padding[1],
        max(0, v.solved.rect.w - (v.padding[0] + v.padding[2])),
        max(0, v.solved.rect.h - (v.padding[1] + v.padding[3])),
    }
}
