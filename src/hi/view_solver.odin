package hi

import "../core"

// Bottom-up solver for `.fit_*` and fixed sizes.
//
// The given view and its children get:
// - `solved.rect.w/h` only if `fit_*` or fixed size
// - `solved.layout_child_count`
//
// Note: The root view `flags`, `size`, `padding` and `layout` are ignored.
_solve_view_fit_and_fixed_size :: proc(v: ^View) {
    // Recurse to children first
    for c := v.first_child; c != nil; c = c.next_sibling {
        if .hidden not_in c.flags do _solve_view_fit_and_fixed_size(c)
    }

    fit_size: Vec2
    v.solved.layout_child_count, fit_size = _view_layout_content_fit(v)

    if v.idx == 0 {
        return
    }

    if .fit_x in v.flags {
        v.solved.rect.w = fit_size.x
    } else if v.flags & { .ratio_x, .fill_x } != {} {
        // Skip parent-dependent width for next solver
    } else {
        v.solved.rect.w = v.size.x
    }

    if .fit_y in v.flags {
        v.solved.rect.h = fit_size.y
    } else if v.flags & { .ratio_y, .fill_y } != {} {
        // Skip parent-dependent height for next solver
    } else {
        v.solved.rect.h = v.size.y
    }
}

// Top-down solver for `.fill_*` and `ratio_*` sizes.
//
// The children of the given view get:
// - `solved.rect.w/h` only if `fill_*` or `ratio_*` size
// - `solved.rect.x/y`
// - `solved.parent_scissor`
//
// Also appends child to `Context.active_views` in case it intersects `solved.parent_scissor`.
_solve_children_fill_and_ratio_size :: proc (v: ^View) {
    v_size_x_avail := max(0, v.solved.rect.w - (v.padding[0] + v.padding[2]))
    v_size_y_avail := max(0, v.solved.rect.h - (v.padding[1] + v.padding[3]))

    v_gaps_total := v.solved.layout_child_count > 0\
        ? f32(v.solved.layout_child_count - 1) * v.layout.gap\
        : 0

    v_size_x_avail_no_gaps := v.layout.dir == .row\
        ? max(0, v_size_x_avail - v_gaps_total)\
        : v_size_x_avail

    v_size_y_avail_no_gaps := v.layout.dir == .column\
        ? max(0, v_size_y_avail - v_gaps_total)\
        : v_size_y_avail

    fill_x_child_count: int
    fill_y_child_count: int
    non_fill_x_children_width: f32
    non_fill_y_children_height: f32

    // First pass: Update size for ".ratio_*", count "fill" children stats
    for c := v.first_child; c != nil; c = c.next_sibling {
        if .hidden in c.flags do continue

        if v.strata != c.strata {
            if .ratio_x in c.flags do c.solved.rect.w = c.size.x * v.solved.rect.w
            if .ratio_y in c.flags do c.solved.rect.h = c.size.y * v.solved.rect.h
        } else {
            if .fill_x in c.flags {
                fill_x_child_count += 1
            } else {
                if .ratio_x in c.flags {
                    c.solved.rect.w = c.size.x * v_size_x_avail_no_gaps
                }
                non_fill_x_children_width += c.solved.rect.w
            }

            if .fill_y in c.flags {
                fill_y_child_count += 1
            } else {
                if .ratio_y in c.flags {
                    c.solved.rect.h = c.size.y * v_size_y_avail_no_gaps
                }
                non_fill_y_children_height += c.solved.rect.h
            }
        }
    }

    // If any "fill" children found, do second pass -- update "fill" children size
    if fill_x_child_count > 0 || fill_y_child_count > 0 {
        assert(v.solved.layout_child_count > 0)

        fill_child_width: f32
        fill_child_height: f32

        if fill_x_child_count > 0 {
            fill_child_width = v.layout.dir == .row\
                ? max(0, (v_size_x_avail_no_gaps - non_fill_x_children_width) / f32(fill_x_child_count))\
                : v_size_x_avail
        }

        if fill_y_child_count > 0 {
            fill_child_height = v.layout.dir == .column\
                ? max(0, (v_size_y_avail_no_gaps - non_fill_y_children_height) / f32(fill_y_child_count))\
                : v_size_y_avail
        }

        for c := v.first_child; c != nil; c = c.next_sibling {
            if .hidden in c.flags do continue
            if .fill_x in c.flags do c.solved.rect.w = fill_child_width
            if .fill_y in c.flags do c.solved.rect.h = fill_child_height
        }
    }

    // Recurse to children last with position calculation
    if v.first_child != nil {
        layout_cursor := Vec2 {
            v.solved.rect.x + v.padding[0] + v.scroll.x,
            v.solved.rect.y + v.padding[1] + v.scroll.y,
        }

        // Offset cursor according to main axis alignment (layout.justify)
        if v.layout.justify != .start {
            if v.layout.dir == .row && fill_x_child_count == 0 {
                d := v_size_x_avail_no_gaps - non_fill_x_children_width
                if v.layout.justify == .center do d /= 2
                layout_cursor.x += d
            } else if v.layout.dir == .column && fill_y_child_count == 0 {
                d := v_size_y_avail_no_gaps - non_fill_y_children_height
                if v.layout.justify == .center do d /= 2
                layout_cursor.y += d
            }
        }

        for c := v.first_child; c != nil; c = c.next_sibling {
            if .hidden in c.flags do continue

            if v.strata == c.strata do switch v.layout.dir {
            case .none:
                rel_rect := Rect { layout_cursor.x, layout_cursor.y, v_size_x_avail, v_size_y_avail }
                _place_rect_pos(&c.solved.rect, c.place, { c.solved.rect.w, c.solved.rect.h }, rel_rect)

            case .row:
                c.solved.rect.x = layout_cursor.x
                c.solved.rect.y = layout_cursor.y
                // Offset child by Y axis, e.g. cross-axis alignment (layout.align)
                if v.layout.align != .start {
                    d := v_size_y_avail - c.solved.rect.h
                    if v.layout.align == .center do d /= 2
                    c.solved.rect.y += d
                }
                layout_cursor.x += c.solved.rect.w + v.layout.gap

            case .column:
                c.solved.rect.x = layout_cursor.x
                c.solved.rect.y = layout_cursor.y
                // Offset child by X axis, e.g. cross-axis alignment (layout.align)
                if v.layout.align != .start {
                    d := v_size_x_avail - c.solved.rect.w
                    if v.layout.align == .center do d /= 2
                    c.solved.rect.x += d
                }
                layout_cursor.y += c.solved.rect.h + v.layout.gap
            } else {
                // Non-native strata child skips layout cursor and uses fixed positioning without parent padding
                _place_rect_pos(&c.solved.rect, c.place, { c.solved.rect.w, c.solved.rect.h }, v.solved.rect)
            }

            // Scissor calculation and in-scissor check

            in_scissor := true
            c.solved.parent_scissor = {}

            if v.strata == c.strata {
                if .scissor in v.flags {
                    v_content_rect := content_rect(v)
                    c.solved.parent_scissor = v.solved.parent_scissor != {}\
                        ? core.rect_intersection(v.solved.parent_scissor, v_content_rect)\
                        : v_content_rect
                } else {
                    c.solved.parent_scissor = v.solved.parent_scissor
                }
                if c.solved.parent_scissor != {} {
                    in_scissor = core.rects_intersect(c.solved.parent_scissor, c.solved.rect)
                }
            }

            if in_scissor {
                append(&v.ctx.active_views, c)
                if c.first_child != nil {
                    _solve_children_fill_and_ratio_size(c)
                }
            }
        }
    }
}

// - `child_count` Number of non-`.hidden` and native strata children
// - `fit_size` The size to fit those children according to `padding`, `layout.dir` and `layout.gap`
_view_layout_content_fit :: proc (v: ^View) -> (child_count: i32, fit_size: Vec2) {
    fit_sum: Vec2
    fit_max: Vec2

    for c := v.first_child; c != nil; c = c.next_sibling {
        if .hidden in c.flags || v.strata != c.strata do continue
        child_count += 1
        fit_sum.x += c.solved.rect.w
        fit_sum.y += c.solved.rect.h
        fit_max.x = max(fit_max.x, c.solved.rect.w)
        fit_max.y = max(fit_max.y, c.solved.rect.h)
    }

    gaps_total := child_count > 0\
        ? f32(child_count - 1) * v.layout.gap\
        : 0

    switch v.layout.dir {
    case .none:
        // Fit single largest child
        fit_size = {
            fit_max.x + v.padding[0] + v.padding[2],
            fit_max.y + v.padding[1] + v.padding[3],
        }
    case .row:
        // Fit into row: width is sum, height is max
        fit_size = {
            fit_sum.x + gaps_total + v.padding[0] + v.padding[2],
            fit_max.y + v.padding[1] + v.padding[3],
        }
    case .column:
        // Fit into column: width is max, height is sum
        fit_size = {
            fit_max.x + v.padding[0] + v.padding[2],
            fit_sum.y + gaps_total + v.padding[1] + v.padding[3],
        }
    }

    return
}

_place_rect_pos :: proc (result_rect: ^Rect, place: Place, size: Vec2, rel_rect: Rect) {
    anchor_point_x := rel_rect.x + rel_rect.w * place.anchor.x
    anchor_point_y := rel_rect.y + rel_rect.h * place.anchor.y
    pivot_offset := size * place.pivot
    result_rect.x = anchor_point_x - pivot_offset.x + place.offset.x
    result_rect.y = anchor_point_y - pivot_offset.y + place.offset.y
}
