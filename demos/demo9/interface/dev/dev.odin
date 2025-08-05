package interface_dev

import "spacelib:ui"

@private ui_: ^ui.UI

add_layer :: proc (ui: ^ui.UI, order: int) {
    assert(ui_ == nil)
    ui_ = ui

    add_dev_layer(order=order)
}

draw_ended :: proc () {
    record_ui_stats()
    draw_frame_list_under_mouse()
}
