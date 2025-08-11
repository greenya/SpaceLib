package deposit

import "spacelib:ui"

import "../../data"
import "../../partials"

@private screen: struct {
    using screen: partials.Screen,

    backpack    : partials.Container,
    deposit     : partials.Container,
}

add :: proc (parent: ^ui.Frame) {
    screen.screen = partials.add_screen(parent, "deposit", is_empty=true)

    ui.add_frame(screen.root,
        { name="icon", size=64, text="compare_arrows", draw=partials.draw_icon_primary },
        { point=.center },
    )

    screen.backpack = partials.add_container(screen.root, "BACKPACK")
    ui.set_anchors(screen.backpack.root, { point=.center, offset={-380,0} })

    screen.deposit = partials.add_container(screen.root, "DEPOSIT")
    ui.set_anchors(screen.deposit.root, { point=.center, offset={380,0} })

    update_state()

    // ui.print_frame_tree(screen.root)
}

@private
update_state :: proc () {
    partials.set_container_state(&screen.backpack, data.player.backpack)
    partials.set_container_state(&screen.deposit, data.player.deposit)
}
