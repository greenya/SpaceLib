package spacelib

import "core:slice"

Manager :: struct {
    root                : ^Frame,

    mouse               : Mouse_Input,
    prev_mouse          : Mouse_Input,
    lmb_pressed         : bool,
    lmb_released        : bool,

    captured_frame      : ^Frame,
    captured_outside    : bool,

    mouse_frames        : [dynamic] ^Frame,
    entered_frames      : [dynamic] ^Frame,
    auto_hide_frames    : [dynamic] ^Frame,

    scissor_start_proc  : Frame_Proc,
    scissor_end_proc    : Frame_Proc,
    frame_post_draw_proc: Frame_Proc,
}

Mouse_Input :: struct {
    pos: Vec2,
    wheel_dy: f32,
    lmb_down: bool,
}

create_manager :: proc (scissor_start_proc: Frame_Proc = nil, scissor_end_proc: Frame_Proc = nil, frame_post_draw_proc: Frame_Proc = nil) -> ^Manager {
    m := new(Manager)
    m.scissor_start_proc = scissor_start_proc
    m.scissor_end_proc = scissor_end_proc
    m.frame_post_draw_proc = frame_post_draw_proc
    m.root = add_frame(nil, { pass=true })
    return m
}

destroy_manager :: proc (m: ^Manager) {
    destroy_frame_tree(m.root)
    delete(m.mouse_frames)
    delete(m.entered_frames)
    delete(m.auto_hide_frames)
    free(m)
}

update_manager :: proc (m: ^Manager, root_rect: Rect, mouse: Mouse_Input) -> (mouse_input_consumed: bool) {
    m.mouse = mouse
    m.lmb_pressed = !m.prev_mouse.lmb_down && m.mouse.lmb_down
    m.lmb_released = m.prev_mouse.lmb_down && !m.mouse.lmb_down

    resize(&m.mouse_frames, 0)
    resize(&m.auto_hide_frames, 0)

    m.root.rect = root_rect
    mark_frame_tree_rect_dirty(m.root)
    update_frame_tree(m.root, m)

    if !m.captured_outside {
        #reverse for f in m.mouse_frames {
            if f.pass do continue
            if m.captured_frame != nil && m.captured_frame != f do continue

            mouse_input_consumed = true
            f.hovered = true
            if !f.prev_hovered {
                append(&m.entered_frames, f)
                if f.enter != nil do f.enter(f)
            }

            if m.lmb_pressed do m.captured_frame = f

            break
        }

        if m.captured_frame != nil {
            mouse_input_consumed = true
            m.captured_frame.pressed = true

            if m.lmb_released {
                if m.captured_frame.hovered do click(m.captured_frame)
                m.captured_frame = nil
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

    if m.lmb_pressed do for f in m.auto_hide_frames {
        if !f.hidden {
            _, found := slice.linear_search_reverse(m.mouse_frames[:], f)
            if !found do f.hidden = true
        }
    }

    if !mouse_input_consumed && m.lmb_pressed do m.captured_outside = true
    if m.captured_outside && m.lmb_released do m.captured_outside = false

    m.prev_mouse = mouse
    return
}

draw_manager :: proc (m: ^Manager) {
    draw_frame_tree(m.root, m)
}
