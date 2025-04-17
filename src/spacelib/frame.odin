package spacelib

import "core:slice"
import "core:strings"

// todo: maybe add support for Frame.drag: Drag_Proc (f: ^Frame, op: Drag_Operation) // enum: is_drag_target, dragging_started, dragging_now, dragging_ended, is_drop_target, dropping_now
// todo: maybe convert all bool fields to "flags: bit_set [Flags]"

Frame :: struct {
    parent      : ^Frame,
    order       : int,

    children    : [dynamic] ^Frame,
    layout      : Layout,

    rect        : Rect,
    rect_dirty  : bool,
    anchors     : [dynamic] Anchor,
    size        : Vec2,

    hidden      : bool,
    pass        : bool,
    solid       : bool,
    scissor     : bool,
    check       : bool,
    radio       : bool,
    auto_hide   : bool,
    actor       : Actor,

    text        : string,
    draw        : Frame_Proc,
    draw_after  : Frame_Proc,
    enter       : Frame_Proc,
    leave       : Frame_Proc,
    click       : Frame_Proc,
    wheel       : Frame_Wheel_Proc,
    hovered     : bool,
    prev_hovered: bool,
    captured    : bool,
    selected    : bool,
    disabled    : bool,
}

Layout :: struct {
    dir         : Layout_Dir,
    align       : Layout_Alignment,
    scroll      : Layout_Scroll,
    size        : Vec2,
    gap         : f32,
    pad         : Vec2,
    auto_size   : bool,
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

Layout_Scroll :: struct {
    step        : f32,
    offset      : f32,
    offset_min  : f32,
    offset_max  : f32,
}

Actor :: union {
    Actor_Scrollbar_Content,
    Actor_Scrollbar_Next,
    Actor_Scrollbar_Prev,
    Actor_Scrollbar_Thumb,
}

Actor_Scrollbar_Content :: struct { thumb: ^Frame }
Actor_Scrollbar_Thumb   :: struct { content: ^Frame }
Actor_Scrollbar_Next    :: struct { content: ^Frame }
Actor_Scrollbar_Prev    :: struct { content: ^Frame }

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

Frame_Proc          :: proc (f: ^Frame)
Frame_Wheel_Proc    :: proc (f: ^Frame, dy: f32) -> (consumed: bool)

add_frame :: proc (parent: ^Frame, init: Frame = {}, anchors: [] Anchor = {}) -> ^Frame {
    f := new(Frame)
    f^ = init

    assert(f.parent == nil)
    set_parent(f, parent)

    for a in anchors do add_anchor(f, a)

    return f
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
    if f.parent != nil {
        append(&f.parent.children, f)
        slice.sort_by(f.parent.children[:], less=#force_inline proc (f1, f2: ^Frame) -> bool {
            return f1.order < f2.order
        })
    }
}

setup_scrollbar_actors :: proc (content: ^Frame, thumb: ^Frame, next: ^Frame = nil, prev: ^Frame = nil) {
    assert(len(thumb.anchors) == 1)
    assert(layout_has_scroll(content))

    content.actor = Actor_Scrollbar_Content { thumb=thumb }
    thumb.actor = Actor_Scrollbar_Thumb { content=content }
    if next != nil do next.actor = Actor_Scrollbar_Next { content=content }
    if prev != nil do prev.actor = Actor_Scrollbar_Prev { content=content }
}

show_by_frame :: proc (f: ^Frame, hide_siblings := false) {
    if hide_siblings && f.parent != nil do for &child in f.parent.children do child.hidden = true
    f.hidden = false
    updated(f)
}

show_by_path :: proc (parent: ^Frame, path: string, hide_siblings := false) {
    target := get(parent, path)
    show_by_frame(target, hide_siblings)
}

show :: proc {
    show_by_frame,
    show_by_path,
}

hide_by_frame :: proc (f: ^Frame) {
    f.hidden = true
}

hide_by_path :: proc (parent: ^Frame, path: string) {
    target := get(parent, path)
    hide_by_frame(target)
}

hide :: proc {
    hide_by_frame,
    hide_by_path,
}

wheel_by_frame :: proc (f: ^Frame, dy: f32) -> (consumed: bool) {
    if hidden(f) || disabled(f) do return false
    if layout_has_scroll(f) && layout_apply_scroll(f, dy) do consumed = true
    if f.actor != nil && wheel_actor(f, dy) do consumed = true
    if f.wheel != nil && f.wheel(f, dy) do consumed = true
    if f.solid do consumed = true
    return
}

wheel_by_path :: proc (parent: ^Frame, path: string, dy: f32) -> (consumed: bool) {
    target := get(parent, path)
    return wheel_by_frame(target, dy)
}

wheel :: proc {
    wheel_by_frame,
    wheel_by_path,
}

click_by_frame :: proc (f: ^Frame) {
    if disabled(f) do return
    if f.check do f.selected = !f.selected
    if f.radio do click_radio(f)
    if f.actor != nil do click_actor(f)
    if f.click != nil do f.click(f)
}

click_by_path :: proc (parent: ^Frame, path: string) {
    target := get(parent, path)
    click_by_frame(target)
}

click :: proc {
    click_by_frame,
    click_by_path,
}

hidden :: proc (f: ^Frame) -> bool {
    for i:=f; i!=nil; i=i.parent do if i.hidden do return true
    return false
}

disabled :: proc (f: ^Frame) -> bool {
    for i:=f; i!=nil; i=i.parent do if i.disabled do return true
    return false
}

find_by_text :: proc (parent: ^Frame, text: string) -> ^Frame {
    for child in parent.children {
        if child.text == text do return child
        found_child := find_by_text(child, text)
        if found_child != nil do return found_child
    }
    return nil
}

find :: proc (parent: ^Frame, path: string) -> ^Frame {
    found_child := parent
    for text in strings.split(path, "/", context.temp_allocator) {
        found_child = find_by_text(found_child, text)
        if found_child == nil do return nil
    }
    assert(found_child != parent) // this is expected as strings.split() never returns empty slice, but lets keep the assert
    return found_child
}

get :: proc (parent: ^Frame, path: string) -> ^Frame {
    target := find(parent, path)
    ensure(target != nil, "Path not found, use find() in case its expected")
    return target
}

layout_has_scroll :: #force_inline proc (f: ^Frame) -> bool {
    return f.layout.dir != .none && f.layout.scroll.step != 0
}

@(private)
layout_apply_scroll :: proc (f: ^Frame, dy: f32) -> (consumed: bool) {
    scroll := &f.layout.scroll
    new_offset := clamp(scroll.offset - dy * scroll.step, scroll.offset_min, scroll.offset_max)
    if scroll.offset != new_offset {
        scroll.offset = new_offset
        return true
    } else {
        return false
    }
}

@(private)
wheel_actor :: proc (f: ^Frame, dy: f32) -> (consumed: bool) {
    #partial switch _ in f.actor {
    case Actor_Scrollbar_Content: return wheel_actor_scrollbar_content(f, dy)
    case                        : return false
    }
}

@(private)
wheel_actor_scrollbar_content :: proc (f: ^Frame, dy: f32) -> (consumed: bool) {
    actor := &f.actor.(Actor_Scrollbar_Content)
    thumb := actor.thumb
    scroll := &f.layout.scroll
    scroll_ratio := clamp_ratio(scroll.offset, scroll.offset_min, scroll.offset_max)

    if is_layout_dir_vertical(f) {
        thumb_space := thumb.parent.rect.h - thumb.rect.h
        thumb_offset := thumb_space * scroll_ratio
        if thumb.anchors[0].offset.y != thumb_offset {
            thumb.anchors[0].offset.y = thumb_offset
            consumed = true
        }
    } else {
        thumb_space := thumb.parent.rect.w - thumb.rect.w
        thumb_offset := thumb_space * scroll_ratio
        if thumb.anchors[0].offset.x != thumb_offset {
            thumb.anchors[0].offset.x = thumb_offset
            consumed = true
        }
    }

    return
}

@(private)
click_radio :: proc (f: ^Frame) {
    if f.parent != nil do for &child in f.parent.children do if child.radio do child.selected = false
    f.selected = true
}

@(private)
click_actor :: proc (f: ^Frame) {
    #partial switch a in f.actor {
    case Actor_Scrollbar_Next: wheel(a.content, -1)
    case Actor_Scrollbar_Prev: wheel(a.content, +1)
    }
}

@(private)
drag :: proc (f: ^Frame, mouse_pos, captured_pos: Vec2) {
    if f.actor != nil do drag_actor(f, mouse_pos, captured_pos)
}

@(private)
drag_actor :: proc (f: ^Frame, mouse_pos, captured_pos: Vec2) {
    #partial switch a in f.actor {
    case Actor_Scrollbar_Thumb: drag_actor_scrollbar_thumb(f, mouse_pos, captured_pos)
    }
}

@(private)
drag_actor_scrollbar_thumb :: proc (f: ^Frame, mouse_pos, captured_pos: Vec2) {
    actor := &f.actor.(Actor_Scrollbar_Thumb)

    if is_layout_dir_vertical(actor.content) {
        space := f.parent.rect.h - f.rect.h
        ratio := clamp_ratio(mouse_pos.y-captured_pos.y, f.parent.rect.y, f.parent.rect.y + f.parent.rect.h - f.rect.h)
        f.anchors[0].offset.y = space * ratio
        scroll := &actor.content.layout.scroll
        scroll.offset = scroll.offset_min + ratio*(scroll.offset_max-scroll.offset_min)
    } else {
        space := f.parent.rect.w - f.rect.w
        ratio := clamp_ratio(mouse_pos.x-captured_pos.x, f.parent.rect.x, f.parent.rect.x + f.parent.rect.w - f.rect.w)
        f.anchors[0].offset.x = space * ratio
        scroll := &actor.content.layout.scroll
        scroll.offset = scroll.offset_min + ratio*(scroll.offset_max-scroll.offset_min)
    }
}

@(private)
destroy_frame_tree :: proc (f: ^Frame) {
    for child in f.children do destroy_frame_tree(child)
    delete(f.children)
    delete(f.anchors)
    free(f)
}

@(private)
update_frame_tree :: proc (f: ^Frame, m: ^Manager) {
    f.prev_hovered = f.hovered
    f.hovered = false
    f.captured = false

    if f.hidden do return

    update_rect(f)

    m_pos := m.mouse.pos
    if pos_in_rect(m_pos, f.rect) && pos_in_rect(m_pos, m.scissor_rect) do append(&m.mouse_frames, f)

    if f.auto_hide do append(&m.auto_hide_frames, f)

    if f.scissor do push_scissor_rect(m, f.rect)
    for child in f.children do update_frame_tree(child, m)
    if f.scissor do pop_scissor_rect(m)
}

@(private)
draw_frame_tree :: proc (f: ^Frame, m: ^Manager) {
    if f.hidden do return
    if f.draw != nil do f.draw(f)
    if m.overdraw_proc != nil do m.overdraw_proc(f)
    if f.scissor do push_scissor_rect(m, f.rect)
    for child in f.children do draw_frame_tree(child, m)
    if f.scissor do pop_scissor_rect(m)
    if f.draw_after != nil do f.draw_after(f)
    m.stats.frames_drawn += 1
}

@(private)
mark_frame_tree_rect_dirty :: proc (f: ^Frame, m: ^Manager) {
    f.rect_dirty = true
    for child in f.children do mark_frame_tree_rect_dirty(child, m)
    m.stats.frames_total += 1
}

@(private)
update_rect :: proc (f: ^Frame) {
    if f.rect_dirty do if len(f.anchors) > 0 do update_rect_with_anchors(f)
    if f.layout.dir != .none do update_rect_for_children_with_layout(f)
}

@(private)
update_rect_for_children_with_layout :: proc (f: ^Frame) {
    prev_rect: Rect
    has_prev_rect: bool

    for child in f.children {
        if child.hidden do continue

        rect := Rect {}
        rect.w = child.size.x != 0 ? child.size.x : f.layout.size.x != 0 ? f.layout.size.x : f.rect.w-2*f.layout.pad.x
        rect.h = child.size.y != 0 ? child.size.y : f.layout.size.y != 0 ? f.layout.size.y : f.rect.h-2*f.layout.pad.y

        #partial switch f.layout.dir {
        case .left:
            rect.x = has_prev_rect ? prev_rect.x-rect.w-f.layout.gap : f.rect.x+f.rect.w-rect.w-f.layout.pad.x
            rect.y = f.rect.y + f.layout.pad.y
        case .left_and_right, .right:
            rect.x = has_prev_rect ? prev_rect.x+prev_rect.w+f.layout.gap : f.rect.x+f.layout.pad.x
            rect.y = f.rect.y + f.layout.pad.y
        case .up:
            rect.x = f.rect.x + f.layout.pad.x
            rect.y = has_prev_rect ? prev_rect.y-rect.h-f.layout.gap : f.rect.y+f.rect.h-rect.h-f.layout.pad.y
        case .up_and_down, .down:
            rect.x = f.rect.x + f.layout.pad.x
            rect.y = has_prev_rect ? prev_rect.y+prev_rect.h+f.layout.gap : f.rect.y+f.layout.pad.y
        }

        prev_rect = rect
        has_prev_rect = true

        #partial switch f.layout.dir {
        case .left, .left_and_right, .right:
            switch f.layout.align {
            case .start : // already aligned
            case .center: rect.y += (f.rect.h-rect.h)/2   - f.layout.pad.y
            case .end   : rect.h +=  f.rect.h-rect.h    - 2*f.layout.pad.y
            }
        case .up, .up_and_down, .down:
            switch f.layout.align {
            case .start : // already aligned
            case .center: rect.x += (f.rect.w-rect.w)/2   - f.layout.pad.x
            case .end   : rect.x +=  f.rect.w-rect.w    - 2*f.layout.pad.x
            }
        }

        child.rect = rect
        child.rect_dirty = false
    }

    if len(f.children) > 0 {
        first_child := f.children[0]
        last_child := slice.last(f.children[:])

        #partial switch f.layout.dir {
        case .left_and_right:
            first_child_x1 := first_child.rect.x
            last_child_x2 := last_child.rect.x + last_child.rect.w
            children_center_x := (first_child_x1 + last_child_x2) / 2
            frame_center_x := f.rect.x + f.rect.w/2
            dx := frame_center_x - children_center_x
            for &child in f.children do child.rect.x += dx
        case .up_and_down:
            first_child_y1 := first_child.rect.y
            last_child_y2 := last_child.rect.y + last_child.rect.h
            children_center_y := (first_child_y1 + last_child_y2) / 2
            frame_center_y := f.rect.y + f.rect.h/2
            dy := frame_center_y - children_center_y
            for &child in f.children do child.rect.y += dy
        }

        content_size, dir_rect_size := get_layout_content_size(f)
        is_dir_vertical := is_layout_dir_vertical(f)

        if f.layout.auto_size {
            if is_dir_vertical  do f.size.y = content_size[1]
            else                do f.size.x = content_size[1]
        } else if layout_has_scroll(f) {
            scroll := &f.layout.scroll

            scroll.offset_min = min(0, content_size[0])
            scroll.offset_max = max(0, content_size[1] - dir_rect_size)
            scroll.offset = clamp(scroll.offset, scroll.offset_min, scroll.offset_max)

            if is_dir_vertical  do for &child in f.children do child.rect.y -= scroll.offset
            else                do for &child in f.children do child.rect.x -= scroll.offset
        }
    }
}

@(private)
get_layout_content_size :: proc (f: ^Frame) -> (content_size: Vec2, dir_rect_size: f32) {
    is_dir_vertical := is_layout_dir_vertical(f)
    dir_rect_size = is_dir_vertical ? f.rect.h : f.rect.w

    if len(f.children) > 0 {
        first_child := f.children[0]
        last_child := slice.last(f.children[:])

        if is_layout_dir_vertical(f) {
            min_y1: f32
            max_y2: f32

            #partial switch f.layout.dir {
            case .up: // children grow up
                min_y1 = last_child.rect.y
                max_y2 = first_child.rect.y + first_child.rect.h
            case .down, .up_and_down: // children grow down
                min_y1 = first_child.rect.y
                max_y2 = last_child.rect.y + last_child.rect.h
            }

            content_size[0] = min_y1 - f.rect.y - f.layout.pad.y
            content_size[1] = max_y2 - f.rect.y + f.layout.pad.y
        } else {
            min_x1: f32
            max_x2: f32

            #partial switch f.layout.dir {
            case .left: // children grow left
                min_x1 = last_child.rect.x
                max_x2 = first_child.rect.x + first_child.rect.w
            case .right, .left_and_right: // children grow right
                min_x1 = first_child.rect.x
                max_x2 = last_child.rect.x + last_child.rect.w
            }

            content_size[0] = min_x1 - f.rect.x - f.layout.pad.x
            content_size[1] = max_x2 - f.rect.x + f.layout.pad.x
        }
    }

    return
}

@(private)
is_layout_dir_vertical :: #force_inline proc (f: ^Frame) -> bool {
    return f.layout.dir == .down || f.layout.dir == .up || f.layout.dir == .up_and_down
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
