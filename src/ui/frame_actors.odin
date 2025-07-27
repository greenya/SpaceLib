package spacelib_ui

import "../core"

Actor :: union {
    Actor_Scrollbar_Content,
    Actor_Scrollbar_Next,
    Actor_Scrollbar_Prev,
    Actor_Scrollbar_Thumb,
}

Actor_Scrollbar_Content :: struct { thumb, next, prev: ^Frame }
Actor_Scrollbar_Thumb   :: struct { content: ^Frame }
Actor_Scrollbar_Next    :: struct { content: ^Frame }
Actor_Scrollbar_Prev    :: struct { content: ^Frame }

setup_scrollbar_actors :: proc (content: ^Frame, thumb: ^Frame = nil, next: ^Frame = nil, prev: ^Frame = nil) {
    ensure(layout_scroll(content) != nil, "Content frame must have layout with scroll")
    ensure(thumb != nil || next != nil || prev != nil, "At least one actor must be used")

    if thumb != nil {
        ensure(thumb.parent != nil, "Thumb must have parent (track)")
        ensure(len(thumb.anchors) == 1, "Thumb must have exactly 1 anchor, its offset will reflect thumb position")
        ensure(.capture in thumb.flags, "Thumb must have .capture flag to allow dragging")
    }

    content._actor = Actor_Scrollbar_Content { thumb=thumb, next=next, prev=prev }
    if thumb != nil do thumb._actor = Actor_Scrollbar_Thumb { content=content }
    if next != nil do next._actor = Actor_Scrollbar_Next { content=content }
    if prev != nil do prev._actor = Actor_Scrollbar_Prev { content=content }
}

@private
click_actor :: proc (f: ^Frame) {
    #partial switch a in f._actor {
    case Actor_Scrollbar_Next: wheel(a.content, -1)
    case Actor_Scrollbar_Prev: wheel(a.content, +1)
    }
}

@private
drag_actor :: proc (f: ^Frame, mouse_pos, captured_pos: Vec2) {
    #partial switch a in f._actor {
    case Actor_Scrollbar_Thumb: drag_actor_scrollbar_thumb(f, mouse_pos, captured_pos)
    }
}

@private
drag_actor_scrollbar_thumb :: proc (f: ^Frame, mouse_pos, captured_pos: Vec2) {
    actor := &f._actor.(Actor_Scrollbar_Thumb)
    track_rect := &f.parent.rect
    ratio: f32

    if is_layout_dir_vertical(actor.content) {
        space := track_rect.h - f.rect.h
        ratio = core.clamp_ratio(mouse_pos.y-captured_pos.y, track_rect.y, track_rect.y+track_rect.h-f.rect.h)
        f.anchors[0].offset.y = space * ratio
    } else {
        space := track_rect.w - f.rect.w
        ratio = core.clamp_ratio(mouse_pos.x-captured_pos.x, track_rect.x, track_rect.x+track_rect.w-f.rect.w)
        f.anchors[0].offset.x = space * ratio
    }

    scroll := layout_scroll(actor.content)
    if scroll != nil {
        scroll.offset = scroll.offset_min + ratio*(scroll.offset_max-scroll.offset_min)
    }
}

@private
wheel_actor :: proc (f: ^Frame, dy := f32(0)) -> (consumed: bool) {
    #partial switch _ in f._actor {
    case Actor_Scrollbar_Content: return wheel_actor_scrollbar_content(f)
    case                        : return false
    }
}

@private
wheel_actor_scrollbar_content :: proc (f: ^Frame) -> (consumed: bool) {
    actor := &f._actor.(Actor_Scrollbar_Content)
    thumb := actor.thumb
    next := actor.next
    prev := actor.prev

    scroll := layout_scroll(f)
    if scroll == nil do return

    if thumb != nil {
        scroll_ratio := core.clamp_ratio(scroll.offset, scroll.offset_min, scroll.offset_max)
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
    }

    if scroll.offset_min == scroll.offset_max {
        if thumb != nil do thumb.flags += { .disabled }
        if next != nil do next.flags += { .disabled }
        if prev != nil do prev.flags += { .disabled }
    } else {
        if thumb != nil do thumb.flags -= { .disabled }
        if next != nil do next.flags -= { .disabled }
        if prev != nil do prev.flags -= { .disabled }
    }

    return
}
