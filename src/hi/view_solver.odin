#+private
package hi

solve_view_tree :: proc (ctx: ^Context) {
    solve_sizes_for_fit_and_fixed(ctx, 0)
    solve_sizes_for_fill_and_ratio(ctx, 0)
    // solve_positions(ctx, 0)
}

// Bottom-up solver for `.fit_*` and fixed sizes
solve_sizes_for_fit_and_fixed :: proc(ctx: ^Context, id: ID) {
    v := &ctx.views[id]

    // Recurse to children first
    child_id := v.first_child
    for child_id > 0 {
        child := &ctx.views[child_id]
        if .hidden not_in child.flags do solve_sizes_for_fit_and_fixed(ctx, child_id)
        child_id = child.next_sibling
    }

    if id == 0 {
        // Root always takes whole ref size, ignoring `size` and `flags`
        // ? Maybe we should support .ratio_* flags, e.g. size={0.5,1} flags={.ratio_x,ratio_y} to allow only left part of the screen?
        // ? Maybe calc actual root child_count (needed if root can have layout with gaps and such)
        // ? Currently, these both cases can be solved with an extra child, e.g. do not use root as View with full support
        v.computed = {
            pos = 0,
            size = ctx.ref_size,
            child_count = 0,
        }
        return
    }

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

// Top-down solver for `.fill_*` and `ratio_*` sizes
// TODO: maybe this pass should also solve positions (so no extra pass)
solve_sizes_for_fill_and_ratio :: proc (ctx: ^Context, id: ID) {
    v := &ctx.views[id]

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

    // Recurse to children last
    child_id = v.first_child
    for child_id > 0 {
        child := &ctx.views[child_id]
        if .hidden not_in child.flags do solve_sizes_for_fill_and_ratio(ctx, child_id)
        child_id = child.next_sibling
    }
}

// - `child_count` Number of non-`.hidden` children
// - `fit_size` The size to fit those children according to `dir`, `pad` and `gap` of the layout
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
