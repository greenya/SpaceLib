package demo9_screens

import "core:fmt"

import "spacelib:ui"

import "opening"
import "player"

init :: proc (parent: ^ui.Frame) {
    screens := ui.add_frame(parent, { name="screens" }, {point=.top_left}, {point=.bottom_right})
    opening.create(screens)
    player.create(screens)
}

open :: proc (parent: ^ui.Frame, screen_name: string, tab_name := "") {
    screen := ui.get(parent, fmt.tprintf("screens/%s", screen_name))
    ui.show(screen, hide_siblings=true)

    if tab_name != "" {
        tab := ui.get(screen, fmt.tprintf("header_bar/tabs/%s", tab_name))
        ui.click(tab)
    }
}
