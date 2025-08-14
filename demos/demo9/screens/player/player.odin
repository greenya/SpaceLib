package player

import "spacelib:core"
import "spacelib:ui"

import "../../events"
import "../../partials"

@private Vec2 :: core.Vec2
@private Color :: core.Color

@private screen: partials.Screen

add :: proc (parent: ^ui.Frame) {
    screen = partials.add_screen(parent, "player")

    partials.add_screen_pyramid_button(&screen, "social", "SOCIAL", icon="groups")
    partials.move_screen_pyramid_buttons(&screen, .center)

    close := partials.add_screen_key_button(&screen, "close", "<icon=key/Esc:1.4:1> Close")
    close.click = proc (f: ^ui.Frame) {
        events.open_screen({ screen_name="home" })
    }

    add_map_page()
    add_inv_page()
    add_crafting_page()
    add_research_page()
    add_skills_page()
    add_journey_page()
    add_customization_page()

    ui.click(screen.tabs, "inventory")
}

@private
add_customization_page :: proc () {
    _, page := partials.add_screen_tab_and_page(&screen, "customization", "CUSTOMIZATION")
    partials.add_placeholder_note(page, "CUSTOMIZATION PAGE GOES HERE...")
}
