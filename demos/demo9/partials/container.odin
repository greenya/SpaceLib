package partials

import "core:fmt"

import "spacelib:core"
import "spacelib:ui"

import "../data"
import "../events"

Container :: struct {
    root                : ^ui.Frame,
    data                : ^data.Container,

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
    drag_slot           : ^ui.Frame,
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

    con.drag_slot = ui.add_frame(parent, {
        order=9,
        name="container_drag_slot",
        flags={.pass,.hidden},
        draw=draw_container_slot,
    },
        { point=.center, rel_point=.mouse },
    )

    return con
}

set_container_state :: proc (con: ^Container, con_data: ^data.Container) {
    con.data = con_data
    ui.set_user_ptr(con.root, con)

    occupied_slots, max_slots, occupied_volume, max_volume := data.container_capacity(con.data^)

    ui.set_text(con.slots_text, occupied_slots, max_slots)
    ui.set_text(con.volume_text, int(occupied_volume), int(max_volume))
    ui.set_text(con.volume_bar_arrow, int(occupied_volume))

    {
        solaris := data.container_item_count(con.data^, "solari")
        if solaris > 0 {
            solaris_text := core.format_int(solaris, allocator=context.temp_allocator)
            ui.set_text(con.solaris_text, solaris_text, shown=true)
        } else {
            ui.hide(con.solaris_text)
        }
    }

    {
        vol_bar_h := con.volume_bar.rect.h
        con.volume_ratio = occupied_volume / max_volume
        con.volume_bar_arrow.anchors[0].offset.y = -2 -(vol_bar_h-4) * con.volume_ratio
        ui.set_user_ptr(con.volume_bar, con)
    }

    ui.destroy_frame_children(con.slots)
    for _, i in con.data.slots do add_container_slot(con, i)

    ui.set_user_ptr(con.drag_slot, con)
    con.drag_slot.user_idx = -1

    ui.update(con.root)
}

update_container_state :: proc (con: ^Container) {
    assert(con.data != nil)
    set_container_state(con, con.data)
}

@private
add_container_slot :: proc (con: ^Container, slot_idx: int) {
    slot_data := &con.data.slots[slot_idx]

    slot := ui.add_frame(con.slots, {
        name        = "slot",
        flags       = slot_data.item != nil ? {.capture} : {},
        user_idx    = slot_idx,
        draw        = draw_container_slot,
        drag        = proc (f: ^ui.Frame, info: ui.Drag_Info) {
            // fmt.println("[drag]", f.user_idx)
            con := ui.get_user_ptr(f, ^Container)
            #partial switch info.phase {
            case .start:
                con.drag_slot.user_idx = f.user_idx
                con.drag_slot.size = { f.rect.w, f.rect.h }
                ui.show(con.drag_slot)

            case .end:
                con.drag_slot.user_idx = -1
                ui.hide(con.drag_slot)

                con_target := ui.get_user_ptr(info.target, ^Container)
                if con_target != nil && info.target.name == "slot" {
                    container_swap_slots(con, f.user_idx, con_target, info.target.user_idx)
                }
            }
        },
    })

    ui.set_user_ptr(slot, con)
}

@private
container_swap_slots :: proc (con_from: ^Container, idx_from: int, con_to: ^Container, idx_to: int) {
    result := data.container_swap_slots(con_from.data, idx_from, con_to.data, idx_to)
    fmt.println(#procedure, result)
    switch result {
    case .success:
        events.container_updated({ container=con_from.data })
        if con_from != con_to {
            events.container_updated({ container=con_to.data })
        }
    case .error_not_enough_volume:
        events.push_notification({
            type    = .error,
            title   = "INVENTORY",
            text    = "Not enough free volume to store more items.",
        })
    case .error_bad_slot_idx, .error_src_slot_is_empty:
        panic("Something is not right here")
    }
}
