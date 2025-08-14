#+private
package player

import "spacelib:ui"

import "../../events"
import "../../partials"

crafting_page: struct {
    root        : ^ui.Frame,
    help_button : ^ui.Frame,
}

add_crafting_page :: proc () {
    _, crafting_page.root = partials.add_screen_tab_and_page(&screen, "crafting", "CRAFTING")

    crafting_page.help_button = partials.add_screen_key_button(&screen, "help", "<icon=key/H> Help")
    crafting_page.help_button.click = proc (f: ^ui.Frame) {
        events.open_modal({ target=f, instruction_id="player/crafting/help" })
    }

    crafting_page.root.show = proc (f: ^ui.Frame) {
        ui.show(crafting_page.help_button)
    }

    crafting_page.root.hide = proc (f: ^ui.Frame) {
        ui.hide(crafting_page.help_button)
    }

    partials.add_placeholder_note(crafting_page.root, "CRAFTING PAGE GOES HERE...\nThe \"Help\" button in the footer is working \\\\o/")
}
