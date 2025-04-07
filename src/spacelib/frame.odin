package spacelib

import "core:slice"

// todo: maybe add support for Frame.drag: Drag_Proc (f: ^Frame, op: Drag_Operation) // enum: is_drag_target, dragging_started, dragging_now, dragging_ended, is_drop_target, dropping_now
// todo: maybe convert all bool fields to "flags: bit_set [Flags]""

Frame :: struct {
    parent      : ^Frame,

    children    : [dynamic] ^Frame,
    layout      : Layout,

    rect        : Rect,
    rect_dirty  : bool,
    anchors     : [dynamic] Anchor,
    size        : Vec2,

    hidden      : bool,
    pass        : bool,
    auto_hide   : bool,
    check       : bool,
    radio       : bool,
    scissor     : bool,

    text        : string,
    draw        : Frame_Proc,
    enter       : Frame_Proc,
    leave       : Frame_Proc,
    click       : Frame_Proc,
    hovered     : bool,
    prev_hovered: bool,
    pressed     : bool,
    selected    : bool,
}

Layout :: struct {
    dir     : Layout_Dir,
    align   : Layout_Alignment,
    size    : Vec2,
    gap     : f32,
    pad     : f32,
}

Layout_Dir :: enum {
    none,
    left,
    left_and_right,
    right,
    up,
    up_and_down,
    down,
}

Layout_Alignment :: enum {
    start,
    center,
    end,
}

Anchor :: struct {
    point       : Anchor_Point,
    rel_point   : Anchor_Point,
    rel_frame   : ^Frame,
    offset      : Vec2,
}

Anchor_Point :: enum {
    none,
    top_left,
    top,
    top_right,
    left,
    center,
    right,
    bottom_left,
    bottom,
    bottom_right,
}

Frame_Proc :: proc (f: ^Frame)

add_frame :: proc (parent: ^Frame, init: Frame = {}, anchors: [] Anchor = {}) -> ^Frame {
    f := new(Frame)
    f^ = init
    f.parent = parent
    if parent != nil do append(&parent.children, f)
    for a in anchors do add_anchor(f, a)
    return f
}

@(private)
destroy_frame_tree :: proc (f: ^Frame) {
    for child in f.children do destroy_frame_tree(child)
    delete(f.children)
    delete(f.anchors)
    free(f)
}

updated :: proc (f: ^Frame) {
    if f.hidden do return
    update_rect(f)
    for child in f.children do updated(child)
}

add_anchor :: proc (f: ^Frame, init: Anchor) {
    init := init
    if init.point == .none do init.point = .top_left
    if init.rel_point == .none do init.rel_point = init.point
    append(&f.anchors, init)
}

clear_anchors :: proc (f: ^Frame) {
    resize(&f.anchors, 0)
}

set_parent :: proc (f: ^Frame, new_parent: ^Frame) {
    if f.parent != nil {
        idx, _ := slice.linear_search(f.parent.children[:], f)
        assert(idx >= 0)
        ordered_remove(&f.parent.children, idx)
    }

    f.parent = new_parent
    if f.parent != nil do append(&f.parent.children, f)
}

show :: proc (f: ^Frame) {
    f.hidden = false
    updated(f)
}

hide :: proc (f: ^Frame) {
    f.hidden = true
}

click :: proc (f: ^Frame) {
    if f.check do f.selected = !f.selected
    if f.radio {
        if f.parent != nil do for &child in f.parent.children do if child.radio do child.selected = false
        f.selected = true
    }
    if f.click != nil do f.click(f)
}

find :: proc (f: ^Frame, text: string, recursive := false) -> ^Frame {
    for child in f.children {
        if child.text == text do return child
        if recursive {
            found_child := find(child, text, true)
            if found_child != nil do return found_child
        }
    }
    return nil
}

@(private)
update_frame_tree :: proc (f: ^Frame, m: ^Manager) {
    f.prev_hovered = f.hovered
    f.hovered = false
    f.pressed = false

    if f.hidden do return

    update_rect(f)

    pos := &m.mouse.pos
    is_mouse_in_rect := f.rect.x < pos.x && f.rect.x+f.rect.w > pos.x && f.rect.y < pos.y && f.rect.y+f.rect.h > pos.y
    if is_mouse_in_rect do append(&m.mouse_frames, f)

    if f.auto_hide do append(&m.auto_hide_frames, f)

    for child in f.children do update_frame_tree(child, m)
}

@(private)
draw_frame_tree :: proc (f: ^Frame, m: ^Manager) {
    if f.hidden do return
    if f.scissor && m.scissor_start_proc != nil do m.scissor_start_proc(f)
    if f.draw != nil do f.draw(f)
    if m.frame_post_draw_proc != nil do m.frame_post_draw_proc(f)
    for child in f.children do draw_frame_tree(child, m)
    if f.scissor && m.scissor_end_proc != nil do m.scissor_end_proc(f)
}

@(private)
mark_frame_tree_rect_dirty :: proc (f: ^Frame) {
    f.rect_dirty = true
    for child in f.children do mark_frame_tree_rect_dirty(child)
}

@(private)
update_rect :: proc (f: ^Frame) {
    if !f.rect_dirty do return
    if len(f.anchors) > 0 do update_rect_with_anchors(f)
    if f.layout.dir != .none do update_rect_for_children_with_layout(f)
}

@(private)
update_rect_for_children_with_layout :: proc (f: ^Frame) {
    prev_rect: Rect
    has_prev_rect: bool

    for child in f.children {
        if child.hidden do continue

        rect := Rect { 0, 0, child.size.x, child.size.y }
        if rect.w == 0 do rect.w = f.layout.size.x
        if rect.w == 0 do rect.w = f.rect.w
        if rect.h == 0 do rect.h = f.layout.size.y
        if rect.h == 0 do rect.h = f.rect.h

        #partial switch f.layout.dir {
        case .left:
            rect.x = has_prev_rect ? prev_rect.x - rect.w - f.layout.gap : f.rect.x - rect.w - f.layout.pad
            rect.y = f.rect.y
        case .left_and_right, .right:
            rect.x = has_prev_rect ? prev_rect.x + prev_rect.w + f.layout.gap : f.rect.x + f.layout.pad
            rect.y = f.rect.y
        case .up:
            rect.x = f.rect.x
            rect.y = has_prev_rect ? prev_rect.y - rect.h - f.layout.gap : f.rect.y - rect.h - f.layout.pad
        case .up_and_down, .down:
            rect.x = f.rect.x
            rect.y = has_prev_rect ? prev_rect.y + prev_rect.h + f.layout.gap : f.rect.y + f.layout.pad
        }

        prev_rect = rect
        has_prev_rect = true

        #partial switch f.layout.dir {
        case .left, .left_and_right, .right:
            switch f.layout.align {
            case .start : // already aligned
            case .center: rect.y += (f.rect.h-rect.h)/2
            case .end   : rect.h += (f.rect.h-rect.h)
            }
        case .up, .up_and_down, .down:
            switch f.layout.align {
            case .start : // already aligned
            case .center: rect.x += (f.rect.w-rect.w)/2
            case .end   : rect.x += (f.rect.w-rect.w)
            }
        }

        child.rect = rect
        child.rect_dirty = false
    }

    if len(f.children) > 0 do #no_bounds_check #partial switch f.layout.dir {
    case .left_and_right:
        first_child_x1 := f.children[0].rect.x
        last_child := slice.last(f.children[:])
        last_child_x2 := last_child.rect.x + last_child.rect.w
        children_center_x := (first_child_x1 + last_child_x2) / 2
        frame_center_x := f.rect.x + f.rect.w/2
        dx := frame_center_x - children_center_x
        for &child in f.children do child.rect.x += dx
    case .up_and_down:
        first_child_y1 := f.children[0].rect.y
        last_child := slice.last(f.children[:])
        last_child_y2 := last_child.rect.y + last_child.rect.h
        children_center_y := (first_child_y1 + last_child_y2) / 2
        frame_center_y := f.rect.y + f.rect.h/2
        dy := frame_center_y - children_center_y
        for &child in f.children do child.rect.y += dy
    }
}

@(private)
update_rect_with_anchors :: proc (f: ^Frame) {
    result_dir := Rect_Dir { r=f.size.x, b=f.size.y }
    result_pin: Rect_Pin

    for anchor in f.anchors {
        assert(anchor.point != .none)
        assert(anchor.rel_point != .none)

        rel_frame := anchor.rel_frame != nil ? anchor.rel_frame : f.parent
        update_rect(rel_frame)

        rel := rel_frame.rect
        dir := result_dir
        dir_w, dir_h := dir.r-dir.l, dir.b-dir.t
        pin_anchors: Rect_Pin

        #partial switch anchor.point {
        case .top_left:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.t=rel.y;
            case .top           : dir.l=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.r = dir.l + dir_w
            dir.b = dir.t + dir_h
            pin_anchors.t = true
            pin_anchors.l = true

        case .top:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.t=rel.y;
            case .top           : dir.l=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.l -= dir_w/2
            dir.r = dir.l + dir_w
            dir.b = dir.t + dir_h
            pin_anchors.t = true

        case .top_right:
            #partial switch anchor.rel_point {
            case .top_left      : dir.r=rel.x; dir.t=rel.y;
            case .top           : dir.r=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.r=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.r=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.r=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.r=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.r=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.r=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.r=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.l = dir.r - dir_w
            dir.b = dir.t + dir_h
            pin_anchors.t = true
            pin_anchors.r = true

        case .left:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.t=rel.y;
            case .top           : dir.l=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.r = dir.l + dir_w
            dir.t -= dir_h/2
            dir.b = dir.t + dir_h
            pin_anchors.l = true

        case .center:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.t=rel.y;
            case .top           : dir.l=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.l -= dir_w/2
            dir.r = dir.l + dir_w
            dir.t -= dir_h/2
            dir.b = dir.t + dir_h

        case .right:
            #partial switch anchor.rel_point {
            case .top_left      : dir.r=rel.x; dir.t=rel.y;
            case .top           : dir.r=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.r=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.r=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.r=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.r=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.r=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.r=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.r=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.l = dir.r - dir_w
            dir.t -= dir_h/2
            dir.b = dir.t + dir_h
            pin_anchors.r = true

        case .bottom_left:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.b=rel.y;
            case .top           : dir.l=rel.x+rel.w/2; dir.b=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.b=rel.y
            case .left          : dir.l=rel.x; dir.b=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.b=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.b=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.b=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.b=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.b=rel.y+rel.h
            }
            dir.r = dir.l + dir_w
            dir.t = dir.b - dir_h
            pin_anchors.b = true
            pin_anchors.l = true

        case .bottom:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.b=rel.y;
            case .top           : dir.l=rel.x+rel.w/2; dir.b=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.b=rel.y
            case .left          : dir.l=rel.x; dir.b=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.b=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.b=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.b=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.b=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.b=rel.y+rel.h
            }
            dir.l -= dir_w/2
            dir.r = dir.l + dir_w
            dir.t = dir.b - dir_h
            pin_anchors.b = true

        case .bottom_right:
            #partial switch anchor.rel_point {
            case .top_left      : dir.r=rel.x; dir.b=rel.y;
            case .top           : dir.r=rel.x+rel.w/2; dir.b=rel.y
            case .top_right     : dir.r=rel.x+rel.w; dir.b=rel.y
            case .left          : dir.r=rel.x; dir.b=rel.y+rel.h/2
            case .center        : dir.r=rel.x+rel.w/2; dir.b=rel.y+rel.h/2
            case .right         : dir.r=rel.x+rel.w; dir.b=rel.y+rel.h/2
            case .bottom_left   : dir.r=rel.x; dir.b=rel.y+rel.h
            case .bottom        : dir.r=rel.x+rel.w/2; dir.b=rel.y+rel.h
            case .bottom_right  : dir.r=rel.x+rel.w; dir.b=rel.y+rel.h
            }
            dir.l = dir.r - dir_w
            dir.t = dir.b - dir_h
            pin_anchors.b = true
            pin_anchors.r = true
        }

        dir.l += anchor.offset.x
        dir.r += anchor.offset.x
        dir.t += anchor.offset.y
        dir.b += anchor.offset.y
        transform_rect_dir(&result_dir, &result_pin, dir, pin_anchors)
    }

    f.rect = { result_dir.l, result_dir.t, result_dir.r - result_dir.l, result_dir.b - result_dir.t }
    f.rect_dirty = false
}

@(private) Rect_Dir :: struct { l, t, r, b: f32 }
@(private) Rect_Pin :: struct { l, t, r, b: bool }

@(private)
transform_rect_dir :: proc (dir: ^Rect_Dir, pin: ^Rect_Pin, dir_next: Rect_Dir, pin_anchors: Rect_Pin) {
    if !pin.l do dir.l = dir_next.l
    if !pin.t do dir.t = dir_next.t
    if !pin.r do dir.r = dir_next.r
    if !pin.b do dir.b = dir_next.b

    if pin_anchors.l do pin.l = true
    if pin_anchors.t do pin.t = true
    if pin_anchors.r do pin.r = true
    if pin_anchors.b do pin.b = true
}
