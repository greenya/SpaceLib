package spacelib_ui

import "../core"

Actor :: union {
    Actor_Scrollbar_Content,
    Actor_Scrollbar_Next,
    Actor_Scrollbar_Prev,
    Actor_Scrollbar_Thumb,

    Actor_Slider_Thumb,
    Actor_Slider_Next,
    Actor_Slider_Prev,
}

Actor_Scrollbar_Content :: struct { thumb, next, prev: ^Frame }
Actor_Scrollbar_Thumb   :: struct { content: ^Frame }
Actor_Scrollbar_Next    :: struct { content: ^Frame }
Actor_Scrollbar_Prev    :: struct { content: ^Frame }

Actor_Slider_Data   :: struct { idx, len: int, is_vertical: bool }
Actor_Slider_Thumb  :: struct { using data: Actor_Slider_Data, next, prev: ^Frame }
Actor_Slider_Next   :: struct { thumb: ^Frame }
Actor_Slider_Prev   :: struct { thumb: ^Frame }

// Setup frames for acting as a scrollbar.
// - `content` should be a scrollable frame; any scrollbar action triggers `wheel` of the `content`.
// - `thumb` if used, should have `.capture` and be a child of a "track" frame, with single anchor,
// its offset is used to position the `thumb`.
// - `next` and `prev` if used, will act as clickable next/prev "arrows".
// - `thumb`, `next` and `prev` will be `.disabled` if nothing to scroll.
// - use `layout_scroll()` with `content` to get scroll state.
setup_scrollbar_actors :: proc (content: ^Frame, thumb: ^Frame = nil, next: ^Frame = nil, prev: ^Frame = nil) {
    ensure(layout_scroll(content) != nil, "Content frame must have layout with scroll")
    ensure(thumb != nil || next != nil || prev != nil, "At least one actor must be used")

    if thumb != nil {
        ensure(thumb.parent != nil, "Thumb must have parent (track)")
        ensure(len(thumb.anchors) == 1, "Thumb must have exactly 1 anchor, its offset will reflect thumb position")
        ensure(.capture in thumb.flags, "Thumb must have .capture flag to allow dragging")
    }

    content.actor = Actor_Scrollbar_Content { thumb=thumb, next=next, prev=prev }
    if thumb != nil do thumb.actor = Actor_Scrollbar_Thumb { content=content }
    if next != nil do next.actor = Actor_Scrollbar_Next { content=content }
    if prev != nil do prev.actor = Actor_Scrollbar_Prev { content=content }
}

// Setup frames for acting as a slider.
// - `thumb` should have `.capture` and be a child of a "track" frame, with a single anchor,
// its offset is used to position the `thumb`; any slider action triggers `click` of the `thumb`.
// - `next` and `prev` if used, will act as clickable next/prev "arrows"; proper arrow will be
// `.disabled`, when `idx` value is `0` or `len-1`.
// - use `actor_slider_data()` with `thumb`, `next` or `prev` to get slider state.
setup_slider_actors :: proc (data: Actor_Slider_Data, thumb: ^Frame, next: ^Frame = nil, prev: ^Frame = nil) {
    ensure(data.idx >= 0 && data.len > 0)
    ensure(thumb.parent != nil, "Thumb must have parent (track)")
    ensure(len(thumb.anchors) == 1, "Thumb must have exactly 1 anchor, its offset will reflect thumb position")
    ensure(.capture in thumb.flags, "Thumb must have .capture flag to allow dragging")

    thumb.actor = Actor_Slider_Thumb { data=data, next=next, prev=prev }
    if next != nil do next.actor = Actor_Slider_Next { thumb=thumb }
    if prev != nil do next.actor = Actor_Slider_Prev { thumb=thumb }
}

actor_slider_data :: proc (f: ^Frame) -> Actor_Slider_Data {
    #partial switch a in f.actor {
    case Actor_Slider_Thumb : return a.data
    case Actor_Slider_Next  : return actor_slider_data(a.thumb)
    case Actor_Slider_Prev  : return actor_slider_data(a.thumb)
    }
    panic("Frame is not a slider actor")
}

@private
click_actor :: proc (f: ^Frame) {
    #partial switch a in f.actor {
    case Actor_Scrollbar_Next: wheel(a.content, -1)
    case Actor_Scrollbar_Prev: wheel(a.content, +1)
    }
}

@private
wheel_actor :: proc (f: ^Frame, dy := f32(0)) -> (consumed: bool) {
    #partial switch _ in f.actor {
    case Actor_Scrollbar_Content: return wheel_actor_scrollbar_content(f)
    case                        : return false
    }
}

@private
drag_actor :: proc (f: ^Frame, info: Drag_Info) {
    #partial switch a in f.actor {
    case Actor_Scrollbar_Thumb: drag_actor_scrollbar_thumb(f, info)
    }
}

@private
drag_actor_scrollbar_thumb :: proc (f: ^Frame, info: Drag_Info) {
    actor := &f.actor.(Actor_Scrollbar_Thumb)
    track_rect := &f.parent.rect
    ratio: f32

    mouse_pos := f.ui.mouse.pos

    if is_layout_dir_vertical(actor.content) {
        space := track_rect.h - f.rect.h
        ratio = core.clamp_ratio(mouse_pos.y-info.start_offset.y, track_rect.y, track_rect.y+track_rect.h-f.rect.h)
        f.anchors[0].offset.y = space * ratio
    } else {
        space := track_rect.w - f.rect.w
        ratio = core.clamp_ratio(mouse_pos.x-info.start_offset.x, track_rect.x, track_rect.x+track_rect.w-f.rect.w)
        f.anchors[0].offset.x = space * ratio
    }

    scroll := layout_scroll(actor.content)
    if scroll != nil {
        scroll.offset = scroll.offset_min + ratio*(scroll.offset_max-scroll.offset_min)
    }
}

@private
wheel_actor_scrollbar_content :: proc (f: ^Frame) -> (consumed: bool) {
    actor := &f.actor.(Actor_Scrollbar_Content)
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
