package demo9_screens_settings

import "core:fmt"
import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

@private screen: ^ui.Frame

add :: proc (parent: ^ui.Frame) {
    assert(screen == nil)

    screen = ui.add_frame(parent, { name="settings" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen_base(screen)

    partials.add_screen_footer_key_button(screen, "close", "Close", key="Esc",
        click=proc (f: ^ui.Frame) {
            events.send_open_screen("home")
        },
    )

    partials.add_screen_footer_key_button(screen, "reset_to_default", "Reset to Default", key="X")

    add_pages()

    ui.click(screen, "header_bar/tabs/gameplay")
}

@private
add_pages :: proc () {
    for p in data.get_settings_pages(context.temp_allocator) {
        _, page := partials.add_screen_tab_and_page(screen, p.page_name, p.page_title)

        items := data.get_settings_page_items(p.page_name)
        if len(items) > 0 {
            list := add_list_column(page)
            add_details_column(page, list)
            for i in items do add_list_column_item(list, i)
        } else {
            text := fmt.tprintf("%s section is empty in data/settings.json", p.page_title)
            partials.add_placeholder_note(page, text)
        }
    }
}

@private
add_list_column_item :: proc (list: ^ui.Frame, item: data.Settings_Item) {
    if item.group_name != "" {
        add_setting_header(list, item.group_name, item.group_title)
    } else {
        add_setting_card(list, item.name)
    }
}

@private
add_setting_header :: proc (list: ^ui.Frame, name, text: string) {
    ui.add_frame(list, {
        name    = name,
        flags   = {.terse,.terse_height},
        draw    = partials.draw_hexagon_rect,
        text    = fmt.tprintf("<left,pad=20:0,font=text_4l,color=primary_d2>%s", text),
    })
}

@private
add_setting_card :: proc (list: ^ui.Frame, name: string) {
    assert(name != "")

    item := data.get_settings_item(name)
    card_title := item.title != "" ? item.title : name

    card := ui.add_frame(list, {
        name = name,
        draw = partials.draw_setting_card,
        enter = set_details_column_content_from_card,
    })

    title := ui.add_frame(card,
        { name="title", size={250,0}, flags={.pass_self,.terse}, text=card_title,
            text_format="<wrap,left,font=text_4l,color=primary>%s" },
        { point=.top_left, offset={20,0} },
        { point=.bottom_left, offset={20,0} },
    )

    value := ui.add_frame(card,
        { name="value", flags={.pass_self} },
        { point=.top_left, rel_point=.top_right, rel_frame=title },
        { point=.bottom_right },
    )

    c := item.control

    switch len(c.names) {
    case 0      : // nothing
    case 2      : partials.add_control_radio_button_group(value, c.names, c.titles, c.default_idx)
    case 3, 4   : partials.add_control_radio_pins(value, c.names, c.titles, c.default_idx)
    case        : panic("Unexpected item.type format")
    }

    ui.set_continue_enter(value, check_blocking_flags=true)
}

@private
add_list_column :: proc (page: ^ui.Frame) -> ^ui.Frame {
    pad :: partials.screen_pad

    list := ui.add_frame(page,
        { name="list", size={560,0}, layout={dir=.down,size={0,80},pad=1,gap=15,scroll={step=20}}, flags={.scissor} },
        { point=.top_left, offset={1.5*pad,2*pad} },
        { point=.bottom_left, offset={1.5*pad,-2*pad} },
    )

    partials.add_scrollbar(list)

    return list
}

@private
add_details_column :: proc (page, list: ^ui.Frame) -> ^ui.Frame {
    pad :: partials.screen_pad
    track_offset :: 40

    details := ui.add_frame(page,
        { name="details", flags={.hidden} },
        { point=.top_left, rel_point=.top_right, rel_frame=list, offset={80,0} },
        { point=.bottom_right, offset={-1.5*pad-track_offset,-2*pad} },
    )

    title := ui.add_frame(details,
        { name="title", flags={.terse,.terse_height}, text_format="<wrap,left,font=text_6l,color=primary>%s" },
        { point=.top_left },
        { point=.top_right },
    )

    line := ui.add_frame(details,
        { name="line", size={0,2}, text="primary_d4", draw=partials.draw_gradient_fade_right_rect },
        { point=.top_left, rel_point=.bottom_left, rel_frame=title, offset={0,20} },
        { point=.top_right, rel_point=.bottom_right, rel_frame=title, offset={0,20} },
    )

    content := ui.add_frame(details,
        { name="content", layout={dir=.down,scroll={step=10}}, flags={.scissor} },
        { point=.top_left, rel_point=.bottom_left, rel_frame=line, offset={0,20} },
        { point=.top_right, rel_point=.bottom_right, rel_frame=line, offset={0,20} },
        { point=.bottom, rel_point=.bottom },
    )

    _, track, _ := partials.add_text_and_scrollbar(content)

    track.anchors[0].offset = {track_offset,0}
    track.anchors[1].offset = {track_offset,0}

    return details
}

@private
set_details_column_content_from_card :: proc (card: ^ui.Frame) {
    name := card.name
    assert(name != "")

    details := ui.get(card, "../../details")
    if details.text == name do return
    ui.set_text(details, name)

    item := data.get_settings_item(name)
    item_desc := data.get_settings_item_desc(name, context.temp_allocator)
    if item_desc != "" {
        ui.set_text(ui.get(details, "title"), item.title)
        ui.set_text(ui.get(details, "content/text"), item_desc)
        ui.set_scroll_offset(ui.get(details, "content"), 0)
        ui.show(details, repeat_refresh_rect=2)
    } else {
        ui.hide(details)
    }
}
