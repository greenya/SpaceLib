package spacelib_ui

Layout_Scroll :: struct {
    // Multiplier for mouse wheel delta.
    step: f32,
    // Current scroll offset (in pixels).
    // This can be equal to `offset_min` or `offset_max`, meaning the scroll is at its limit.
    // Scrolling is also considered "inactive" when `offset_min == offset_max`.
    offset: f32,
    // Minimum scroll offset (in pixels).
    // In most common layout directions this is `0`, but it can be negative in some cases,
    // for example, when `Flow.dir == .left`.
    offset_min: f32,
    // Maximum scroll offset (in pixels).
    // In most common layout directions this is `>0`, but it can be `0` while scroll is active,
    // for example, when `Flow.dir == .left`.
    offset_max: f32,
}

@private
layout_visible_children :: proc (f: ^Frame, allocator := context.allocator) -> [] ^Frame {
    assert(f.layout != nil)
    list := make([dynamic] ^Frame, allocator)
    for child in f.children {
        if len(child.anchors) == 0 && .hidden not_in child.flags {
            append(&list, child)
        }
    }
    return list[:]
}

@private
is_layout_dir_vertical :: #force_inline proc (f: ^Frame) -> bool {
    switch l in f.layout {
    case Flow:
        switch l.dir {
        case .up, .down, .down_center       : return true
        case .left, .right, .right_center   : return false
        }
    case Grid:
        switch l.dir {
        case .right_down, .left_down: return true
        }
    }
    panic("Frame has no layout")
}

// for indexing Flow.pad and Grid.pad arrays
@private L :: 0
@private R :: 1
@private T :: 2
@private B :: 3
