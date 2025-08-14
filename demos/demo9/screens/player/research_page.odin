#+private
package player

import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

research_page: struct {
    root        : ^ui.Frame,
    help_button : ^ui.Frame,
}

add_research_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(&screen, "research", "RESEARCH")
    research_page.root = page

    tab_points := ui.get(tab, "points")
    ui.set_text(tab_points, data.player.intel_points_avail, shown=true)

    research_page.help_button = partials.add_screen_key_button(&screen, "help", "<icon=key/H> Help")
    research_page.help_button.click = proc (f: ^ui.Frame) {
        events.open_modal({ target=f, instruction_id="player/research/help" })
    }

    research_page.root.show = proc (f: ^ui.Frame) {
        ui.show(research_page.help_button)
    }

    research_page.root.hide = proc (f: ^ui.Frame) {
        ui.hide(research_page.help_button)
    }

    partials.add_placeholder_note(page, "RESEARCH PAGE GOES HERE...\nThe \"Help\" button in the footer is working \\\\o/")
}
