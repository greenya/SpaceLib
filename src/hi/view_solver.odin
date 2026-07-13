package hi

import "../core"

// Bottom-up solver for `.fit_*` and fixed sizes.
//
// The given view and its children get:
// - `solved_rect.w/h` only if `fit_*` or fixed size
// - `solved_layout_child_count`
//
// Note: The root view `flags`, `size`, `padding` and `layout` are ignored.
_solve_view_fit_and_fixed_size :: proc (v: ^View) {
    _reset_view_parent_dependent_size_for_fit_phase(v)

    // Recurse to children first
    for c := v.first_child; c != nil; c = c.next_sibling {
        if .hidden not_in c.flags do _solve_view_fit_and_fixed_size(c)
    }

    fit_size: Vec2
    v.solved_layout_child_count, fit_size = _view_layout_content_fit(v)

    if v.idx == 0 {
        return
    }

    if .text_fit_x not_in v.flags && .intext_full not_in v.flags {
        if .fit_x in v.flags {
            v.solved_rect.w = fit_size.x
        } else if v.flags & { .ratio_x, .fill_x } != {} {
            // Skip parent-dependent width for next solver
        } else {
            v.solved_rect.w = v.size.x
        }
    }

    if .text not_in v.flags {
        if .fit_y in v.flags {
            v.solved_rect.h = fit_size.y
        } else if v.flags & { .ratio_y, .fill_y } != {} {
            // Skip parent-dependent height for next solver
        } else {
            v.solved_rect.h = v.size.y
        }
    }
}

// Top-down solver for `.fill_*` and `ratio_*` sizes.
//
// The children of the given view get:
// - `solved_rect.w/h` only if `fill_*` or `ratio_*` size
// - `solved_rect.x/y`
// - `solved_scissor`
//
// Also appends child to `Context.visible_views` in case it intersects `solved_scissor`.
_solve_children_fill_and_ratio_size :: proc (v: ^View, v_solved_scissor: Rect) {
    v_size_x_avail := max(0, v.solved_rect.w - (v.padding[0] + v.padding[2]))
    v_size_y_avail := max(0, v.solved_rect.h - (v.padding[1] + v.padding[3]))

    v_gaps_total := v.solved_layout_child_count > 0\
        ? f32(v.solved_layout_child_count - 1) * v.layout.gap\
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

    // First pass: update ratio sizes and count layout fill stats.
    for c := v.first_child; c != nil; c = c.next_sibling {
        if .hidden in c.flags do continue

        if _is_layout_child(c) {
            if .text_fit_x in c.flags {
                non_fill_x_children_width += c.solved_rect.w
            } else if .fill_x in c.flags {
                fill_x_child_count += 1
            } else {
                if .ratio_x in c.flags {
                    c.solved_rect.w = c.size.x * v_size_x_avail_no_gaps
                }
                non_fill_x_children_width += c.solved_rect.w
            }

            if .text in c.flags {
                non_fill_y_children_height += c.solved_rect.h
            } else if .fill_y in c.flags {
                fill_y_child_count += 1
            } else {
                if .ratio_y in c.flags {
                    c.solved_rect.h = c.size.y * v_size_y_avail_no_gaps
                }
                non_fill_y_children_height += c.solved_rect.h
            }
        } else {
            if .text_fit_x not_in c.flags && .intext_full not_in c.flags {
                if .ratio_x in c.flags do c.solved_rect.w = c.size.x * v.solved_rect.w
            }
            if .text not_in c.flags {
                if .ratio_y in c.flags do c.solved_rect.h = c.size.y * v.solved_rect.h
            }
        }
    }

    // If any "fill" children found, do second pass -- update "fill" children size
    if fill_x_child_count > 0 || fill_y_child_count > 0 {
        assert(v.solved_layout_child_count > 0)

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
            if .hidden in c.flags || !_is_layout_child(c) do continue
            if .text_fit_x not_in c.flags {
                if .fill_x in c.flags do c.solved_rect.w = fill_child_width
            }
            if .text not_in c.flags {
                if .fill_y in c.flags do c.solved_rect.h = fill_child_height
            }
        }
    }

    // Recurse to children last with position calculation
    if v.first_child != nil {
        layout_cursor := Vec2 {
            v.solved_rect.x + v.padding[0] + v.scroll.x,
            v.solved_rect.y + v.padding[1] + v.scroll.y,
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
            if .intext in c.flags do c.flags -= { ._intext_bound }

            switch {
            case _is_layout_child(c):
                switch v.layout.dir {
                case .none:
                    rel_rect := Rect { layout_cursor.x, layout_cursor.y, v_size_x_avail, v_size_y_avail }
                    _place_rect_pos(&c.solved_rect, c.place, { c.solved_rect.w, c.solved_rect.h }, rel_rect)

                case .row:
                    c.solved_rect.x = layout_cursor.x
                    c.solved_rect.y = layout_cursor.y
                    // Offset child by Y axis, e.g. cross-axis alignment (layout.align)
                    if v.layout.align != .start {
                        d := v_size_y_avail - c.solved_rect.h
                        if v.layout.align == .center do d /= 2
                        c.solved_rect.y += d
                    }
                    layout_cursor.x += c.solved_rect.w + v.layout.gap

                case .column:
                    c.solved_rect.x = layout_cursor.x
                    c.solved_rect.y = layout_cursor.y
                    // Offset child by X axis, e.g. cross-axis alignment (layout.align)
                    if v.layout.align != .start {
                        d := v_size_x_avail - c.solved_rect.w
                        if v.layout.align == .center do d /= 2
                        c.solved_rect.x += d
                    }
                    layout_cursor.y += c.solved_rect.h + v.layout.gap
                }
            case .intext in c.flags:
                // Text token owns c.solved_rect.x/y
            case:
                // Absolute and non-native strata children skip layout cursor, padding, and scroll
                _place_rect_pos(&c.solved_rect, c.place, { c.solved_rect.w, c.solved_rect.h }, v.solved_rect)
            }

            // Scissor calculation and in-scissor check

            in_scissor := true
            c_solved_scissor: Rect

            if v.strata == c.strata {
                if .scissor in v.flags {
                    v_scissor_rect := .absolute in c.flags ? v.solved_rect : viewport_rect(v)
                    c_solved_scissor = v_solved_scissor != {}\
                        ? core.rect_intersection(v_solved_scissor, v_scissor_rect)\
                        : v_scissor_rect

                    // An enabled scissor with no area clips the entire child subtree.
                    // We do not let its empty rect reach Visible_View, where `{}` means the scissor is disabled.
                    in_scissor = c_solved_scissor.w > 0 && c_solved_scissor.h > 0
                } else {
                    c_solved_scissor = v_solved_scissor
                }
                if in_scissor && c_solved_scissor != {} && .intext not_in c.flags {
                    in_scissor = core.rects_intersect(c_solved_scissor, c.solved_rect)
                }
            }

            if in_scissor {
                append(&v.ctx.visible_views, Visible_View { c, c_solved_scissor, nil })
                if c.first_child != nil {
                    _solve_children_fill_and_ratio_size(c, c_solved_scissor)
                }
            }
        }
    }
}

_reset_view_parent_dependent_size_for_fit_phase :: proc (v: ^View) {
    if v.idx == 0 do return

    if v.flags & { .fit_x, .text_fit_x, .intext_full } == {} && v.flags & { .ratio_x, .fill_x } != {} {
        v.solved_rect.w = 0
    }

    if v.flags & { .fit_y, .text } == {} && v.flags & { .ratio_y, .fill_y } != {} {
        v.solved_rect.h = 0
    }
}

// - `child_count` Number of visible layout children
// - `fit_size` The size to fit those children according to `padding`, `layout.dir` and `layout.gap`
@require_results
_view_layout_content_fit :: proc (v: ^View) -> (child_count: i32, fit_size: Vec2) {
    fit_sum: Vec2
    fit_max: Vec2

    for c := v.first_child; c != nil; c = c.next_sibling {
        if .hidden in c.flags || !_is_layout_child(c) do continue
        child_count += 1
        fit_sum.x += c.solved_rect.w
        fit_sum.y += c.solved_rect.h
        fit_max.x = max(fit_max.x, c.solved_rect.w)
        fit_max.y = max(fit_max.y, c.solved_rect.h)
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

@require_results
_is_layout_child :: proc (child: ^View) -> bool {
    assert(child.parent != nil)
    return .absolute not_in child.flags\
        && .intext not_in child.flags\
        && child.strata == child.parent.strata
}

_place_rect_pos :: proc (result_rect: ^Rect, place: Place, size: Vec2, rel_rect: Rect) {
    anchor_point_x := rel_rect.x + rel_rect.w * place.anchor.x
    anchor_point_y := rel_rect.y + rel_rect.h * place.anchor.y
    pivot_offset := size * place.pivot
    result_rect.x = anchor_point_x - pivot_offset.x + place.offset.x
    result_rect.y = anchor_point_y - pivot_offset.y + place.offset.y
}
