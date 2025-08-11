package partials

import "spacelib:core"
import "spacelib:ui"

import "../data"

Container :: struct {
    root                : ^ui.Frame,

    header              : ^ui.Frame,
    footer              : ^ui.Frame,

    title_icon          : ^ui.Frame,
    title_text          : ^ui.Frame,
    solaris_text        : ^ui.Frame,
    slots_text          : ^ui.Frame,
    volume_text         : ^ui.Frame,

    volume_bar          : ^ui.Frame,
    volume_bar_arrow    : ^ui.Frame,
    volume_ratio        : f32,

    slots               : ^ui.Frame,
}

add_container :: proc (parent: ^ui.Frame, title: string) -> Container {
    con: Container

    con.root = ui.add_frame(parent, {
        name="container",
        size={600,710},
        text="#0004",
        draw=draw_color_rect,
    })

    con.header = add_panel_header(con.root, title, icon="inventory_2")
    ui.set_anchors(con.header,
        { point=.top_left, offset=10 },
        { point=.top_right, offset={-10,10} },
    )

    con.title_icon = ui.get(con.header, "icon")
    con.title_text = ui.get(con.header, "text")

    con.solaris_text = ui.add_frame(con.header, {
        name="solaris",
        flags={.terse},
        text_format="<pad=10:0,right,font=text_4m,color=primary_l2,icon=two-coins> %s",
    },
        { point=.top_right },
        { point=.bottom_right },
    )

    con.footer = ui.add_frame(con.root, {
        name="footer",
        size={0,40},
        layout=ui.Flow{ dir=.left, gap=10, align=.center },
    },
        { point=.bottom_left, offset={10,-10} },
        { point=.bottom_right, offset=-10 },
    )

    _, con.volume_text = add_chevron_label(con.footer,
        name="volume",
        icon="deployed_code",
        text_format="<font=text_4r,color=primary_l2> %i / %i",
    )

    _, con.slots_text = add_chevron_label(con.footer,
        name="slots",
        icon="view_cozy",
        text_format="<font=text_4r,color=primary_l2> %i / %i",
    )

    // we only add this flow frame to have scroll;
    // maybe when Grid has own scroll we don't need it
    flow := ui.add_frame(con.root, {
        name="flow",
        flags={.scissor},
        layout=ui.Flow{ dir=.down, scroll={step=30} },
    },
        { point=.top_left, rel_point=.bottom_left, rel_frame=con.header, offset={0,15} },
        { point=.bottom_right, rel_point=.top_right, rel_frame=con.footer, offset={0,-15} },
    )

    con.slots = ui.add_frame(flow, {
        name="slots",
        layout=ui.Grid{ dir=.right_down, wrap=5, aspect=1, gap=15, auto_size={.height} },
    })

    add_scrollbar(flow)

    con.volume_bar = ui.add_frame(con.root, {
        name="volume_bar",
        size={16,0},
        draw=draw_container_volume_bar,
    },
        { point=.top_right, rel_point=.top_left, rel_frame=flow, offset={-10,0} },
        { point=.bottom_right, rel_point=.bottom_left, rel_frame=flow, offset={-10,0} },
    )

    con.volume_bar_arrow = ui.add_frame(con.volume_bar, {
        name="arrow",
        size={64,32},
        text_format="%iv",
        draw=draw_container_volume_bar_arrow,
    },
        { point=.right, rel_point=.bottom_left, offset={10,0} },
    )

    return con
}

set_container_state :: proc (con: ^Container, data_con: ^data.Container) {
    occupied_slots, max_slots, occupied_volume, max_volume := data.container_capacity(data_con^)

    ui.set_text(con.slots_text, occupied_slots, max_slots)
    ui.set_text(con.volume_text, int(occupied_volume), int(max_volume))
    ui.set_text(con.volume_bar_arrow, int(occupied_volume))

    solaris := data.container_item_count(data_con^, "solari")
    if solaris > 0 {
        solaris_text := core.format_int(solaris, allocator=context.temp_allocator)
        ui.set_text(con.solaris_text, solaris_text, shown=true)
    } else {
        ui.hide(con.solaris_text)
    }

    {
        vol_bar_h := con.volume_bar.rect.h
        con.volume_ratio = occupied_volume / max_volume
        con.volume_bar.user_ptr = &con.volume_ratio
        con.volume_bar_arrow.anchors[0].offset.y = -2 -(vol_bar_h-4) * con.volume_ratio
    }

    // add missing slots
    missing_slots := max_slots - len(con.slots.children)
    for _ in 0..<missing_slots do ui.add_frame(con.slots, { name="slot", draw=draw_container_slot })

    // hide unused slots
    for i in max_slots..<len(con.slots.children) {
        con.slots.children[i].flags += {.hidden}
        con.slots.children[i].user_ptr = nil
    }

    // setup slots
    for &s, i in data_con.slots {
        con.slots.children[i].flags -= {.hidden}
        con.slots.children[i].user_ptr = &s
    }
}
