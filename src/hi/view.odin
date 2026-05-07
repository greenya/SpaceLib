package hi

ID :: distinct i32

View_Init :: struct {
    flags: bit_set [Flag; u32],

    placement   : Placement,// Used only if parent `layout.dir == .none`
    size        : [2] f32,  // Width and height, assuming "fixed value" when `.fit_*` or `.fill_*` is not used; `.ratio_*` allows to interpret value as fraction of the parent
    padding     : [4] f32,  // Padding for the children in order: 0=left, 1=top, 2=right, 3=bottom
    scroll      : [2] f32,  // Offset for the children
    layout      : Layout,   // Layout for the children

    on_draw: View_Draw_Proc,
    // on_state: (show/hide/selected/unselected)
    // on_mouse: (status: enter/leave), (action: click/wheel/drag)

    // USER DATA
    name: string,
    // user_idx: int,
    // user_ptr: rawptr,
}

View :: struct {
    using init: View_Init,

    parent      : ID,       // `>= 0`, where `0` is root; and `root.parent == 0`
    next_sibling: ID,       // `>0` if set, and `0` when not used
    first_child : ID,       // `>0` if set, and `0` when not used

    // Solver result in ref units. Not updated for invisible views.
    solved: struct {
        pos         : [2] f32,
        size        : [2] f32,
        child_count : int,  // Visible child count
    },
}

Flag :: enum u8 {
    // Core

    hidden,     // The view and all its children are hidden. `View.solved` is not updated for `.hidden` views.
    debug,      // The view drawing will be additionally overdrawn via `Context.debug_draw_rect()`.
    scissor,    // [NOT IMPLEMENTED] The view clips its children. The scissor rect is defined by the `solved` rect reduced by `padding`. // TODO: should affect drawing and mouse hit test

    // Events

    // TODO: All events should be given from the top visible view to the bottom (root)
    // - if view doesn't have on_*, the event keeps propagation to the next (bottom) view
    // - if view has on_*, the event callback is executed and the event considered to be consumed, propagation stops
    //      // TODO: maybe add return value (keep_bubbling_up: bool), or flag into Event struct, or something,
    //               to allow receiving event and keep propagation, so for example adding fullscreen top most view
    //               can catch all the events (for debugging maybe) and all the views below still receive events and work
    //               Maybe instead of return bool, this can be done via extra Flag, e.g. ".observer"
    //      With this approach we don't need "pass" or "pass_self" or "block_wheel" flags (like spacelib:ui does)

    disabled,   // [NOT IMPLEMENTED] The view is disabled, it will not receive Mouse Action Events (click, wheel, drag)
    capture,    // [NOT IMPLEMENTED] The view can capture mouse when clicked; the click event will be fired on mouse button release
    check,      // [NOT IMPLEMENTED] The view inverts `.selected` when clicked
    radio,      // [NOT IMPLEMENTED] The view sets own `.selected` when clicked and clears it for all `.radio` siblings
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

    // Sizing

    ratio_x,    // `size.x` is a ratio (0.5 = 50%) relative to the parent
    ratio_y,    // `size.y` is a ratio (0.5 = 50%) relative to the parent
    fit_x,      // `solved.size.x` is set to fit children width
    fit_y,      // `solved.size.y` is set to fit children height
    fill_x,     // `solved.size.x` is set to all remaining parent width. Space is shared evenly between all `.fill_x` views.
    fill_y,     // `solved.size.y` is set to all remaining parent height. Space is shared evenly between all `.fill_y` views.
}

Placement :: struct {
    anchor  : [2] f32, // Parent point (0 to 1)
    pivot   : [2] f32, // Local point (0 to 1)
    offset  : [2] f32, // Extra offset
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

View_Draw_Proc :: #type proc (v: ^View /*, is_after := false*/) // TODO: maybe add .draw_after flag, if set, this proc will be called extra time with is_after=true

append_view :: proc (ctx: ^Context, parent: ID, init: View_Init) -> ID {
    n, err := append(&ctx.views, View { init=init })
    assert(n == 1 && err == nil)

    id := ID(-1 + len(ctx.views))
    ctx.views[id].parent = parent

    parent_last_child := last_child(ctx, parent)
    if parent_last_child > 0 {
        ctx.views[parent_last_child].next_sibling = id
    } else {
        ctx.views[parent].first_child = id
    }

    return id
}

// Returns `0` if no children
last_child :: proc (ctx: ^Context, id: ID) -> ID {
    child_id := ctx.views[id].first_child
    if child_id > 0 {
        for ctx.views[child_id].next_sibling > 0 {
            child_id = ctx.views[child_id].next_sibling
        }
    }
    return child_id
}

@private
draw_view_children :: proc (ctx: ^Context, parent_id: ID, debug: bool) {
    child_id := ctx.views[parent_id].first_child
    for child_id > 0 {
        child := &ctx.views[child_id]
        defer child_id = child.next_sibling
        if .hidden in child.flags do continue

        child_debug := debug || .debug in child.flags

        if child.on_draw != nil     do child->on_draw()
        if child.first_child > 0    do draw_view_children(ctx, child_id, child_debug)
        if child_debug              do debug_draw_view(ctx, child_id)
    }
}

@private
view_scissor_rect :: proc (ctx: ^Context, v: ^View) -> Rect {
    return {
        v.solved.pos.x + v.padding[0],
        v.solved.pos.y + v.padding[1],
        max(0, v.solved.size.x - (v.padding[0] + v.padding[2])),
        max(0, v.solved.size.y - (v.padding[1] + v.padding[3])),
    }
}
