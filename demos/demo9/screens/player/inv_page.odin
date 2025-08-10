#+private
package player

import "spacelib:core"
import "spacelib:ui"

import "../../data"
import "../../partials"

inv_page: struct {
    root: ^ui.Frame,

    backpack: struct {
        using container : partials.Container,
        solaris_text    : ^ui.Frame,
    },
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

    inv_page.backpack.container = partials.add_container(backpack, "BACKPACK")
    ui.set_anchors(inv_page.backpack.root, { point=.center })

    inv_page.backpack.solaris_text = ui.add_frame(inv_page.backpack.header, {
        name="solaris",
        flags={.terse},
        text_format="<pad=10:0,right,font=text_4m,color=primary_l2,icon=two-coins> %s",
    },
        { point=.top_right },
        { point=.bottom_right },
    )

    ui.set_text_format(inv_page.backpack.footer_slots_text, "<font=text_4r,color=primary_l2> %i / %i")
    ui.set_text_format(inv_page.backpack.footer_volume_text, "<font=text_4r,color=primary_l2> %i / %i")

    ui.update(inv_page.backpack.root)

    inv_update_backpack_state()
}

inv_update_backpack_state :: proc () {
    partials.set_container_state(&inv_page.backpack, data.player.backpack)

    solaris := data.container_item_count(data.player.backpack^, "solari")
    solaris_text := core.format_int(solaris, allocator=context.temp_allocator)
    ui.set_text(inv_page.backpack.solaris_text, solaris_text)
}
