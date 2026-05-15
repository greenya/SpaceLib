package hi

import "../core"

View_ID :: distinct int

View_Init :: struct {
    flags: bit_set [Flag; u16],

    using bits: bit_field u16 {
        level   : int       | 12,   // Order within `strata`, 12 bits, approx. range -2000..+2000
        strata  : Strata    | 4,    // Drawing layer
    },

    placement   : Placement,// Used only if parent `layout.dir == .none`
    size        : Vec2,     // Width and height, assuming "fixed value" when `.fit_*` or `.fill_*` is not used; `.ratio_*` allows to interpret value as fraction of the parent
    padding     : Vec4,     // Padding for the children in order: 0=left, 1=top, 2=right, 3=bottom
    scroll      : Vec2,     // Offset for the children
    layout      : Layout,   // Layout for the children

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

    ctx : ^Context,
    id  : View_ID,

    parent      : ^View,
    next_sibling: ^View,
    first_child : ^View,

    // Solver result in ref units. Not updated for invisible views.
    solved: struct {
        pos         : Vec2,
        size        : Vec2,
        child_count : int,  // Visible child count
    },
}

Flag :: enum {
    // Core

    hidden,     // The view and all its children are hidden. `View.solved` is not updated for `.hidden` views.
    debug,      // The view drawing will be additionally overdrawn via `Context.debug_draw_rect()`.
    scissor,    // FIX: [NOT IMPLEMENTED] The view clips its children of the equal `strata`. The clipping is applied according to the `content_rect()`. // TODO: should affect drawing and mouse hit test

    // Sizing

    ratio_x,    // `size.x` is a ratio (0.5 = 50%) relative to the parent
    ratio_y,    // `size.y` is a ratio (0.5 = 50%) relative to the parent
    fit_x,      // `solved.size.x` is set to fit children width
    fit_y,      // `solved.size.y` is set to fit children height
    fill_x,     // `solved.size.x` is set to all remaining parent width. Space is shared evenly between all `.fill_x` views.
    fill_y,     // `solved.size.y` is set to all remaining parent height. Space is shared evenly between all `.fill_y` views.

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
    selected,   // The view is "selected". It is up to the `View.on_draw()` to respect this state. The state toggling can be automated using `.check` or `.ratio` flags
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
    //
    //              Maybe consider ways to add "View.strata" field. Maybe make flags to be bit_field, and take 3 bits for "strata".
    //              This will complicate update_context() and draw_context(), but will allow to add dropdown or tooltip directly to
    //              the target view (as child of it), with some higher strata, which should not be considered as "child" for any logic,
    //              but only for anchoring logic, it should also affect drawing order, all the views with the highest strata should be
    //              drawn last (on top of anything)
    //
    //              Maybe consider ways of building plain list of visible views ordered in a draw-order (painter algorithm), so
    //              draw_context() becomes trivial, and all the mouse hit tests can benefit from this list.
}

Strata :: enum {
    background  = -1,   // For lowest and generally non-interactive views like artistic decorations, HUD, damage numbers, world object labels
    base        = 0,    // For the most views, e.g. panels, buttons, health bars, action bars, non-modal dialogs
    overlay     = 1,    // For priority views like menus and dropdowns which should avoid parent clipping (only if parent uses `base` strata). For modal dialogs, requiring immediate attention often with screen darkening layer to focus attention and block input.
    tooltip     = 2,    // For topmost and generally non-interactive transient views like tooltips, notifications, system messages
}

Placement :: struct {
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
    none,   // Children positioned by their `placement`.
    row,    // Children arranged in a row. Their `placement` is ignored.
    column, // Children arranged in a column. Their `placement` is ignored.
}

Layout_Alignment :: enum u8 {
    start,  // Children aligned to the "top" or "left", depending on the axis.
    end,    // Children aligned to the "bottom" or "right" depending on the axis.
    center,
}

add_view :: proc (parent: ^View, init: View_Init) -> ^View {
    v_id, v := core.sparse_array_add(&parent.ctx.views, View { init=init })
    v.id = View_ID(v_id)
    v.ctx = parent.ctx
    v.parent = parent

    if v.strata == {} {
        v.strata = v.parent.strata
    }

    parent_last_child := last_child(parent)
    if parent_last_child != nil {
        parent_last_child.next_sibling = v
    } else {
        parent.first_child = v
    }

    v.ctx.dirty = true
    return v
}

last_child :: proc (v: ^View) -> ^View {
    for child := v.first_child; child != nil; child = child.next_sibling {
        if child.next_sibling == nil do return child
    }
    return nil
}

Set_Filter :: bit_set [enum { self, children }]

set_debug :: proc (v: ^View, on: bool, filter: bit_set [enum { self, children }] = ~{}) {
    set :: proc (v: ^View, on: bool) { if on { v.flags+={.debug} } else { v.flags-={.debug} } }
    if .self in filter do set(v, on)
    if .children in filter do for child := v.first_child; child != nil; child = child.next_sibling {
        set(child, on)
        if child.first_child != nil do set_debug(child, on, { .children })
    }
}

set_strata :: proc (v: ^View, strata: Strata, filter := ~Set_Filter{}) {
    if .self in filter do v.strata = strata
    if .children in filter do for child := v.first_child; child != nil; child = child.next_sibling {
        child.strata = strata
        if child.first_child != nil do set_strata(child, strata, { .children })
    }
    v.ctx.dirty = true
}

content_rect :: proc (v: ^View) -> Rect {
    return {
        v.solved.pos.x + v.padding[0],
        v.solved.pos.y + v.padding[1],
        max(0, v.solved.size.x - (v.padding[0] + v.padding[2])),
        max(0, v.solved.size.y - (v.padding[1] + v.padding[3])),
    }
}
