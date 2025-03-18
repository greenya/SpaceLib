package spacelib

Manager :: struct {
    root: ^Frame,
}

Mouse :: struct {
    pos: Vec2,
    lmb_down: bool,
}

create_manager :: proc () -> ^Manager {
    manager := new(Manager)
    manager.root = add_frame({})
    return manager
}

destroy_manager :: proc (manager: ^Manager) {
    destroy_frame_tree(manager.root)
    free(manager)
}

update_manager :: proc (manager: ^Manager, screen_rect: Rect, mouse: Mouse) {
    manager.root.rect = screen_rect
    update_frame_tree(manager.root)
}

draw_manager :: proc (manager: ^Manager) {
    draw_frame_tree(manager.root)
}
