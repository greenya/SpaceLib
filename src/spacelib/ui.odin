package spacelib

UI :: struct {
    frame       : ^Frame,
    fonts       : [dynamic] ^Font,
    is_debug    : bool,
}

create_ui :: proc () -> ^UI {
    ui := new(UI)
    ui.frame = add_frame()
    set_abs_rect(ui.frame, { 0, 0, 100, 100 })
    return ui
}

destroy_ui :: proc (ui: ^UI) {
    destroy_frame(ui.frame)
    delete(ui.fonts)
    free(ui)
}

draw_ui :: proc (ui: ^UI, rect: Rect) {
    ui.frame.abs_rect = rect
    draw_frame(ui.frame, ui)
}
