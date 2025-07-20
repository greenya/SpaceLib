package spacelib_ui

import "core:fmt"
import "core:slice"
import "core:strings"
import "../core"
import "../terse"

Frame :: struct {
    ui              : ^UI,

    parent          : ^Frame,
    flags           : bit_set [Flag],
    order           : int,
    children        : [dynamic] ^Frame,
    layout          : union { Flow, Grid },

    rect            : Rect,
    rect_dirty      : bool,
    anchors         : [dynamic] Anchor,
    size            : Vec2,
    size_min        : Vec2,
    size_aspect     : f32,

    name            : string,
    text            : string,
    text_format     : string,
    terse           : ^terse.Terse,
    actor           : Actor,

    tick            : Frame_Proc,
    show            : Frame_Proc,
    hide            : Frame_Proc,
    draw            : Frame_Proc,
    draw_after      : Frame_Proc,
    enter           : Frame_Proc,
    entered         : bool,
    entered_prev    : bool,
    entered_time    : f32,
    leave           : Frame_Proc,
    left_time       : f32,
    click           : Frame_Proc,
    wheel           : Frame_Wheel_Proc,
    captured        : bool,
    selected        : bool,

    anim            : Animation,
    offset          : Vec2,
    opacity         : f32,
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

Anchor :: struct {
    point       : Anchor_Point,
    rel_point   : Anchor_Point,
    rel_frame   : ^Frame,
    offset      : Vec2,
}

Anchor_Point :: enum {
    none,
    mouse,
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

Flow :: struct {
    dir         : Flow_Direction,
    align       : Flow_Alignment,
    scroll      : Layout_Scroll,
    size        : Vec2,
    gap         : f32,
    pad         : Vec2,
    auto_size   : Flow_Auto_Size,
}

Flow_Direction :: enum {
    left,
    left_and_right,
    right,
    up,
    up_and_down,
    down,
}

Flow_Alignment :: enum {
    start,
    center,
    end,
}

Flow_Auto_Size :: enum {
    none,
    full,
    dir,
}

Grid :: struct {
    dir         : Grid_Direction,
    wrap        : int,
    aspect_ratio: f32,
    gap         : Vec2,
    pad         : Vec2,
    auto_size   : bool,
}

Grid_Direction :: enum {
    right_down,
    // TODO: support other Grid directions
    // down_right,
    // left_down,
    // down_left,
    // right_up,
    // up_right,
    // left_up,
    // up_left,
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

Frame_Proc          :: proc (f: ^Frame)
Frame_Wheel_Proc    :: proc (f: ^Frame, dy: f32) -> (consumed: bool)

add_frame :: proc (parent: ^Frame, init: Frame = {}, anchors: ..Anchor) -> ^Frame {
    assert(init.parent == nil, "Pass parent as argument, not in init value")

    f := new(Frame)
    f^ = init
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

set_anchors :: proc (f: ^Frame, anchors: ..Anchor) {
    clear_anchors(f)
    for a in anchors {
        init := a
        assert(init.point != .mouse, "Mouse anchor can only be used as rel_point.")
        if init.point == .none      do init.point = .top_left
        if init.rel_point == .none  do init.rel_point = init.point
        append(&f.anchors, init)
    }
}

clear_anchors :: #force_inline proc (f: ^Frame) {
    resize(&f.anchors, 0)
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
        left_ratio_interrupted := 1 - clamp((f.entered_time - f.left_time)/leave_dur, 0, 1)
        enter_ratio := core.clamp_ratio_span(f.ui.clock.time, f.entered_time, enter_dur)
        ratio := clamp(left_ratio_interrupted + enter_ratio, 0, 1)
        return core.ease_ratio(ratio, enter_ease)
    } else {
        enter_ratio_interrupted := clamp((f.left_time - f.entered_time)/enter_dur, 0, 1)
        if f.left_time != 0 { // prevents default value 0 to be treated as "just left" when ui.clock.time is ~0
            left_ratio := core.clamp_ratio_span(f.ui.clock.time, f.left_time, leave_dur)
            ratio := clamp(1 - enter_ratio_interrupted + left_ratio, 0, 1)
            return 1 - core.ease_ratio(ratio, leave_ease)
        } else {
            return 0
        }
    }
}

set_scroll_offset :: proc (f: ^Frame, value: f32) {
    layout_apply_scroll(f, value, is_absolute=true)
    if f.actor != nil do wheel_actor(f)
}

layout_flow :: #force_inline proc (f: ^Frame) -> ^Flow {
    #partial switch &l in f.layout {
    case Flow: return &l
    }
    panic("Layout is not Flow")
}

layout_grid :: #force_inline proc (f: ^Frame) -> ^Grid {
    #partial switch &l in f.layout {
    case Grid: return &l
    }
    panic("Layout is not Grid")
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

    if .check in f.flags    do f.selected = !f.selected
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
    if f.actor != nil do drag_actor(f, mouse_pos, captured_pos)
}

@private
sort_children :: #force_inline proc (parent: ^Frame) {
    slice.sort_by(parent.children[:], less=#force_inline proc (f1, f2: ^Frame) -> bool {
        return f1.order < f2.order
    })
}

@private
set_rect_dirty_frame_tree :: proc (f: ^Frame) {
    f.rect_dirty = true
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
prepare_frame_tree :: proc (f: ^Frame) {
    if f.anim.tick != nil {
        f.anim.ratio = core.clamp_ratio(f.ui.clock.time, f.anim.start, f.anim.end)
        f.anim.tick(f)
        if f.anim.ratio == 1 do f.anim = {}
    }

    f.entered_prev = f.entered
    f.entered = false
    f.captured = false

    f.rect_dirty = true
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
    if f.rect_dirty && len(f.anchors) > 0 do update_rect_with_anchors(f)

    switch l in f.layout {
    case Flow: update_rect_for_children_of_flow(f)
    case Grid: update_rect_for_children_of_grid(f)
    }

    if .terse in f.flags do update_terse(f)

    if f.size_min.x > 0 do f.size.x = max(f.size.x, f.size_min.x)
    if f.size_min.y > 0 do f.size.y = max(f.size.y, f.size_min.y)

    if f.actor != nil do wheel_actor(f)
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

    if scroll_offset_delta != {} {
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

    if f.flags & {.terse_size,.terse_width} != {} do f.size.x = f.terse.rect.w
    if f.flags & {.terse_size,.terse_height} != {} do f.size.y = f.terse.rect.h
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
    case Flow: return l.dir == .down || l.dir == .up || l.dir == .up_and_down
    case Grid: return l.dir == .right_down
    }
    panic("Frame has no layout")
}
