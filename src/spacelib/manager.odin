package spacelib

import "core:slice"

Manager :: struct {
    root                : ^Frame,

    mouse               : Mouse_Input,
    prev_mouse          : Mouse_Input,
    lmb_pressed         : bool,
    lmb_released        : bool,
    mouse_consumed      : bool,
    mouse_frames        : [dynamic] ^Frame,

    captured_frame      : ^Frame,
    captured_outside    : bool,

    default_draw_proc   : Draw_Proc,
}

Mouse_Input :: struct {
    pos: Vec2,
    lmb_down: bool,
}

create_manager :: proc (default_draw_proc: Draw_Proc = nil) -> ^Manager {
    m := new(Manager)
    m.default_draw_proc = default_draw_proc
    m.root = add_frame({ pass=true })
    return m
}

destroy_manager :: proc (m: ^Manager) {
    destroy_frame_tree(m.root)
    delete(m.mouse_frames)
    free(m)
}

update_manager :: proc (m: ^Manager, screen_rect: Rect, mouse: Mouse_Input) {
    m.mouse = mouse
    m.lmb_pressed = !m.prev_mouse.lmb_down && m.mouse.lmb_down
    m.lmb_released = m.prev_mouse.lmb_down && !m.mouse.lmb_down

    resize(&m.mouse_frames, 0)

    m.root.rect = screen_rect
    mark_frame_tree_dirty(m.root)
    update_frame_tree(m.root, m)

    frame_clicked: bool
    #reverse for f in m.mouse_frames {
        f.hovered = true

        if m.lmb_pressed && f.click != nil && !frame_clicked {
            frame_clicked = true
            m.captured_frame = f
        }

        if f.solid do break
    }

    if m.captured_frame != nil {
        m.captured_frame.pressed = true
        if m.lmb_released {
            if m.captured_frame.hovered do m.captured_frame.click(m.captured_frame)
            m.captured_frame = nil
        }
    }

    top_hover_frame := len(m.mouse_frames) > 0 ? slice.last(m.mouse_frames[:]) : nil
    m.mouse_consumed = m.captured_frame != nil || (top_hover_frame != nil && top_hover_frame != m.root)

    if !m.mouse_consumed && m.lmb_pressed do m.captured_outside = true
    if m.captured_outside && m.lmb_released do m.captured_outside = false

    m.prev_mouse = mouse
}

draw_manager :: proc (manager: ^Manager) {
    draw_frame_tree(manager.root, manager.default_draw_proc)
}
