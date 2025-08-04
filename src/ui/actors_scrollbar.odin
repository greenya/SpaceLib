package spacelib_ui

import "../core"

Actor_Scrollbar_Content :: struct { thumb, next, prev: ^Frame }
Actor_Scrollbar_Thumb   :: struct { content: ^Frame }
Actor_Scrollbar_Next    :: struct { content: ^Frame }
Actor_Scrollbar_Prev    :: struct { content: ^Frame }

// Setup frames for acting as a scrollbar.
// - `content` should be a scrollable frame; use `content.wheel` to track scroll value changes.
// - `thumb` if used, should have `.capture` and be a child of a "track" frame, with single anchor,
// its offset is used to position the `thumb`.
// - `next` and `prev` if used, will act as clickable next/prev "arrows".
// - `thumb`, `next` and `prev` will be `.disabled` if nothing to scroll.
// - `layout_scroll(content)` can be used to query scroll state.
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
