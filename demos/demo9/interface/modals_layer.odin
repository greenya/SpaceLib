#+private
package interface

import "core:fmt"

import "spacelib:ui"

import "../partials"

modals: struct {
    layer: ^ui.Frame,
    modal: ^ui.Frame,
}

add_modals_layer :: proc (order: int) {
    assert(modals.layer == nil)

    modals.layer = ui.add_frame(ui_.root, {
        name    = "modals_layer",
        flags   = {.hidden,.block_wheel},
        order   = order,
        text    = "#000b",
        draw    = partials.draw_color_rect,
    }, { point=.top_left }, { point=.bottom_right })

    add_modal()
}

add_modal :: proc () {
    modal := ui.add_frame(modals.layer, {
        name    = "modal",
        size    = {600,0},
        layout  = {dir=.down,auto_size=.dir,pad=30},
        draw    = partials.draw_window_rect,
    }, { point=.center })

    title := ui.add_frame(modal, {
        name        = "title",
        flags       = {.terse,.terse_height},
        text_format = "<wrap,pad=30,font=text_4m,color=primary_d2>%s",
    })

    message := ui.add_frame(modal, {
        name        = "message",
        flags       = {.terse,.terse_height},
        text_format = "<wrap,font=text_4l,color=primary_d2>%s",
    })

    buttons := ui.add_frame(modal, {
        name    = "buttons",
        size    = {0,90},
        layout  = {dir=.left_and_right,gap=20,align=.end},
    })

    for i in 1..=3 {
        name := fmt.tprintf("button_%i", i)
        title := fmt.tprintf("Button %i", i)
        button := partials.add_button(buttons, name, title, "X")
        button.size_min = {150,0}
    }

    ui.set_text(title, "Quit Game")
    ui.set_text(message, "Are you sure you want to quit?")
}
