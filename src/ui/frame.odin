package spacelib_ui

import "core:fmt"
import "core:slice"
import "core:strings"
import "../core"
import "../terse"

Frame_Init :: struct {
    // Set of flags. See description of each flag for details.
    flags: bit_set [Flag],

    // Absolute rectangle of the frame.
    // In most cases, this is updated automatically by the UI based on `anchors` or `parent.layout`.
    // You should set it manually only if the frame is not anchored and not a child of a layout.
    // For example, the root frame typically sets this directly to match the screen resolution.
    rect: Rect,

    // Size.
    // Width and height are processed separately.
    // For example, size={200,0} will effectively set width, and leave height open for calculations
    // by `anchors` and `parent.layout`.
    size: Vec2,

    // Size aspect ratio.
    // Considered "not set" if it is zero.
    // The value is applied only when one dimension is known and another is zero (not set nor calculated).
    // The value used only by `Flow` and `anchors`.
    size_aspect: f32,

    // Size ratio.
    // Sub-values (width and height) are processed separately.
    // Sub-value is considered "not set" if it is zero.
    // The value is used only by `Flow`.
    size_ratio: Vec2,

    // Minimal size.
    // Sub-values (width and height) are processed separately.
    // Sub-value is considered "not set" if it is zero.
    // The value is applied after all size calculations has been made.
    // The value is used only by `Flow` and `terse`.
    size_min: Vec2,

    // Layout method for `children`.
    // Affects only children without `anchors`.
    layout: union { Flow, Grid },

    // Relative order of this frame to other siblings.
    // This value effects order of this frame in the `parent.children` array. It is not an index,
    // but a priority. Use `index()` to get the zero-based index. The higher `order`, the later
    // frame drawn and input tested (its above any lower-order sibling frame).
    //
    // Note: adding all frames with the same `order` (say 0) will keep the order same the order
    // they were added. But when adding a frame with say order `-1` will ensure the new frame will
    // be first, but the order of all children with same value (said 0) is effectively undefined.
    // This is due to sorting done to children list after each add.
    //
    // So general rule: if some frames needs order, you probably want all frames to have `order`
    // set (and different) for consistent sort result.
    order: int,

    // Name. Not unique.
    // Use `set_name()` to set new value. The value will be cloned (allocated).
    name: string,

    // Text.
    // This value might differ from what you've set in case `text_format` is used.
    // Use `set_text()` to set new value. The value will be cloned (allocated).
    text: string,

    // Text format for the `text`.
    // If set, the `text` will be formatted like `fmt.aprintf(f.text_format, ...values)`.
    // Use `set_text_format()` to set new value. The value will be cloned (allocated).
    text_format: string,

    // Tick callback.
    // The callback can expect the `rect` of the frame and each of its children has been calculated.
    // Called before any event callbacks (e.g. `enter`, `click`, etc.)
    // Called on every `tick()` when frame is not `.hidden`.
    tick: Frame_Proc,

    // Draw callback.
    // Called before setting own scissor (if used) and before drawing children.
    // Called on every `draw()` when frame is not `.hidden`.
    draw: Frame_Proc,

    // Post draw callback.
    // Called after drawing children and after restoring previous scissor (if used).
    // Called on every `draw()` when frame is not `.hidden`.
    draw_after: Frame_Proc,

    // Triggered when the frame gets shown.
    // Only for direct frame, e.g. child frames will not be called.
    show: Frame_Proc,

    // Triggered when the frame gets hidden.
    // Only for direct frame, e.g. child frames will not be called.
    hide: Frame_Proc,

    // Mouse status callback. Triggered when the mouse has entered the `rect` of the frame or
    // any of its children. The callback can expect `entered == true`, and `entered_time` set.
    enter: Frame_Proc,

    // Mouse status callback. Triggered when the mouse has left the `rect` of the frame or
    // any of its children. The callback can expect `entered == false`, and `left_time` set.
    leave: Frame_Proc,

    // Mouse action callback. Triggered when the mouse button is clicked over the `rect`.
    // By default, the callback is called on button press. If the `.capture` flag is set,
    // the callback is instead triggered on button release.
    click: Frame_Proc,

    // Mouse action callback. Triggered when the mouse wheel is scrolled over the `rect`.
    // The event propagates to deeper frames until it is consumed (i.e., a callback returns `true`).
    wheel: Frame_Wheel_Proc,

    // Mouse action callback. Triggered while the mouse is being dragged.
    // Called on every `tick()` for the frame that has `captured` the mouse.
    //
    // The callback is guaranteed to be called at least twice, with a proper `info.phase`:
    // `.start` at the beginning and `.end` at the end of the drag operation.
    drag: Frame_Drag_Proc,

    // Indicates that the frame is selected.
    // Use with `.check` flag if you want UI to toggle it on `click`.
    // Use with `.radio` flag if you want UI to set it to `true` on `click` for this frame while
    // set it to `false` for all siblings with `.radio` flag.
    selected: bool,
}

Frame :: struct {
    // Init part of the `Frame` struct.
    using init: Frame_Init,

    // The UI this frame is part of.
    // Can be `nil` in case the frame is manually detached via `set_parent(f, nil)`.
    // Note: detached frames will not be destroyed on `destroy()`.
    ui: ^UI,

    // Parent frame.
    // This value is `nil` for root and for manually detached frames.
    parent: ^Frame,

    // Child frames. Sorted according to `child.order`.
    children: [dynamic] ^Frame,

    // Anchors.
    // Anchors calculation is using `size` and `size_aspect` to decide on final `rect`.
    // Note: `parent.layout` skips anchored frames.
    anchors: [dynamic] Anchor,

    // Terse (measured text).
    //
    // Created from `text` using `terse.create()`. The UI might regenerate the value when needed,
    // for example, when new `text` is set or the `rect` is updated.
    //
    // Terse uses following callbacks:
    // - `UI.terse_query_font_proc`
    // - `UI.terse_query_color_proc`
    // - `UI.terse_draw_proc` (optional)
    //
    // Enabled by `.terse` flag.
    terse: ^terse.Terse,

    // Indicates that the mouse has entered the `rect` of the frame or any of its children.
    entered     : bool,
    entered_prev: bool,

    // Time (in seconds) when the mouse entered the `rect` of the frame or any of its children.
    entered_time: f32,

    // Time (in seconds) when the mouse left the `rect` of the frame or any of its children.
    left_time: f32,

    // Indicates that the frame has captured the mouse.
    // This state begins when the mouse button is pressed and ends when it is released.
    // Releasing the button over the frame's `rect` triggers the `click` event.
    //
    // This behavior is enabled by the `.capture` flag. Without this flag, the frame still receives
    // a `click`, but it is triggered at the moment the mouse button is pressed, not when it is released.
    //
    // Only one frame at any given time can capture the mouse.
    captured: bool,

    // Animation state.
    //
    // Start an animation using `animate()`. The animation callback will be called with this frame as
    // an argument on every UI tick until the animation ends. The callback is guaranteed to be called
    // at least twice: once with `anim.ratio == 0` (start of animation, immediately upon calling `animate()`)
    // and once with `anim.ratio == 1` (end of animation).
    //
    // A new animation can be started at any time by calling `animate()` again -- there's no need to check
    // `animating()` or manually call `end_animation()`; the UI handles that automatically. The animation callback
    // can always expect to receive a final call with `anim.ratio == 1`, which can be used to show/hide the frame,
    // update alpha, apply a final offset, etc.
    //
    // Only one animation per frame can run at a time.
    anim: Animation,

    // Offset to be applied for final `rect`. Useful for animation, as we cannot just move frame by
    // changing its `rect.x` when it is anchored or arranged by `parent.layout`.
    offset: Vec2,

    // Opacity of the frame. The frame only stores this value; it's up to the drawing callbacks
    // to use it when rendering.
    // Use `set_opacity()` to change this value for the frame and all its children.
    opacity: f32,

    // Actor state.
    // More details in `setup_xxx_actors()` procedures.
    actor: Actor,

    rect_status: enum {
        ready,
        update_needed,
        updating_now,
    },
}

Flag :: enum {
    // The frame is hidden.
    // Hidden frames do not receive any input, and none of their callbacks (including `tick`) are triggered.
    // However, if the frame has an unfinished animation, its animation callback is still guaranteed
    // to be called one final time with `anim.ratio == 1` to ensure proper finalization.
    hidden,
    // The frame is disabled.
    // The frame will not be able to capture mouse even with `.capture` flag.
    // Action events `click`, `drag` and `wheel` will not be triggered.
    disabled,
    // The frame and all its children pass all input events.
    pass,
    // The frame passes all input events. The children are not affected.
    pass_self,
    // The frame blocks `wheel` event from propagation to deeper frames.
    block_wheel,
    // The frame can capture mouse. More in `Frame.captured`.
    capture,
    // The frame's `rect` will be used as a scissor for its children when drawing and calculating mouse hit.
    //
    // The following optional UI callbacks are used in drawing phase:
    // - `UI.scissor_set_proc`
    // - `UI.scissor_clear_proc`
    scissor,
    // The frame has trait of a check button. More in `Frame.selected`.
    check,
    // The frame has trait of a radio button. More in `Frame.selected`.
    radio,
    // The frame automatically hides itself when clicked outside of its `rect` or any of its children.
    auto_hide,
    // The frame's `text` is used for terse. More in `Frame.terse`.
    terse,
    // The frame's `size` is set to value of `terse.rect.w/h`.
    // This flag can be used only with `.terse` flag.
    terse_size,
    // The frame's `size.y` is set to value of `terse.rect.h`.
    // This flag can be used only with `.terse` flag.
    terse_height,
    // The frame's `size.x` is set to value of `terse.rect.w`.
    // This flag can be used only with `.terse` flag.
    terse_width,
    // The frame's `terse.rect` is used for mouse hit test instead of `rect`.
    // This flag can be used only with `.terse` flag.
    terse_hit_rect,
    // After the frame's `terse` is regenerated, `terse.shrink_terse()` will also be called.
    // This flag can be used only with `.terse` flag.
    terse_shrink,
}

Animation :: struct {
    tick    : Frame_Proc,
    start   : f32,
    end     : f32,
    ratio   : f32,
}

Drag_Info :: struct {
    // Phase of the drag operation.
    phase: enum { start, dragging, end },
    // Absolute mouse position when the drag started.
    start_mouse_pos: Vec2,
    // Local position within the frame where the drag started.
    start_offset: Vec2,
    // Total offset since the drag started. This value changes as mouse moves.
    total_offset: Vec2,
    // Offset delta since the previous tick. Becomes `0` when the mouse stops moving.
    delta: Vec2,
}

Frame_Proc          :: proc (f: ^Frame)
Frame_Wheel_Proc    :: proc (f: ^Frame, dy: f32) -> (consumed: bool)
Frame_Drag_Proc     :: proc (f: ^Frame, info: Drag_Info)

add_frame :: proc (parent: ^Frame, init: Frame_Init = {}, anchors: ..Anchor) -> ^Frame {
    f := new(Frame)
    f.init = init

    f.entered_time = -999
    f.left_time = -999
    f.opacity = 1

    set_parent(f, parent)
    set_anchors(f, ..anchors)

    name := f.name
    if name != "" {
        f.name = ""
        set_name(f, name)
    }

    text := f.text
    if text != "" {
        f.text = ""
        set_text(f, text)
    }

    text_format := f.text_format
    if text_format != "" {
        f.text_format = ""
        set_text_format(f, text_format)
    }

    return f
}

index :: #force_inline proc (child: ^Frame) -> int {
    assert(child.parent != nil)
    i, _ := #force_inline slice.linear_search(child.parent.children[:], child)
    assert(i >= 0, "Invalid child state. The frame has a parent, but is not listed among the parent's children. Use set_parent() to re-parent correctly.")
    return i
}

depth :: #force_inline proc (f: ^Frame) -> int {
    c := 0
    for i:=f; i!=nil; i=i.parent do c += 1
    return c
}

path :: #force_inline proc (f: ^Frame, allocator := context.allocator) -> [] ^Frame {
    list := make([] ^Frame, depth(f), allocator)
    j := 0
    for i:=f; i!=nil; i=i.parent {
        list[j] = i
        j += 1
    }
    return list
}

path_string :: #force_inline proc (f: ^Frame, include_root := true, include_self := true, allocator := context.allocator) -> string {
    frames := path(f, context.temp_allocator)

    if !include_self do frames = frames[1:]
    if len(frames) == 0 do return ""
    slice.reverse(frames)
    if !include_root do frames = frames[1:]

    names := slice.mapper(
        frames,
        proc (f: ^Frame) -> string {
            return f.name != "" ? f.name : "<nil>"
        },
        context.temp_allocator,
    )

    return strings.join(names, "/", allocator)
}

set_parent :: proc (f: ^Frame, new_parent: ^Frame) {
    if f.parent != nil {
        ordered_remove(&f.parent.children, index(f))
        f.ui = nil
    }

    f.parent = new_parent
    if f.parent != nil {
        append(&f.parent.children, f)
        sort_children(f.parent)
        f.ui = f.parent.ui
    }
}

set_order :: proc (f: ^Frame, new_order: int) {
    f.order = new_order
    if f.parent != nil do sort_children(f.parent)
}

set_name :: proc (f: ^Frame, name: string) {
    delete(f.name)
    f.name = name != "" ? strings.clone(name) : ""
}

set_text :: proc (f: ^Frame, values: ..any, shown := false) {
    format := f.text_format != "" ? f.text_format : "%v"
    new_text := fmt.aprintf(format, ..values)

    if f.text != new_text {
        delete(f.text)
        f.text = new_text

        terse.destroy(f.terse)
        f.terse = nil
    } else {
        delete(new_text)
    }

    if shown do show(f)
    update(f)
}

set_text_format :: proc (f: ^Frame, text_format: string) {
    delete(f.text_format)
    f.text_format = text_format != "" ? strings.clone(text_format) : ""
}

set_opacity :: proc (f: ^Frame, new_opacity: f32) {
    f.opacity = new_opacity
    for child in f.children do set_opacity(child, new_opacity)
}

animate :: proc (f: ^Frame, tick: Frame_Proc, dur: f32) {
    assert(f != nil)
    assert(tick != nil)
    assert(dur > 0)

    end_animation(f)

    f.anim = {
        tick    = tick,
        start   = f.ui.clock.time,
        end     = f.ui.clock.time + dur,
        ratio   = 0,
    }

    tick(f)
}

end_animation :: proc (f: ^Frame) {
    if f.anim.tick != nil {
        f.anim.ratio = 1
        f.anim.tick(f)
        f.anim = {}
    }
}

animating :: #force_inline proc (f: ^Frame) -> bool {
    return f.anim.tick != nil
}

hover_ratio :: #force_inline proc (f: ^Frame, enter_ease: core.Ease, enter_dur: f32, leave_ease: core.Ease, leave_dur: f32) -> f32 {
    if f.entered {
        leave_interrupted_dur := f.entered_time - f.left_time
        leftover_ratio := leave_interrupted_dur<leave_dur ? 1-(leave_interrupted_dur/leave_dur) : 0
        enter_ratio := core.clamp_ratio_span(f.ui.clock.time, f.entered_time, enter_dur)
        ratio := clamp(leftover_ratio + enter_ratio, 0, 1)
        return core.ease_ratio(ratio, enter_ease)
    } else {
        enter_interrupted_dur := f.left_time - f.entered_time
        leftover_ratio := enter_interrupted_dur<enter_dur ? 1-(enter_interrupted_dur/enter_dur) : 0
        leave_ratio := core.clamp_ratio_span(f.ui.clock.time, f.left_time, leave_dur)
        ratio := clamp(leftover_ratio + leave_ratio, 0, 1)
        return 1 - core.ease_ratio(ratio, leave_ease)
    }
}

scroll :: proc (f: ^Frame, dy: f32) -> (actually_scrolled: bool) {
    actually_scrolled = layout_apply_scroll(f, dy)
    if f.actor != nil do wheel_actor(f)
    return
}

scroll_abs :: proc (f: ^Frame, new_offset: f32) -> (actually_scrolled: bool) {
    actually_scrolled = layout_apply_scroll(f, new_offset, is_absolute=true)
    if f.actor != nil do wheel_actor(f)
    return
}

prev_sibling :: #force_inline proc (f: ^Frame) -> ^Frame {
    if f.parent != nil {
        prev_idx := index(f) - 1
        if prev_idx >= 0 {
            return f.parent.children[prev_idx]
        }
    }
    return nil
}

next_sibling :: #force_inline proc (f: ^Frame) -> ^Frame {
    if f.parent != nil {
        next_idx := index(f) + 1
        if next_idx < len(f.parent.children) {
            return f.parent.children[next_idx]
        }
    }
    return nil
}

first_selected_child :: #force_inline proc (parent: ^Frame) -> ^Frame {
    for child in parent.children do if child.selected do return child
    return nil
}

first_visible_child :: #force_inline proc (parent: ^Frame) -> ^Frame {
    for child in parent.children do if .hidden not_in child.flags do return child
    return nil
}

first_visible_sibling :: #force_inline proc (f: ^Frame) -> ^Frame {
    if f.parent != nil do for child in f.parent.children do if .hidden not_in child.flags do return child
    return nil
}

show_by_frame :: proc (f: ^Frame, hide_siblings := false) {
    if hide_siblings && f.parent != nil {
        for child in f.parent.children {
            if child != f do hide_by_frame(child)
        }
    }

    f.flags -= { .hidden }

    if f.parent != nil && f.parent.layout != nil {
        update(f.parent)
    } else {
        update(f)
    }

    if f.show != nil do f.show(f)
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
    if .hidden in f.flags do return

    f.flags += { .hidden }

    if f.parent != nil && f.parent.layout != nil {
        update(f.parent)
    }

    if f.hide != nil do f.hide(f)
}

hide_by_path :: proc (parent: ^Frame, path: string) {
    target := get(parent, path)
    hide_by_frame(target)
}

hide :: proc {
    hide_by_frame,
    hide_by_path,
}

hide_children :: proc (parent: ^Frame) {
    for child in parent.children do hide(child)
}

wheel_by_frame :: proc (f: ^Frame, dy: f32) -> (consumed: bool) {
    if disabled(f) do return false

    if layout_apply_scroll(f, dy)           do consumed = true
    if f.actor != nil && wheel_actor(f, dy) do consumed = true
    if f.wheel != nil && f.wheel(f, dy)     do consumed = true
    if .block_wheel in f.flags              do consumed = true

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

    if .check in f.flags    do f.selected ~= true
    if .radio in f.flags    do click_radio(f)
    if f.actor != nil       do click_actor(f)
    if f.click != nil       do f.click(f)
}

click_by_path :: proc (parent: ^Frame, path: string) {
    target := get(parent, path)
    click_by_frame(target)
}

click :: proc {
    click_by_frame,
    click_by_path,
}

select_next_child :: proc (parent: ^Frame, allow_rotation := false) {
    should_select_next := false

    for child in parent.children {
        if should_select_next && selectable(child) {
            click(child)
            return
        }
        if child.selected do should_select_next = true
    }

    if should_select_next && allow_rotation {
        for child in parent.children {
            if !child.selected && selectable(child) {
                click(child)
                return
            }
        }
    }
}

select_prev_child :: proc (parent: ^Frame, allow_rotation := false) {
    // note: the code is identical to select_next_child(), only #reverse directives were added
    should_select_next := false

    #reverse for child in parent.children {
        if should_select_next && selectable(child) {
            click(child)
            return
        }
        if child.selected do should_select_next = true
    }

    if should_select_next && allow_rotation {
        #reverse for child in parent.children {
            if !child.selected && selectable(child) {
                click(child)
                return
            }
        }
    }
}

hidden :: #force_inline proc (f: ^Frame) -> bool {
    for i:=f; i!=nil; i=i.parent do if .hidden in i.flags do return true
    return false
}

disabled :: #force_inline proc (f: ^Frame) -> bool {
    for i:=f; i!=nil; i=i.parent do if .disabled in i.flags do return true
    return false
}

passing :: #force_inline proc (f: ^Frame) -> bool {
    if .pass_self in f.flags do return true
    for i:=f; i!=nil; i=i.parent do if .pass in i.flags do return true
    return false
}

find :: proc (parent: ^Frame, path: string) -> ^Frame {
    found := parent
    for name in strings.split(path, "/", context.temp_allocator) {
        found = find_by_rule(found, name)
        if found == nil do return nil
    }
    return found
}

get :: proc (parent: ^Frame, path: string) -> ^Frame {
    target := find(parent, path)
    fmt.ensuref(target != nil, "Path \"%s\" not found, use find() in case it is expected", path)
    return target
}

update :: proc (f: ^Frame, include_hidden := false, repeat := 1) {
    for _ in 0..<repeat {
        mark_rect_for_update_frame_tree(f, include_hidden)
        update_rect_frame_tree(f, include_hidden)
    }
}

@private
find_by_rule :: proc (f: ^Frame, rule: string) -> ^Frame {
    if rule == "." do return f
    if rule == ".." do return f.parent

    rule := rule
    allow_non_direct_child := false

    if len(rule) > 0 && rule[0] == '~' {
        rule = rule[1:]
        allow_non_direct_child = true
    }

    for child in f.children {
        if child.name == rule do return child
        found_child := find_by_rule(child, rule)
        if found_child != nil {
            if found_child.parent != f && !allow_non_direct_child {
                found_child = nil
            } else {
                return found_child
            }
        }
    }

    return nil
}

@private
selectable :: #force_inline proc (f: ^Frame) -> bool {
    return (.radio in f.flags) && (f.flags & {.hidden,.disabled} == {})
}

@private
click_radio :: proc (f: ^Frame) {
    if f.parent != nil do for child in f.parent.children do if .radio in child.flags do child.selected = false
    f.selected = true
}

@private
drag :: proc (f: ^Frame, info: Drag_Info) {
    if disabled(f) do return

    if f.actor != nil   do drag_actor(f, info)
    if f.drag != nil    do f.drag(f, info)
}

@private
sort_children :: #force_inline proc (parent: ^Frame) {
    slice.sort_by(parent.children[:], less=#force_inline proc (f1, f2: ^Frame) -> bool {
        return f1.order < f2.order
    })
}

@private
mark_rect_for_update_frame_tree :: proc (f: ^Frame, include_hidden: bool) {
    if include_hidden || .hidden not_in f.flags {
        f.rect_status = .update_needed
        for child in f.children do mark_rect_for_update_frame_tree(child, include_hidden)
    }
}

@private
update_rect_frame_tree :: proc (f: ^Frame, include_hidden: bool) {
    if include_hidden || .hidden not_in f.flags {
        update_rect(f)
        for child in f.children do update_rect_frame_tree(child, include_hidden)
    }
}

@private
destroy_frame_tree :: proc (f: ^Frame) {
    for child in f.children do destroy_frame_tree(child)
    terse.destroy(f.terse)
    delete(f.name)
    delete(f.text)
    delete(f.text_format)
    delete(f.children)
    delete(f.anchors)
    free(f)
}

@private
prepare_frame_tree :: proc (f: ^Frame) {
    if f.anim.tick != nil {
        f.anim.ratio = .hidden in f.flags\
            ? 1\
            : core.clamp_ratio(f.ui.clock.time, f.anim.start, f.anim.end)
        f.anim.tick(f)
        if f.anim.ratio == 1 do f.anim = {}
    }

    f.entered_prev = f.entered
    f.entered = false
    f.captured = false

    f.rect_status = .update_needed
    for child in f.children do prepare_frame_tree(child)

    f.ui.stats.frames_total += 1
}

@private
update_frame_tree :: proc (f: ^Frame) {
    if .hidden in f.flags do return

    update_rect(f)

    m_pos := f.ui.mouse.pos
    hit_rect := .terse_hit_rect in f.flags && f.terse != nil ? f.terse.rect : f.rect
    if core.vec_in_rect(m_pos, hit_rect) && core.vec_in_rect(m_pos, f.ui.scissor_rect) {
        append(&f.ui.mouse_frames, f)
    }

    if .auto_hide in f.flags do append(&f.ui.auto_hide_frames, f)

    if .scissor in f.flags do push_scissor_rect(f.ui, f.rect)
    for child in f.children do update_frame_tree(child)
    if .scissor in f.flags do pop_scissor_rect(f.ui)

    if f.tick != nil do f.tick(f)
}

@private
draw_frame_tree :: proc (f: ^Frame) {
    if .hidden in f.flags do return

    is_drawn: bool
    in_scissor := core.rects_intersect(f.rect, f.ui.scissor_rect)

    if in_scissor {
        if f.draw != nil {
            f.draw(f)
            is_drawn = true
        } else if f.terse != nil && f.ui.terse_draw_proc != nil {
            f.ui.terse_draw_proc(f)
            is_drawn = true
        }
    }

    if f.ui.frame_overdraw_proc != nil do f.ui.frame_overdraw_proc(f)
    if .scissor in f.flags do push_scissor_rect(f.ui, f.rect)
    for child in f.children do draw_frame_tree(child)
    if .scissor in f.flags do pop_scissor_rect(f.ui)
    if in_scissor && f.draw_after != nil do f.draw_after(f)

    if is_drawn do f.ui.stats.frames_drawn += 1
}

@private
update_rect :: proc (f: ^Frame) {
    if f.rect_status != .ready && len(f.anchors) > 0 {
        update_rect_with_anchors(f)
    }

    switch l in f.layout {
    case Flow: update_rect_for_children_of_flow(f)
    case Grid: update_rect_for_children_of_grid(f)
    }

    if .terse in f.flags do update_terse(f)

    if f.actor != nil do update_actor(f)
}
