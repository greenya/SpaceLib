package spacelib_ui

import "../core"
import "../terse"

@private
update_terse :: proc (f: ^Frame) {
    should_rebuild :=
        f.terse == nil ||
        (f.terse != nil && !core.rect_equal_approx(f.terse.rect_input, f.rect, e=.5)) ||
        (f.terse != nil && !core.rect_equal_approx(f.terse.scissor, f.ui.scissor_rect, e=.5))

    if !should_rebuild do return

    assert(f.ui.terse_query_font_proc != nil, "UI.terse_query_font_proc must not be nil when using terse")
    assert(f.ui.terse_query_color_proc != nil, "UI.terse_query_color_proc must not be nil when using terse")

    scroll_offset_delta: Vec2

    if f.terse != nil {
        rect_size_changed :=
            abs(f.rect.w-f.terse.rect_input.w) > .1 ||
            abs(f.rect.h-f.terse.rect_input.h) > .1
        if !rect_size_changed {
            scroll_offset_delta = { f.rect.x-f.terse.rect_input.x, f.rect.y-f.terse.rect_input.y }
        }
    }

    if !core.vec_zero_approx(scroll_offset_delta, e=.5) {
        terse.apply_offset(f.terse, scroll_offset_delta)
    } else {
        terse.destroy(f.terse)
        f.terse = terse.create(
            f.text,
            f.rect,
            f.ui.terse_query_font_proc,
            f.ui.terse_query_color_proc,
            f.ui.scissor_rect,
            f.opacity,
        )
        if .terse_shrink in f.flags do terse.shrink_terse(f.terse)
    }

    if f.flags & {.terse_size,.terse_width} != {} {
        f.size.x = f.size_min.x>0 ? max(f.size_min.x, f.terse.rect.w) : f.terse.rect.w
    }

    if f.flags & {.terse_size,.terse_height} != {} {
        f.size.y = f.size_min.y>0 ? max(f.size_min.y, f.terse.rect.h) : f.terse.rect.h
    }
}

@private
destroy_terse_in_frame_tree :: proc (f: ^Frame) {
    for child in f.children do destroy_terse_in_frame_tree(child)
    if f.terse != nil {
        terse.destroy(f.terse)
        f.terse = nil
    }
}
