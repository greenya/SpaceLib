package demo9_screens

import "core:fmt"

import "spacelib:core"
import "spacelib:ui"

import "../events"
import "credits"
import "opening"
import "player"

@private screens: ^ui.Frame

add :: proc (parent: ^ui.Frame) {
    assert(screens == nil)

    screens = ui.add_frame(parent, { name="screens" }, {point=.top_left}, {point=.bottom_right})
    credits.add(screens)
    opening.add(screens)
    player.add(screens)

    events.listen("open_screen", open_screen)
}

@private
open_screen :: proc (args: ..any) {
    screen_name := core.any_as_string(args[0])
    tab_name := len(args) > 1 ? core.any_as_string(args[1]) : ""

    screen := ui.get(screens, screen_name)
    ui.show(screen, hide_siblings=true)

    if tab_name != "" {
        tab := ui.get(screen, fmt.tprintf("header_bar/tabs/%s", tab_name))
        ui.click(tab)
    }
}
