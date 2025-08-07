package partials

import "spacelib:ui"

add_container :: proc (parent: ^ui.Frame, title: string) -> (container: ^ui.Frame) {
    container = ui.add_frame(parent, {
        name="container",
        size={600,720},
        text="#0004",
        draw=draw_color_rect,
    })

    header := add_panel_header(container, title, icon="inventory_2")
    ui.set_anchors(header,
        { point=.top_left, offset=10 },
        { point=.top_right, offset={-10,10} },
    )

    footer := ui.add_frame(container, {
        name="footer",
        size={0,40},
        layout=ui.Flow{ dir=.left, gap=10, align=.center },
    },
        { point=.bottom_left, offset={10,-10} },
        { point=.bottom_right, offset=-10 },
    )

    add_chevron_label(footer, name="volume", icon="deployed_code")
    add_chevron_label(footer, name="slots", icon="view_cozy")

    // we only add this flow frame to have scroll;
    // maybe when Grid has own scroll we don't need it
    slots := ui.add_frame(container, {
        name="slots",
        flags={.scissor},
        layout=ui.Flow{ dir=.down, scroll={step=30} },
    },
        { point=.top_left, rel_point=.bottom_left, rel_frame=header, offset={0,15} },
        { point=.bottom_right, rel_point=.top_right, rel_frame=footer, offset={0,-15} },
    )

    ui.add_frame(slots, {
        name="grid",
        layout=ui.Grid{ dir=.right_down, wrap=5, aspect=1, gap=15, auto_size={.height} },
    })

    add_scrollbar(slots)

    return
}

add_container_slot :: proc (container: ^ui.Frame) {
    ui.add_frame(ui.get(container, "slots/grid"), {
        name="slot",
        draw=draw_container_slot,
    })
}
