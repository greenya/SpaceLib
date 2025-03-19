package spacelib

Manager :: struct {
    root            : ^Frame,
    mouse           : Mouse_Input,
    prev_mouse      : Mouse_Input,
    lmb_pressed     : bool,
    lmb_released    : bool,
    mouse_consumed  : bool,
    top_hover_frame : ^Frame,
    capture_frame   : ^Frame,
    // capture_outside : bool,

    default_draw_proc: Draw_Proc,
}

// todo: add capture_outside? or maybe capture by root treat as "world capture"
// the idea:
// if something pressed outside the ui, the ui should not detect hover,
// it should treat it as its captured/locked by foreign system (and do not interfere)

// todo: click should only be fire for single frame if clickable frames overlap

Mouse_Input :: struct {
    pos: Vec2,
    lmb_down: bool,
}

create_manager :: proc () -> ^Manager {
    m := new(Manager)
    m.root = add_frame({})
    return m
}

destroy_manager :: proc (m: ^Manager) {
    destroy_frame_tree(m.root)
    free(m)
}

update_manager :: proc (m: ^Manager, screen_rect: Rect, mouse: Mouse_Input) {
    m.lmb_pressed = !m.prev_mouse.lmb_down && mouse.lmb_down
    m.lmb_released = m.prev_mouse.lmb_down && !mouse.lmb_down
    m.mouse = mouse
    m.top_hover_frame = nil

    m.root.rect = screen_rect
    update_frame_tree(m.root, m)

    if m.capture_frame != nil && m.lmb_released {
        if m.capture_frame.hovered do m.capture_frame.click(m.capture_frame)
        m.capture_frame = nil
    }

    m.mouse_consumed = m.capture_frame != nil || (m.top_hover_frame != nil && m.top_hover_frame != m.root)

    m.prev_mouse = mouse
}

draw_manager :: proc (manager: ^Manager) {
    draw_frame_tree(manager.root, manager.default_draw_proc)
}
