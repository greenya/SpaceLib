package spacelib_ui

import "core:fmt"
import "core:slice"
import "core:strings"
import "../core"
import "../terse"

Frame_Init :: struct {
    // Set of flags.
    flags           : bit_set [Flag],

    // Absolute rectangle of the frame.
    // In most cases will be updated by the UI depending on `anchors` or `layout`.
    // Set it directly only when frame is not anchored and is not child of a `layout`.
    // For example, the root frame generally has set this directly to screen resolution.
    rect            : Rect,

    // Size. Set only one value to set only it, e.g. size={200,0} will effectively set width,
    // and leave height open for calculations by `anchors` and `layout`.
    size            : Vec2,

    // Size aspect ratio. Considered "not set" if it is zero.
    // The value used only by `anchors` and `Flow` of the parent frame.
    // The value is applied only when one dimension is known and another is zero (not set nor calculated).
    size_aspect     : f32,

    // Minimal size. Width and height are processed separately.
    // Width/height is considered "not set" if it is zero.
    // The value is used only by `Flow` of the parent frame.
    // The value is applied after all size calculations has been made.
    size_min        : Vec2,

    // Layout method for `children`.
    // Affects only children without `anchors`.
    layout          : union { Flow, Grid },

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
    // So general rule: if some frames needs order, you probably want all frames to have `order` set
    // (and different) for consistent sort result.
    order           : int,

    // Name. Not unique.
    name            : string,

    // Text.
    text            : string,
    // Text format for the `text`.
    // If set, the `text` will contain result of `fmt.aprintf(text_format, ...values)`, when calling `set_text()`.
    text_format     : string,

    // Tick callback. Called when `ui.phase == .ticking`.
    // At this point, the `rect` of the frame and each of its children has been calculated.
    // Called before any event callbacks (e.g. `enter`, `click`, etc.)
    // Called on every tick when frame is not `.hidden`.
    tick            : Frame_Proc,

    // Draw callback. Called when `ui.phase == .drawing`.
    // Called before setting own scissor (if used) and before drawing children.
    // Called on every draw when frame is not `.hidden`.
    draw            : Frame_Proc,

    // Post draw callback. Called when `ui.phase == .drawing`.
    // Called after restoring previous scissor (if used) and after drawing children.
    // Called on every draw when frame is not `.hidden`.
    draw_after      : Frame_Proc,

    show            : Frame_Proc,
    hide            : Frame_Proc,
    enter           : Frame_Proc,
    leave           : Frame_Proc,
    click           : Frame_Proc,
    wheel           : Frame_Wheel_Proc,
    drag            : Frame_Drag_Proc,

    // Indicates the frame is selected.
    // Use with `.check` flag if you want UI to toggle it on `click`.
    // Use with `.radio` flag if you want UI to turn it ON on `click` for this frame while turn it OFF
    // for all siblings with `.radio` flag.
    selected        : bool,
}

Frame :: struct {
    // UI this frame is part of.
    // Can be `nil` in case the frame is detached (e.g. `parent == nil`).
    // Note: detached frames will not be destroyed on `destroy_ui()`.
    ui              : ^UI,

    // Parent frame.
    parent          : ^Frame,
    // Child frames. Sorted according to `child.order`.
    children        : [dynamic] ^Frame,

    // Init part of the `Frame` struct.
    using init      : Frame_Init,

    // Anchors.
    // Anchors calculation is using `size` and `size_aspect` to decide on final `rect`.
    // Note: `parent.layout` skips frames with `anchors`.
    anchors         : [dynamic] Anchor,

    // Terse.
    // Enabled by `.terse` flag.
    terse           : ^terse.Terse,

    // Indicates the mouse has entered the `rect` of the frame or any of its children.
    entered         : bool,
    // `entered` value of the previous tick.
    entered_prev    : bool,
    // Time (in seconds) when the mouse entered the `rect` of the frame or any of its children.
    entered_time    : f32,
    // Time (in seconds) when the mouse left the `rect` of the frame or any of its children.
    left_time       : f32,
    // Indicates the frame has captured the mouse.
    // Enabled by `.capture` flag.
    captured        : bool,

    // Animation state.
    anim            : Animation,
    // Offset to be applied for final `rect`. For animation purposes.
    offset          : Vec2,
    // Opacity of the frame. The UI only manages the value, the drawing is done by the drawing callbacks,
    // and they should use this value if necessary.
    opacity         : f32,

    _rect_dirty     : bool,
    _actor          : Actor,
}

Flag :: enum {
    hidden,
    disabled,
    pass,
    pass_self,
    block_wheel,
    capture,
    scissor,
    check,
    radio,
    auto_hide,
    terse,
    terse_size,
    terse_height,
    terse_width,
    terse_hit_rect,
}

Layout_Scroll :: struct {
    step        : f32,
    offset      : f32,
    offset_min  : f32,
    offset_max  : f32,
}

Animation :: struct {
    tick    : Frame_Proc,
    start   : f32,
    end     : f32,
    ratio   : f32,
}

Frame_Proc          :: proc (f: ^Frame)
Frame_Wheel_Proc    :: proc (f: ^Frame, dy: f32) -> (consumed: bool)
Frame_Drag_Proc     :: proc (f: ^Frame, mouse_pos, captured_pos: Vec2)

add_frame :: proc (parent: ^Frame, init: Frame_Init = {}, anchors: ..Anchor) -> ^Frame {
    f := new(Frame)
    f.init = init

    f.entered_time = -999
    f.left_time = -999
    f.opacity = 1

    set_parent(f, parent)
    set_anchors(f, ..anchors)

    if f.name != "" {
        name := f.name
        f.name = ""
        set_name(f, name)
    }

    if f.text != "" {
        text := f.text
        f.text = ""
        set_text(f, text)
    }

    return f
}

update :: proc (f: ^Frame, repeat := 1) {
    for _ in 0..<repeat {
        set_rect_dirty_frame_tree(f)
        update_rect_frame_tree(f)
    }
}

index :: #force_inline proc (child: ^Frame) -> int {
    assert(child.parent != nil)
    i, _ := slice.linear_search(child.parent.children[:], child)
    assert(i >= 0, "Bad child. The child has a parent, but that parent's list of children does not include the child. Please use set_parent() for correct re-parenting.")
    return i
}

depth :: #force_inline proc (f: ^Frame) -> int {
    c := 0
    for i:=f; i!=nil; i=i.parent do c += 1
    return c
}

parents :: #force_inline proc (f: ^Frame, allocator := context.allocator) -> [] ^Frame {
    list := make([] ^Frame, depth(f), allocator)
    j := 0
    for i:=f; i!=nil; i=i.parent {
        list[j] = i
        j += 1
    }
    return list
}

path :: #force_inline proc (f: ^Frame, exclude_root := true, allocator := context.allocator) -> string {
    frames := parents(f, context.temp_allocator)
    slice.reverse(frames)
    if exclude_root do frames = frames[1:]

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
    delete(f.text)
    terse.destroy(f.terse)
    f.terse = nil

    format := f.text_format != "" ? f.text_format : "%v"
    f.text = fmt.aprintf(format, ..values)

    if shown do show(f)
    update(f)
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
    if f._actor != nil do wheel_actor(f)
    return
}

scroll_abs :: proc (f: ^Frame, new_offset: f32) -> (actually_scrolled: bool) {
    actually_scrolled = layout_apply_scroll(f, new_offset, is_absolute=true)
    if f._actor != nil do wheel_actor(f)
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
    if hidden(f) || disabled(f) do return false

    if layout_apply_scroll(f, dy)               do consumed = true
    if f._actor != nil && wheel_actor(f, dy)    do consumed = true
    if f.wheel != nil && f.wheel(f, dy)         do consumed = true
    if .block_wheel in f.flags                  do consumed = true

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

    if .check in f.flags    do f.selected = !f.selected
    if .radio in f.flags    do click_radio(f)
    if f._actor != nil      do click_actor(f)
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

passed :: #force_inline proc (f: ^Frame) -> bool {
    if .pass_self in f.flags do return true
    for i:=f; i!=nil; i=i.parent do if .pass in i.flags do return true
    return false
}

find :: proc (parent: ^Frame, path: string) -> ^Frame {
    found_child := parent
    for name in strings.split(path, "/", context.temp_allocator) {
        found_child = find_by_rule(found_child, name)
        if found_child == nil do return nil
    }
    assert(found_child != parent) // this is expected as strings.split() never returns empty slice, but lets keep the assert
    return found_child
}

get :: proc (parent: ^Frame, path: string) -> ^Frame {
    target := find(parent, path)
    fmt.ensuref(target != nil, "Path \"%s\" not found, use find() in case its expected", path)
    return target
}

@private
find_by_rule :: proc (parent: ^Frame, rule: string) -> ^Frame {
    rule := rule
    allow_non_direct_child := false

    if rule == ".." do return parent.parent

    if len(rule) > 0 && rule[0] == '~' {
        rule = rule[1:]
        allow_non_direct_child = true
    }

    for child in parent.children {
        if child.name == rule do return child
        found_child := find_by_rule(child, rule)
        if found_child != nil {
            if found_child.parent != parent && !allow_non_direct_child {
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
layout_scroll :: #force_inline proc (f: ^Frame) -> ^Layout_Scroll {
    #partial switch &l in f.layout {
    case Flow: if l.scroll.step != 0 do return &l.scroll
    }
    return nil
}

@private
layout_apply_scroll :: #force_inline proc (f: ^Frame, dy: f32, is_absolute := false) -> (consumed: bool) {
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
click_radio :: proc (f: ^Frame) {
    if f.parent != nil do for child in f.parent.children do if .radio in child.flags do child.selected = false
    f.selected = true
}

@private
drag :: proc (f: ^Frame, mouse_pos, captured_pos: Vec2) {
    if disabled(f) do return

    if f._actor != nil  do drag_actor(f, mouse_pos, captured_pos)
    if f.drag != nil    do f.drag(f, mouse_pos, captured_pos)
}

@private
sort_children :: #force_inline proc (parent: ^Frame) {
    slice.sort_by(parent.children[:], less=#force_inline proc (f1, f2: ^Frame) -> bool {
        return f1.order < f2.order
    })
}

@private
set_rect_dirty_frame_tree :: proc (f: ^Frame) {
    f._rect_dirty = true
    for child in f.children do set_rect_dirty_frame_tree(child)
}

@private
update_rect_frame_tree :: proc (f: ^Frame) {
    update_rect(f)
    for child in f.children do update_rect_frame_tree(child)
}

@private
destroy_frame_tree :: proc (f: ^Frame) {
    for child in f.children do destroy_frame_tree(child)
    terse.destroy(f.terse)
    delete(f.name)
    delete(f.text)
    delete(f.children)
    delete(f.anchors)
    free(f)
}

@private
destroy_terse_frame_tree :: proc (f: ^Frame) {
    for child in f.children do destroy_terse_frame_tree(child)
    if f.terse != nil {
        terse.destroy(f.terse)
        f.terse = nil
    }
}

@private
prepare_frame_tree :: proc (f: ^Frame) {
    if f.anim.tick != nil {
        f.anim.ratio = core.clamp_ratio(f.ui.clock.time, f.anim.start, f.anim.end)
        f.anim.tick(f)
        if f.anim.ratio == 1 do f.anim = {}
    }

    f.entered_prev = f.entered
    f.entered = false
    f.captured = false

    f._rect_dirty = true
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

    if f.terse != nil do f.terse.opacity = f.opacity

    is_drawn: bool
    in_scissor := core.rect_intersection(f.rect, f.ui.scissor_rect) != {}

    if in_scissor {
        if f.draw != nil {
            if .terse not_in f.flags || f.terse != nil {
                f.draw(f)
                is_drawn = true
            }
        } else {
            if f.terse != nil {
                assert(f.ui.terse_draw_proc != nil, "UI.terse_draw_proc must not be nil when using terse")
                f.ui.terse_draw_proc(f.terse)
                is_drawn = true
            }
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
    if f._rect_dirty && len(f.anchors) > 0 do update_rect_with_anchors(f)

    switch l in f.layout {
    case Flow: update_rect_for_children_of_flow(f)
    case Grid: update_rect_for_children_of_grid(f)
    }

    if .terse in f.flags do update_terse(f)

    if f._actor != nil do wheel_actor(f)
}

@private
update_terse :: proc (f: ^Frame) {
    should_rebuild :=
        f.terse == nil ||
        (f.terse != nil && !core.rect_equal_approx(f.terse.rect_input, f.rect, e=.5)) ||
        (f.terse != nil && !core.rect_equal_approx(f.terse.scissor, f.ui.scissor_rect, e=.5))

    if !should_rebuild do return

    assert(f.ui.terse_query_font_proc != nil, "UI.terse_query_font_proc must not be nil when using terse")
    assert(f.ui.terse_query_color_proc != nil, "UI.terse_query_color_proc must not be nil when using terse")

    scroll_offset_delta: Vec2

    if f.terse != nil {
        rect_size_changed :=
            abs(f.rect.w-f.terse.rect_input.w) > .1 ||
            abs(f.rect.h-f.terse.rect_input.h) > .1
        if !rect_size_changed {
            scroll_offset_delta = { f.rect.x-f.terse.rect_input.x, f.rect.y-f.terse.rect_input.y }
        }
    }

    if !core.vec_zero_approx(scroll_offset_delta, e=.5) {
        terse.apply_offset(f.terse, scroll_offset_delta)
    } else {
        terse.destroy(f.terse)
        f.terse = terse.create(
            f.text,
            f.rect,
            f.ui.terse_query_font_proc,
            f.ui.terse_query_color_proc,
            f.ui.scissor_rect,
            f.opacity,
        )
    }

    if f.flags & {.terse_size,.terse_width} != {} {
        f.size.x = f.size_min.x>0 ? max(f.size_min.x, f.terse.rect.w) : f.terse.rect.w
    }

    if f.flags & {.terse_size,.terse_height} != {} {
        f.size.y = f.size_min.y>0 ? max(f.size_min.y, f.terse.rect.h) : f.terse.rect.h
    }
}

@private
get_layout_visible_children :: proc (parent: ^Frame, allocator := context.allocator) -> [] ^Frame {
    assert(parent.layout != nil)
    list := make([dynamic] ^Frame, allocator)
    for child in parent.children {
        if len(child.anchors) > 0 do continue
        if .hidden in child.flags do continue
        append(&list, child)
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
