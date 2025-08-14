#+private
package player

import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

skills_page: struct {
    root        : ^ui.Frame,
    help_button : ^ui.Frame,
}

add_skills_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(&screen, "skills", "SKILLS")
    skills_page.root = page

    tab_points := ui.get(tab, "points")
    ui.set_text(tab_points, data.player.skill_points_avail, shown=true)

    skills_page.help_button = partials.add_screen_key_button(&screen, "help", "<icon=key/H> Help")
    skills_page.help_button.click = proc (f: ^ui.Frame) {
        events.open_modal({ target=f, instruction_id="player/skills/help" })
    }

    skills_page.root.show = proc (f: ^ui.Frame) {
        ui.show(skills_page.help_button)
    }

    skills_page.root.hide = proc (f: ^ui.Frame) {
        ui.hide(skills_page.help_button)
    }

    partials.add_placeholder_note(page, "SKILLS PAGE GOES HERE...\nThe \"Help\" button in the footer is working \\\\o/")
}
