package spacelib_ui

import "../terse"

@private
update_terse :: proc (f: ^Frame) {
    action: enum { none, offset, rebuild }
    offset: Vec2

    tolerance :: .1

    if f.terse != nil {
        tri := &f.terse.rect_input
        size_equal := abs(f.rect.w-tri.w) < tolerance && abs(f.rect.h-tri.h) < tolerance
        if size_equal {
            offset = { f.rect.x-tri.x, f.rect.y-tri.y }
            if abs(offset.x) > tolerance || abs(offset.y) > tolerance {
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
        f.terse = terse.create(f.text, f.rect, should_clone_text=false)

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
