package hi

import "core:slice"
import "../core"

// Bottom-up solver for `.fit_*` and fixed sizes.
//
// The given view and its children get:
// - `solved.size` only if `fit_*` or fixed size
// - `solved.child_count`
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
//
// Also adds visible children to the `ctx.visible_views`.
_solve_children_fill_and_ratio_size :: proc (v: ^View) {
    v_size_x_avail := max(0, v.solved.size.x - (v.padding[0] + v.padding[2]))
    v_size_y_avail := max(0, v.solved.size.y - (v.padding[1] + v.padding[3]))

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
            if .ratio_x in c.flags do c.solved.size.x = c.size.x * v.solved.size.x
            if .ratio_y in c.flags do c.solved.size.y = c.size.y * v.solved.size.y
        } else {
            if .fill_x in c.flags {
                fill_x_child_count += 1
            } else {
                if .ratio_x in c.flags {
                    c.solved.size.x = c.size.x * v_size_x_avail_no_gaps
                }
                non_fill_x_children_width += c.solved.size.x
            }

            if .fill_y in c.flags {
                fill_y_child_count += 1
            } else {
                if .ratio_y in c.flags {
                    c.solved.size.y = c.size.y * v_size_y_avail_no_gaps
                }
                non_fill_y_children_height += c.solved.size.y
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
            if .fill_x in c.flags do c.solved.size.x = fill_child_width
            if .fill_y in c.flags do c.solved.size.y = fill_child_height
        }
    }

    // Recurse to children last with position calculation
    if v.first_child != nil {
        layout_cursor := v.solved.pos + { v.padding[0], v.padding[1] } + v.scroll

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

            append(&v.ctx.visible_views, Visible_View { view=c })

            if v.strata != c.strata {
                // Non-native strata child skips layout cursor and uses fixed positioning without parent padding
                c.solved.pos = _place_pos(
                    place       = c.place,
                    size        = c.solved.size,
                    rel_pos     = v.solved.pos,
                    rel_size    = v.solved.size,
                )
            } else do switch v.layout.dir {
            case .none:
                c.solved.pos = _place_pos(
                    place       = c.place,
                    size        = c.solved.size,
                    rel_pos     = layout_cursor,
                    rel_size    = {v_size_x_avail, v_size_y_avail},
                )
            case .row:
                c.solved.pos = layout_cursor
                // Offset child by Y axis, e.g. cross-axis alignment (layout.align)
                if v.layout.align != .start {
                    d := v_size_y_avail - c.solved.size.y
                    if v.layout.align == .center do d /= 2
                    c.solved.pos.y += d
                }
                layout_cursor.x += c.solved.size.x + v.layout.gap
            case .column:
                c.solved.pos = layout_cursor
                // Offset child by X axis, e.g. cross-axis alignment (layout.align)
                if v.layout.align != .start {
                    d := v_size_x_avail - c.solved.size.x
                    if v.layout.align == .center do d /= 2
                    c.solved.pos.x += d
                }
                layout_cursor.y += c.solved.size.y + v.layout.gap
            }

            if c.first_child != nil {
                _solve_children_fill_and_ratio_size(c)
            }
        }
    }
}

// Updates `ctx.visible_views`:
// - sorts according to priority: `strata` > `level` > `uid`
// - solves scissor rects
_solve_visible_view_scissors :: proc (ctx: ^Context) {
    slice.sort_by(ctx.visible_views[:], less=proc (w1, w2: Visible_View) -> bool {
        switch {
        case w1.view.strata != w2.view.strata   : return w1.view.strata < w2.view.strata
        case w1.view.level  != w2.view.level    : return w1.view.level  < w2.view.level
        case                                    : return w1.view.uid    < w2.view.uid
        }
    })

    s: struct { rect: Rect, strata: Strata } = { strata=Strata(-999) }
    for &w in ctx.visible_views {
        if s.strata != w.view.strata {
            s.rect = { expand_values(ctx.root.solved.pos), expand_values(ctx.root.solved.size) }
            s.strata = w.view.strata
        }

        if .scissor in w.view.flags {
            v_rect := Rect { expand_values(w.view.solved.pos), expand_values(w.view.solved.size) }
            s.rect = core.rect_intersection(s.rect, v_rect)
        }

        // FIX: track actual parent scissor rect, not flat rolling one (like now)
        //      maybe add View.solved.scissor to simplify things

        // maybe refactor solved.pos+size into solved.rect

        // maybe add .in_scissor flag, update for all ctx.visible_views, basically cache result of core.rects_intersect() and use it in mouse hit test and drawing (skip event->draw if not-.in_scissor)

        w.scissor = s.rect
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
        fit_sum += c.solved.size
        fit_max.x = max(fit_max.x, c.solved.size.x)
        fit_max.y = max(fit_max.y, c.solved.size.y)
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

_place_pos :: proc (place: Place, size, rel_pos, rel_size: Vec2) -> Vec2 {
    anchor_point := rel_pos + (rel_size * place.anchor)
    pivot_offset := size * place.pivot
    return anchor_point - pivot_offset + place.offset
}
