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

Layout_Auto_Size :: enum {
    width,
    height,
}

@private
layout_scroll :: #force_inline proc (f: ^Frame) -> ^Layout_Scroll {
    #partial switch &l in f.layout {
    case Flow: if l.scroll.step != 0 do return &l.scroll
    }
    return nil
}

@private
layout_apply_scroll :: #force_inline proc (f: ^Frame, dy: f32, is_absolute := false) -> (scrolled: bool) {
    scroll := layout_scroll(f)
    if scroll != nil {
        new_offset := is_absolute ? dy : scroll.offset - dy * scroll.step
        new_offset = clamp(new_offset, scroll.offset_min, scroll.offset_max)
        if scroll.offset != new_offset {
            scroll.offset = new_offset
            return true
        }
    }
    return false
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
        // we return "true" for secondary Grid direction (potential vertical scroll)
        switch l.dir {
        case .right_down, .left_down        : return true
        case .down_right                    : return false
        }
    }
    panic("Frame has no layout")
}

// For indexing 4-float padding arrays in Flow and Grid
@private L :: 0 // left
@private R :: 1 // right
@private T :: 2 // top
@private B :: 3 // bottom
