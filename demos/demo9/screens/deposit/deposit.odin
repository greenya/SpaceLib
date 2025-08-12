package deposit

import "spacelib:ui"

import "../../data"
import "../../events"
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
    partials.set_container_state(&screen.backpack, data.player.backpack)

    screen.deposit = partials.add_container(screen.root, "DEPOSIT")
    ui.set_anchors(screen.deposit.root, { point=.center, offset={380,0} })
    partials.set_container_state(&screen.deposit, data.player.deposit)

    events.listen(.container_updated, container_updated_listener)
}

container_updated_listener :: proc (args: events.Args) {
    args := args.(events.Container_Updated)

    if args.container == screen.backpack.data   do partials.update_container_state(&screen.backpack)
    if args.container == screen.deposit.data    do partials.update_container_state(&screen.deposit)
}
