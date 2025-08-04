package spacelib_ui

import "../core"

Actor_Slider_Data :: struct {
    // Current slider value: `0`..`total-1`.
    idx: int,
    // Total number of values.
    total: int,
    // Direction:
    // - `false` -- horizontally from left to right: `0 >>> total-1`
    // - `true` -- vertically from bottom to top: `0 ^^^ total-1`
    is_vertical: bool,
}

Actor_Slider_Thumb  :: struct { using data: Actor_Slider_Data, next, prev: ^Frame }
Actor_Slider_Next   :: struct { thumb: ^Frame }
Actor_Slider_Prev   :: struct { thumb: ^Frame }

// Setup frames for acting as a slider.
// - `thumb` should have `.capture` and be a child of a "track" frame, with a single anchor,
// its offset is used to position the `thumb`; use `thumb.click` to track slider value changes.
// - `next` and `prev` if used, will act as clickable next/prev "arrows"; proper arrow will be
// `.disabled`, when `idx` value is `0` or `total-1`.
// - `actor_slider(thumb/next/prev)` can be used to get slider state.
setup_slider_actors :: proc (data: Actor_Slider_Data, thumb: ^Frame, next: ^Frame = nil, prev: ^Frame = nil) {
    ensure(data.idx >= 0 && data.total > 0)
    ensure(thumb.parent != nil, "Thumb must have parent (track)")
    ensure(len(thumb.anchors) == 1, "Thumb must have exactly 1 anchor, its offset will reflect thumb position")
    ensure(.capture in thumb.flags, "Thumb must have .capture flag to allow dragging")

    thumb.actor = Actor_Slider_Thumb { data=data, next=next, prev=prev }
    if next != nil do next.actor = Actor_Slider_Next { thumb=thumb }
    if prev != nil do prev.actor = Actor_Slider_Prev { thumb=thumb }

    update(thumb.parent)
    set_actor_slider_idx(thumb, data.idx)
}

actor_slider :: proc (f: ^Frame) -> (thumb: ^Frame, data: ^Actor_Slider_Data) {
    #partial switch &a in f.actor {
    case Actor_Slider_Thumb : return f, &a.data
    case Actor_Slider_Next  : return actor_slider(a.thumb)
    case Actor_Slider_Prev  : return actor_slider(a.thumb)
    }
    panic("Frame is not a slider actor")
}

set_actor_slider_idx :: proc (f: ^Frame, new_idx: int) {
    thumb, data := actor_slider(f)
    actor := &thumb.actor.(Actor_Slider_Thumb)

    data.idx = clamp(new_idx, 0, data.total-1)
    idx_ratio := f32(data.idx) / f32(data.total-1)

    if data.is_vertical {
        track_space := thumb.parent.rect.h
        thumb.anchors[0].offset.y = track_space * (1-idx_ratio)
    } else {
        track_space := thumb.parent.rect.w
        thumb.anchors[0].offset.x = track_space * idx_ratio
    }

    if actor.prev != nil {
        if data.idx == 0    do actor.prev.flags += {.disabled}
        else                do actor.prev.flags -= {.disabled}
    }

    if actor.next != nil {
        if data.idx == data.total-1 do actor.next.flags += {.disabled}
        else                        do actor.next.flags -= {.disabled}
    }

    click(thumb)
}

@private
drag_actor_slider_thumb :: proc (f: ^Frame, info: Drag_Info) {
    actor := &f.actor.(Actor_Slider_Thumb)
    data := &actor.data
    track_rect := &f.parent.rect
    idx_ratio: f32

    mouse_pos := f.ui.mouse.pos
    if data.is_vertical {
        track_space := track_rect.h
        point_space := track_space / f32(data.total-1)
        idx_ratio = 1 - core.clamp_ratio(mouse_pos.y-point_space/2, track_rect.y, track_rect.y+track_space)
    } else {
        track_space := track_rect.w
        point_space := track_space / f32(data.total-1)
        idx_ratio = core.clamp_ratio(mouse_pos.x+point_space/2, track_rect.x, track_rect.x+track_space)
    }

    idx := int(idx_ratio * f32(data.total-1))
    set_actor_slider_idx(f, idx)
}
