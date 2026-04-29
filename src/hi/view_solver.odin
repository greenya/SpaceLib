#+private
package hi

solve_view_tree :: proc (ctx: ^Context) {
    // Root is special: always takes whole ref size, ignoring `flags`, `size`, `padding` and `layout`;
    // also `computed.pos` and `computed.child_count` are zeroed
    ctx.views[0].computed = { size=ctx.ref_size }

    solve_view_fit_and_fixed_size(ctx, 0)
    solve_children_fill_and_ratio_size(ctx, 0)
}

// Bottom-up solver for `.fit_*` and fixed sizes.
// Updates following properties for the non-root `id`:
// - `computed.size` updated only if `fit_*` or fixed size
// - `computed.child_count` updated
solve_view_fit_and_fixed_size :: proc(ctx: ^Context, id: ID) {
    v := &ctx.views[id]

    // Recurse to children first
    child_id := v.first_child
    for child_id > 0 {
        child := &ctx.views[child_id]
        if .hidden not_in child.flags do solve_view_fit_and_fixed_size(ctx, child_id)
        child_id = child.next_sibling
    }

    if id == 0 do return

    child_count, fit_size := view_content_fit(ctx, id)
    v.computed.child_count = child_count

    if .fit_x in v.flags {
        v.computed.size.x = fit_size.x
    } else if v.flags & { .ratio_x, .fill_x } != {} {
        // Skip parent-dependent width for next solver
    } else {
        v.computed.size.x = v.size.x
    }

    if .fit_y in v.flags {
        v.computed.size.y = fit_size.y
    } else if v.flags & { .ratio_y, .fill_y } != {} {
        // Skip parent-dependent height for next solver
    } else {
        v.computed.size.y = v.size.y
    }
}

// Top-down solver for `.fill_*` and `ratio_*` sizes.
// Updates following properties for the children of `parent_id`:
// - `computed.size` updated only if `fill_*` or `ratio_*` size
// - `computed.pos` updated
solve_children_fill_and_ratio_size :: proc (ctx: ^Context, parent_id: ID) {
    v := &ctx.views[parent_id]

    v_size_x_avail := max(0, v.computed.size.x - (v.padding[0] + v.padding[2]))
    v_size_y_avail := max(0, v.computed.size.y - (v.padding[1] + v.padding[3]))

    v_gaps_total := v.computed.child_count > 0\
        ? f32(v.computed.child_count - 1) * v.layout.gap\
        : 0

    v_size_x_avail_no_gaps := v.layout.dir == .row\
        ? max(0, v_size_x_avail - v_gaps_total)\
        : v_size_x_avail

    v_size_y_avail_no_gaps := v.layout.dir == .column\
        ? max(0, v_size_y_avail - v_gaps_total)\
        : v_size_y_avail

    child_id: ID
    child_count_fill_x: int
    child_count_fill_y: int
    children_non_fill_x_width: f32
    children_non_fill_y_height: f32

    // First pass: Update size for ".ratio_*", count "fill" children stats
    child_id = v.first_child
    for child_id > 0 {
        child := &ctx.views[child_id]
        defer child_id = child.next_sibling
        if .hidden in child.flags do continue

        if .fill_x in child.flags {
            child_count_fill_x += 1
        } else {
            if .ratio_x in child.flags {
                child.computed.size.x = child.size.x * v_size_x_avail_no_gaps
            }
            children_non_fill_x_width += child.computed.size.x
        }

        if .fill_y in child.flags {
            child_count_fill_y += 1
        } else {
            if .ratio_y in child.flags {
                child.computed.size.y = child.size.y * v_size_y_avail_no_gaps
            }
            children_non_fill_y_height += child.computed.size.y
        }
    }

    // If any "fill" children found, do second pass -- update "fill" children size
    if child_count_fill_x > 0 || child_count_fill_y > 0 {
        assert(v.computed.child_count > 0)

        fill_child_width: f32
        fill_child_height: f32

        if child_count_fill_x > 0 {
            fill_child_width = v.layout.dir == .row\
                ? max(0, (v_size_x_avail_no_gaps - children_non_fill_x_width) / f32(child_count_fill_x))\
                : v_size_x_avail
        }

        if child_count_fill_y > 0 {
            fill_child_height = v.layout.dir == .column\
                ? max(0, (v_size_y_avail_no_gaps - children_non_fill_y_height) / f32(child_count_fill_y))\
                : v_size_y_avail
        }

        child_id = v.first_child
        for child_id > 0 {
            child := &ctx.views[child_id]
            if .hidden not_in child.flags {
                if .fill_x in child.flags do child.computed.size.x = fill_child_width
                if .fill_y in child.flags do child.computed.size.y = fill_child_height
            }
            child_id = child.next_sibling
        }
    }

    // TODO: update children computed.pos

    // Recurse to children last
    child_id = v.first_child
    for child_id > 0 {
        child := &ctx.views[child_id]
        if .hidden not_in child.flags && child.first_child > 0 {
            solve_children_fill_and_ratio_size(ctx, child_id)
        }
        child_id = child.next_sibling
    }
}

// - `child_count` Number of non-`.hidden` children
// - `fit_size` The size to fit those children according to `padding`, `layout.dir` and `layout.gap`
view_content_fit :: proc (ctx: ^Context, id: ID) -> (child_count: int, fit_size: [2] f32) {
    v := &ctx.views[id]

    cs_sum: [2] f32
    cs_max: [2] f32

    child_id := v.first_child
    for child_id > 0 {
        child := &ctx.views[child_id]
        if .hidden not_in child.flags {
            child_count += 1
            cs_sum += child.computed.size
            cs_max.x = max(cs_max.x, child.computed.size.x)
            cs_max.y = max(cs_max.y, child.computed.size.y)
        }
        child_id = child.next_sibling
    }

    gaps_total := child_count > 0\
        ? f32(child_count - 1) * v.layout.gap\
        : 0

    switch v.layout.dir {
    case .none:
        // Fit single largest child
        fit_size = {
            cs_max.x + v.padding[0] + v.padding[2],
            cs_max.y + v.padding[1] + v.padding[3],
        }
    case .row:
        // Fit into row: width is sum, height is max
        fit_size = {
            cs_sum.x + gaps_total + v.padding[0] + v.padding[2],
            cs_max.y + v.padding[1] + v.padding[3],
        }
    case .column:
        // Fit into column: width is max, height is sum
        fit_size = {
            cs_max.x + v.padding[0] + v.padding[2],
            cs_sum.y + gaps_total + v.padding[1] + v.padding[3],
        }
    }

    return
}
