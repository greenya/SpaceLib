#+private
package player

import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

inv_page: struct {
    root    : ^ui.Frame,
    backpack: partials.Container,
}

add_inv_page :: proc () {
    _, inv_page.root = partials.add_screen_tab_and_page(&screen, "inventory", "INVENTORY")

    add_inv_backpack_panel()
}

add_inv_backpack_panel :: proc () {
    column := ui.add_frame(inv_page.root, {
        name="backpack",
        size={600,0},
        text="#0004",
        draw=partials.draw_color_rect,
    },
        { point=.top_left, offset={100,0} },
        { point=.bottom_left, offset={100,0} },
    )

    inv_page.backpack = partials.add_container(column, "BACKPACK")
    ui.set_anchors(inv_page.backpack.root, { point=.center })
    partials.set_container_state(&inv_page.backpack, data.player.backpack)

    events.listen(.container_updated, container_updated_listener)
}

container_updated_listener :: proc (args: events.Args) {
    args := args.(events.Container_Updated)
    if args.container == inv_page.backpack.data {
        partials.update_container_state(&inv_page.backpack)
    }
}
