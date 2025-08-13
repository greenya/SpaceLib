#+private
package player

import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

inv_page: struct {
    root        : ^ui.Frame,

    help_button : ^ui.Frame,

    backpack    : partials.Container,
}

add_inv_page :: proc () {
    _, inv_page.root = partials.add_screen_tab_and_page(&screen, "inventory", "INVENTORY")

    inv_page.help_button = partials.add_screen_key_button(&screen, "help", "<icon=key/H> Help")
    inv_page.help_button.click = proc (f: ^ui.Frame) {
        events.open_modal({ target=f, instruction_id="player/inventory/help" })
    }

    inv_page.root.show = proc (f: ^ui.Frame) {
        ui.show(inv_page.help_button)
    }

    inv_page.root.hide = proc (f: ^ui.Frame) {
        ui.hide(inv_page.help_button)
    }

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
