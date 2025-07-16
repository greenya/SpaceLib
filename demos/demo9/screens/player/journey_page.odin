#+private
package player

import "spacelib:ui"

import "../../partials"

add_journey_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "journey", "JOURNEY")
    partials.add_placeholder_note(page, "JOURNEY PAGE GOES HERE...")

    tabs := partials.add_category_tabs(page, {
        { name="story", text="STORY", icon="settings" },
        { name="contract", text="CONTRACT", icon="settings" },
        { name="codex", text="CODEX", icon="settings" },
        { name="tutorial", text="TUTORIAL", icon="settings" },
    })

    ui.set_anchors(tabs, { point=.top_left, offset={80,70} })
}
