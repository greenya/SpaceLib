#+private
package player

import "spacelib:ui"

import "../../data"
import "../../partials"

inv_page: struct {
    root: ^ui.Frame,

    backpack_container      : ^ui.Frame,
    backpack_solaris_text   : ^ui.Frame,
    backpack_slots_text     : ^ui.Frame,
    backpack_volume_text    : ^ui.Frame,
    backpack_slots          : ^ui.Frame,
}

add_inv_page :: proc () {
    _, inv_page.root = partials.add_screen_tab_and_page(&screen, "inventory", "INVENTORY")

    add_inv_backpack_panel()
}

add_inv_backpack_panel :: proc () {
    backpack := ui.add_frame(inv_page.root, {
        name="backpack",
        size={600,0},
        text="#0004",
        draw=partials.draw_color_rect,
    },
        { point=.top_left, offset={100,0} },
        { point=.bottom_left, offset={100,0} },
    )

    inv_page.backpack_container = partials.add_container(backpack, "BACKPACK")
    ui.set_anchors(inv_page.backpack_container, { point=.center })

    inv_page.backpack_slots = ui.get(inv_page.backpack_container, "slots/grid")

    backpack_header := ui.get(inv_page.backpack_container, "header")
    inv_page.backpack_solaris_text = ui.add_frame(backpack_header, {
        name="solaris",
        flags={.terse},
        text_format="<pad=10:0,right,font=text_4m,color=primary_l2,icon=two-coins> %i",
    },
        { point=.top_right },
        { point=.bottom_right },
    )

    inv_page.backpack_slots_text = ui.get(inv_page.backpack_container, "footer/slots/text")
    ui.set_text_format(inv_page.backpack_slots_text, "<font=text_4r,color=primary_l2> %i / %i")

    inv_page.backpack_volume_text = ui.get(inv_page.backpack_container, "footer/volume/text")
    ui.set_text_format(inv_page.backpack_volume_text, "<font=text_4r,color=primary_l2> %i / %i")

    inv_update_backpack_state()
}

inv_update_backpack_state :: proc () {
    solaris := data.container_item_count(data.player.backpack^, "solari")
    ui.set_text(inv_page.backpack_solaris_text, solaris)

    occupied_slots, max_slots, occupied_volume, max_volume := data.container_capacity(data.player.backpack^)
    ui.set_text(inv_page.backpack_slots_text, occupied_slots, max_slots)
    ui.set_text(inv_page.backpack_volume_text, int(occupied_volume), int(max_volume))

    bp_slots := inv_page.backpack_slots

    // add missing slots
    missing_slots := max_slots - len(bp_slots.children)
    for _ in 0..<missing_slots do partials.add_container_slot(inv_page.backpack_container)

    // hide unused slots
    for i in max_slots..<len(bp_slots.children) {
        bp_slots.children[i].flags += {.hidden}
        bp_slots.children[i].user_ptr = nil
    }

    // setup slots
    for &s, i in data.player.backpack.slots {
        bp_slots.children[i].flags -= {.hidden}
        bp_slots.children[i].user_ptr = &s
    }
}
