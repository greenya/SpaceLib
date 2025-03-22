package spacelib

import "core:slice"

Manager :: struct {
    root                : ^Frame,

    mouse               : Mouse_Input,
    prev_mouse          : Mouse_Input,
    lmb_pressed         : bool,
    lmb_released        : bool,
    mouse_frames        : [dynamic] ^Frame,

    captured_frame      : ^Frame,
    captured_outside    : bool,
    auto_hide_frames    : [dynamic] ^Frame,

    default_draw_proc   : Frame_Proc,
}

Mouse_Input :: struct {
    pos: Vec2,
    lmb_down: bool,
}

create_manager :: proc (default_draw_proc: Frame_Proc = nil) -> ^Manager {
    m := new(Manager)
    m.default_draw_proc = default_draw_proc
    m.root = add_frame({ pass=true })
    return m
}

destroy_manager :: proc (m: ^Manager) {
    destroy_frame_tree(m.root)
    delete(m.mouse_frames)
    delete(m.auto_hide_frames)
    free(m)
}

update_manager :: proc (m: ^Manager, screen_rect: Rect, mouse: Mouse_Input) -> (mouse_input_consumed: bool) {
    m.mouse = mouse
    m.lmb_pressed = !m.prev_mouse.lmb_down && m.mouse.lmb_down
    m.lmb_released = m.prev_mouse.lmb_down && !m.mouse.lmb_down

    resize(&m.mouse_frames, 0)
    resize(&m.auto_hide_frames, 0)

    m.root.rect = screen_rect
    mark_frame_tree_dirty(m.root)
    update_frame_tree(m.root, m)

    if !m.captured_outside {
        frame_clicked: bool

        #reverse for f in m.mouse_frames {
            if f.pass do continue
            if m.captured_frame != nil && m.captured_frame != f do continue

            f.hovered = true
            mouse_input_consumed = true

            if m.lmb_pressed && f.click != nil && !frame_clicked {
                frame_clicked = true
                m.captured_frame = f
            }

            if f.solid do break
        }

        if m.captured_frame != nil {
            m.captured_frame.pressed = true
            mouse_input_consumed = true

            if m.lmb_released {
                if m.captured_frame.hovered {
                    m.captured_frame.click(m.captured_frame);
                    update_frame_tree(m.root, m);
                }
                m.captured_frame = nil
            }
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

draw_manager :: proc (manager: ^Manager) {
    draw_frame_tree(manager.root, manager.default_draw_proc)
}
