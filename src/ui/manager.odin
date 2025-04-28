package spacelib_ui

import "core:slice"
import "core:time"

Manager :: struct {
    root                : ^Frame,

    mouse               : Mouse_Input,
    prev_mouse          : Mouse_Input,

    phase               : Processing_Phase,
    captured            : Captured_Info,

    mouse_frames        : [dynamic] ^Frame,
    entered_frames      : [dynamic] ^Frame,
    auto_hide_frames    : [dynamic] ^Frame,

    scissor_rect        : Rect,
    scissor_rects       : [dynamic] Rect,
    scissor_set_proc    : Scissor_Set_Proc,
    scissor_clear_proc  : Scissor_Clear_Proc,

    overdraw_proc       : Frame_Proc,

    stats               : Manager_Stats,
}

Mouse_Input :: struct {
    pos     : Vec2,
    wheel_dy: f32,
    lmb_down: bool,
}

Processing_Phase :: enum {
    none,
    updating,
    drawing,
}

Captured_Info :: struct {
    outside : bool,
    frame   : ^Frame,
    pos     : Vec2,
}

Manager_Stats :: struct {
    updating_time   : time.Duration,
    drawing_time    : time.Duration,
    frames_total    : int,
    frames_drawn    : int,
    scissors_set    : int,
}

Scissor_Set_Proc    :: proc (r: Rect)
Scissor_Clear_Proc  :: proc ()

create_manager :: proc (scissor_set_proc: Scissor_Set_Proc = nil, scissor_clear_proc: Scissor_Clear_Proc = nil, overdraw_proc: Frame_Proc = nil) -> ^Manager {
    m := new(Manager)
    m.scissor_set_proc = scissor_set_proc
    m.scissor_clear_proc = scissor_clear_proc
    m.overdraw_proc = overdraw_proc
    m.root = add_frame(nil, { pass=true })
    return m
}

destroy_manager :: proc (m: ^Manager) {
    destroy_frame_tree(m.root)
    delete(m.mouse_frames)
    delete(m.entered_frames)
    delete(m.auto_hide_frames)
    delete(m.scissor_rects)
    free(m)
}

update_manager :: proc (m: ^Manager, root_rect: Rect, mouse: Mouse_Input) -> (mouse_input_consumed: bool) {
    m.stats = {}
    phase_started := time.tick_now()
    m.phase = .updating
    defer {
        m.phase = .none
        m.stats.updating_time = time.tick_since(phase_started)
    }

    m.root.rect = root_rect
    m.scissor_rect = root_rect

    m.mouse = mouse
    lmb_pressed := !m.prev_mouse.lmb_down && m.mouse.lmb_down
    lmb_released := m.prev_mouse.lmb_down && !m.mouse.lmb_down

    clear(&m.mouse_frames)
    clear(&m.auto_hide_frames)

    mark_frame_tree_rect_dirty(m.root, m)
    update_frame_tree(m.root, m)

    if !m.captured.outside {
        #reverse for f in m.mouse_frames {
            if f.pass do continue
            if m.captured.frame != nil && m.captured.frame != f do continue

            mouse_input_consumed = true

            f.hovered = true
            if !f.prev_hovered {
                append(&m.entered_frames, f)
                if f.enter != nil do f.enter(f)
            }

            if lmb_pressed do m.captured = { frame=f, pos=m.mouse.pos-{f.rect.x,f.rect.y} }

            break
        }

        if m.captured.frame != nil {
            mouse_input_consumed = true

            m.captured.frame.captured = true
            drag(m.captured.frame, m.mouse.pos, m.captured.pos)

            if lmb_released {
                if m.captured.frame.hovered do click(m.captured.frame)
                m.captured = {}
            }
        }

        if mouse.wheel_dy != 0 do #reverse for f in m.mouse_frames {
            if f.pass do continue
            consumed := wheel(f, mouse.wheel_dy)
            if consumed do break
        }
    }

    for i := len(m.entered_frames) - 1; i >= 0; i -= 1 {
        f := m.entered_frames[i]
        if f.prev_hovered && !f.hovered {
            unordered_remove(&m.entered_frames, i)
            if f.leave != nil do f.leave(f)
        }
    }

    if lmb_pressed do for f in m.auto_hide_frames {
        if !f.hidden {
            _, found := slice.linear_search_reverse(m.mouse_frames[:], f)
            if !found do f.hidden = true
        }
    }

    if !mouse_input_consumed && lmb_pressed do m.captured = { outside=true }
    if m.captured.outside && lmb_released do m.captured = {}

    m.prev_mouse = mouse
    return
}

draw_manager :: proc (m: ^Manager) {
    phase_started := time.tick_now()
    m.phase = .drawing
    defer {
        m.phase = .none
        m.stats.drawing_time = time.tick_since(phase_started)
    }

    assert(len(m.scissor_rects) == 0)
    m.scissor_rect = m.root.rect

    draw_frame_tree(m.root, m)
}

@(private)
push_scissor_rect :: proc (m: ^Manager, new_rect: Rect) {
    assert(m.phase != .none)

    new_rect := new_rect

    last_rect := slice.last_ptr(m.scissor_rects[:])
    if last_rect != nil {
        new_rect = rect_intersection(new_rect, last_rect^)
    }

    append(&m.scissor_rects, new_rect)
    m.scissor_rect = new_rect
    if m.phase == .drawing && m.scissor_set_proc != nil {
        m.scissor_set_proc(new_rect)
        m.stats.scissors_set += 1
    }
}

@(private)
pop_scissor_rect :: proc (m: ^Manager) {
    assert(m.phase != .none)
    assert(len(m.scissor_rects) > 0)

    pop(&m.scissor_rects)

    last_rect := slice.last_ptr(m.scissor_rects[:])
    if last_rect != nil {
        m.scissor_rect = last_rect^
        if m.phase == .drawing && m.scissor_set_proc != nil do m.scissor_set_proc(last_rect^)
    } else {
        m.scissor_rect = m.root.rect
        if m.phase == .drawing && m.scissor_clear_proc != nil do m.scissor_clear_proc()
    }
}
