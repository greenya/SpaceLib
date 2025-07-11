package demo9_interface

import "spacelib:ui"

import "partials"

@private modals_layer: ^ui.Frame

@private
add_modals_layer :: proc (order: int) {
    assert(modals_layer == nil)

    modals_layer = ui.add_frame(ui_.root, {
        name    = "modals_layer",
        flags   = {/*.hidden,*/.block_wheel},
        order   = order,
        text    = "#000b",
        draw    = partials.draw_color_rect,
    }, { point=.top_left }, { point=.bottom_right })

    add_modal()
}

@private
add_modal :: proc () {
    modal := ui.add_frame(modals_layer, {
        name    = "modal",
        size    = {600,300},
        layout  = {dir=.down/*,auto_size=.dir*/,pad=40,gap=40},
        draw    = partials.draw_window_rect,
    }, { point=.center })

    title := ui.add_frame(modal, {
        name        = "title",
        flags       = {.terse,.terse_height},
        text_format = "<font=text_4m,color=primary_d2>%s",
    })

    ui.set_text(title, "Quit Game")
}
