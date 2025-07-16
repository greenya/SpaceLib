#+private
package player

import "spacelib:ui"

import "../../partials"

add_map_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "map", "MAP")
    partials.add_placeholder_note(page, "MAP PAGE GOES HERE...")

    map_filter := partials.add_screen_pyramid_button(screen, "map_filter", "<icon=key_tiny/F:.7> FILTER", icon="visibility")
    ui.set_order(map_filter, -2)

    map_legend := partials.add_screen_pyramid_button(screen, "map_legend", "<icon=key_tiny/L:.7> LEGEND", icon="view_cozy")
    ui.set_order(map_legend, -1)

    page.show = proc (f: ^ui.Frame) {
        partials.move_screen_pyramid_buttons(screen, .left)
        ui.show(screen, "footer_bar/pyramid_buttons/map_filter")
        ui.show(screen, "footer_bar/pyramid_buttons/map_legend")
    }

    page.hide = proc (f: ^ui.Frame) {
        partials.move_screen_pyramid_buttons(screen, .center)
        ui.hide(screen, "footer_bar/pyramid_buttons/map_filter")
        ui.hide(screen, "footer_bar/pyramid_buttons/map_legend")
    }
}
