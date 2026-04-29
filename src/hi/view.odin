package hi

// TODO: Support for Free-Floating Fit, e.g. when parent doesn't have `layout`,
//       but still want its size to be updated, to fit all children, who are placed
//       via their `placement`.

// TODO: Support .scissor flag

ID :: distinct i32

View :: struct {
    name        : string,
    flags       : bit_set [Flag; u32],

    parent      : ID,       // `>= 0`, where `0` is root; and `root.parent == 0`
    next_sibling: ID,       // `>0` if set, and `0` when not used
    first_child : ID,       // `>0` if set, and `0` when not used

    placement   : Placement,// Used only if parent `layout.dir == .none`
    size        : [2] f32,  // Width and height, assuming "fixed value" when `.fit_*` or `.fill_*` is not used; `.ratio_*` allows to interpret value as fraction of the parent
    padding     : [4] f32,  // Padding for the children in order: 0=left, 1=top, 2=right, 3=bottom
    scroll      : [2] f32,  // Offset for the children
    layout      : Layout,   // Layout for the children

    // Solver result in ref units. Not updated for invisible views.
    computed: struct {
        pos         : [2] f32,
        size        : [2] f32,
        child_count : int,  // Visible child count
    },

    // EVENT HANDLING -- SKIP FOR NOW
    // on_mouse: proc (v: ^View, event: Mouse_Event),
    // on_draw: proc (v: ^View),

    // USER DATA -- SKIP FOR NOW
    // user_idx: int,
    // user_ptr: rawptr,
}

Flag :: enum u8 {
    hidden,     // The view and all its children are hidden. `View.computed` is not updated for hidden views.
    scissor,    // [NOT IMPLEMENTED] The view clips its children. // TODO: should affect drawing and mouse hit test

    // Sizing

    ratio_x,    // `size.x` is a ratio (0.5 = 50%) relative to the parent
    ratio_y,    // `size.y` is a ratio (0.5 = 50%) relative to the parent
    fit_x,      // `computed.size.x` is set to fit children width
    fit_y,      // `computed.size.y` is set to fit children height
    fill_x,     // `computed.size.x` is set to all remaining parent width. Space is shared evenly between all `.fill_x` views.
    fill_y,     // `computed.size.y` is set to all remaining parent height. Space is shared evenly between all `.fill_y` views.
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

append_view :: proc (ctx: ^Context, parent: ID, init: View) -> ID {
    n, err := append(&ctx.views, init)
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

// Returns 0 on error
// ? Maybe just add View.prev_sibling field?
// prev_sibling :: proc (ctx: ^Context, id: ID) -> ID {
//     child_id := ctx.views[ctx.views[id].parent].first_child
//     if child_id == id do return 0 // we are the first child, no prev sibling
//     if child_id > 0 {
//         for ctx.views[child_id].next_sibling > 0 {
//             if id == ctx.views[child_id].next_sibling do break
//             child_id = ctx.views[child_id].next_sibling
//         }
//     }
//     return child_id
// }

// TODO: add shortcuts for setting the padding
// set_padding(v, 10) // this one is almost useless, as padding=10 does it
// set_padding_vh(v, vertical=5, horizontal=10)
// set_padding_ltrb(v, left=10, top=5, right=10, bottom=5)
