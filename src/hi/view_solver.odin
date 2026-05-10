#+private
package hi

ROOT_VIEW_ID :: 0

// Bottom-up solver for `.fit_*` and fixed sizes.
//
// The given view and its children get:
// - `solved.size` only if `fit_*` or fixed size
// - `solved.child_count`
//
// Note: The root view `flags`, `size`, `padding` and `layout` are ignored.
solve_view_fit_and_fixed_size :: proc(v: ^View) {
    // Recurse to children first
    for child := v.first_child; child != nil; child = child.next_sibling {
        if .hidden not_in child.flags do solve_view_fit_and_fixed_size(child)
    }

    child_count, fit_size := view_content_fit(v)
    v.solved.child_count = child_count

    if v.id == ROOT_VIEW_ID {
        return
    }

    if .fit_x in v.flags {
        v.solved.size.x = fit_size.x
    } else if v.flags & { .ratio_x, .fill_x } != {} {
        // Skip parent-dependent width for next solver
    } else {
        v.solved.size.x = v.size.x
    }

    if .fit_y in v.flags {
        v.solved.size.y = fit_size.y
    } else if v.flags & { .ratio_y, .fill_y } != {} {
        // Skip parent-dependent height for next solver
    } else {
        v.solved.size.y = v.size.y
    }
}

// Top-down solver for `.fill_*` and `ratio_*` sizes.
//
// The children of the given view get:
// - `solved.size` only if `fill_*` or `ratio_*` size
// - `solved.pos`
solve_children_fill_and_ratio_size :: proc (v: ^View) {
    v_size_x_avail := max(0, v.solved.size.x - (v.padding[0] + v.padding[2]))
    v_size_y_avail := max(0, v.solved.size.y - (v.padding[1] + v.padding[3]))

    v_gaps_total := v.solved.child_count > 0\
        ? f32(v.solved.child_count - 1) * v.layout.gap\
        : 0

    v_size_x_avail_no_gaps := v.layout.dir == .row\
        ? max(0, v_size_x_avail - v_gaps_total)\
        : v_size_x_avail

    v_size_y_avail_no_gaps := v.layout.dir == .column\
        ? max(0, v_size_y_avail - v_gaps_total)\
        : v_size_y_avail

    child_count_fill_x: int
    child_count_fill_y: int
    children_non_fill_x_width: f32
    children_non_fill_y_height: f32

    // First pass: Update size for ".ratio_*", count "fill" children stats
    for child := v.first_child; child != nil; child = child.next_sibling {
        if .hidden in child.flags do continue

        if .fill_x in child.flags {
            child_count_fill_x += 1
        } else {
            if .ratio_x in child.flags {
                child.solved.size.x = child.size.x * v_size_x_avail_no_gaps
            }
            children_non_fill_x_width += child.solved.size.x
        }

        if .fill_y in child.flags {
            child_count_fill_y += 1
        } else {
            if .ratio_y in child.flags {
                child.solved.size.y = child.size.y * v_size_y_avail_no_gaps
            }
            children_non_fill_y_height += child.solved.size.y
        }
    }

    // If any "fill" children found, do second pass -- update "fill" children size
    if child_count_fill_x > 0 || child_count_fill_y > 0 {
        assert(v.solved.child_count > 0)

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

        for child := v.first_child; child != nil; child = child.next_sibling {
            if .hidden not_in child.flags {
                if .fill_x in child.flags do child.solved.size.x = fill_child_width
                if .fill_y in child.flags do child.solved.size.y = fill_child_height
            }
        }
    }

    // Recurse to children last with position calculation
    if v.first_child != nil {
        cursor := v.solved.pos + { v.padding[0], v.padding[1] } + v.scroll

        // Offset cursor according to main axis alignment (layout.justify)
        if v.layout.justify != .start {
            if v.layout.dir == .row && child_count_fill_x == 0 {
                d := v_size_x_avail_no_gaps - children_non_fill_x_width
                if v.layout.justify == .center do d /= 2
                cursor.x += d
            } else if v.layout.dir == .column && child_count_fill_y == 0 {
                d := v_size_y_avail_no_gaps - children_non_fill_y_height
                if v.layout.justify == .center do d /= 2
                cursor.y += d
            }
        }

        for child := v.first_child; child != nil; child = child.next_sibling {
            if .hidden in child.flags do continue

            switch v.layout.dir {
            case .none:
                child.solved.pos = placement_pos(
                    placement   = child.placement,
                    size        = child.solved.size,
                    rel_pos     = cursor,
                    rel_size    = {v_size_x_avail, v_size_y_avail},
                )
            case .row:
                child.solved.pos = cursor
                // Offset child by Y axis, e.g. cross-axis alignment (layout.align)
                if v.layout.align != .start {
                    d := v_size_y_avail - child.solved.size.y
                    if v.layout.align == .center do d /= 2
                    child.solved.pos.y += d
                }
                cursor.x += child.solved.size.x + v.layout.gap
            case .column:
                child.solved.pos = cursor
                // Offset child by X axis, e.g. cross-axis alignment (layout.align)
                if v.layout.align != .start {
                    d := v_size_x_avail - child.solved.size.x
                    if v.layout.align == .center do d /= 2
                    child.solved.pos.x += d
                }
                cursor.y += child.solved.size.y + v.layout.gap
            }

            if child.first_child != nil {
                solve_children_fill_and_ratio_size(child)
            }
        }
    }
}

// - `child_count` Number of non-`.hidden` children
// - `fit_size` The size to fit those children according to `padding`, `layout.dir` and `layout.gap`
view_content_fit :: proc (v: ^View) -> (child_count: int, fit_size: [2] f32) {
    cs_sum: [2] f32
    cs_max: [2] f32

    for child := v.first_child; child != nil; child = child.next_sibling {
        if .hidden not_in child.flags {
            child_count += 1
            cs_sum += child.solved.size
            cs_max.x = max(cs_max.x, child.solved.size.x)
            cs_max.y = max(cs_max.y, child.solved.size.y)
        }
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

placement_pos :: proc (placement: Placement, size, rel_pos, rel_size: [2] f32) -> [2] f32 {
    anchor_point := rel_pos + (rel_size * placement.anchor)
    pivot_offset := size * placement.pivot
    return anchor_point - pivot_offset + placement.offset
}
