package player

import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

@private screen: ^ui.Frame

add :: proc (parent: ^ui.Frame) {
    assert(screen == nil)
    screen = partials.add_screen(parent, "player")

    close := partials.add_screen_footer_key_button(screen, "close", "<icon=key/Esc:1.4:1> Close")
    close.click = proc (f: ^ui.Frame) {
        events.open_screen({ screen_name="home" })
    }

    add_map_page()
    add_inventory_page()
    add_crafting_page()
    add_research_page()
    add_skills_page()
    add_journey_page()
    add_customization_page()

    ui.click(screen, "header_bar/tabs/inventory")
}

@private
add_map_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "map", "MAP")
    partials.add_placeholder_note(page, "MAP PAGE GOES HERE...")
}

@private
add_inventory_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "inventory", "INVENTORY")
    partials.add_placeholder_note(page, "INVENTORY PAGE GOES HERE...")
}

@private
add_crafting_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "crafting", "CRAFTING")
    partials.add_placeholder_note(page, "CRAFTING PAGE GOES HERE...")
}

@private
add_research_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(screen, "research", "RESEARCH")

    tab_points := ui.get(tab, "points")
    ui.set_text(tab_points, data.player.intel_points_avail, shown=true)

    partials.add_placeholder_note(page, "RESEARCH PAGE GOES HERE...")
}

@private
add_skills_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(screen, "skills", "SKILLS")

    tab_points := ui.get(tab, "points")
    ui.set_text(tab_points, data.player.skill_points_avail, shown=true)

    partials.add_placeholder_note(page, "SKILLS PAGE GOES HERE...")
}

@private
add_customization_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "customization", "CUSTOMIZATION")
    partials.add_placeholder_note(page, "CUSTOMIZATION PAGE GOES HERE...")
}
