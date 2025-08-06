package spacelib_ui

import "../terse"

@private
update_terse :: proc (f: ^Frame) {
    assert(f.ui.terse_query_font_proc != nil, "UI.terse_query_font_proc must not be nil when using terse")
    assert(f.ui.terse_query_color_proc != nil, "UI.terse_query_color_proc must not be nil when using terse")

    action: enum { none, offset, rebuild }
    offset: Vec2

    tol :: .1

    if f.terse != nil {
        tri := &f.terse.rect_input
        size_equal := abs(f.rect.w-tri.w) < tol && abs(f.rect.h-tri.h) < tol
        if size_equal {
            offset = { f.rect.x-tri.x, f.rect.y-tri.y }
            if abs(offset.x) > tol || abs(offset.y) > tol {
                action = .offset
            }
        } else {
            action = .rebuild
        }
    } else {
        action = .rebuild
    }

    switch action {
    case .none:
        return

    case .offset:
        terse.apply_offset(f.terse, offset)

    case .rebuild:
        terse.destroy(f.terse)
        f.terse = terse.create(
            f.text,
            f.rect,
            f.ui.terse_query_font_proc,
            f.ui.terse_query_color_proc,
        )

        if .terse_shrink in f.flags do terse.shrink_terse(f.terse)

        if f.flags & {.terse_size,.terse_width} != {} {
            f.size.x = f.size_min.x>0 ? max(f.size_min.x, f.terse.rect.w) : f.terse.rect.w
        }

        if f.flags & {.terse_size,.terse_height} != {} {
            f.size.y = f.size_min.y>0 ? max(f.size_min.y, f.terse.rect.h) : f.terse.rect.h
        }
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
