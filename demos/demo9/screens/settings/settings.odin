package settings

import "core:fmt"
import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

@private screen: partials.Screen

add :: proc (parent: ^ui.Frame) {
    screen = partials.add_screen(parent, "settings")

    close := partials.add_screen_key_button(&screen, "close", "<icon=key/Esc:1.4:1> Close")
    close.click = proc (f: ^ui.Frame) {
        events.open_screen({ screen_name="home" })
    }

    partials.add_screen_key_button(&screen, "reset_to_default", "<icon=key/X> Reset to Default")

    add_pages()

    ui.click(screen.tabs, "gameplay")
}

@private
add_pages :: proc () {
    for p in data.get_settings_pages(context.temp_allocator) {
        _, page := partials.add_screen_tab_and_page(&screen, p.page_id, p.page_title)

        items := data.get_settings_page_items(p.page_id)
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
add_list_column_item :: proc (list: ^ui.Frame, item: data.Setting) {
    if item.group_id != "" {
        add_setting_header(list, item.group_id, item.group_title)
    } else {
        add_setting_card(list, item.id)
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

    item := data.get_setting(name)
    card_title := item.title != "" ? item.title : name

    card := ui.add_frame(list, {
        name    = name,
        draw    = partials.draw_card_rect,
        enter   = set_details_column_content_from_card,
    })

    title := ui.add_frame(card,
        { name="title", size={250,0}, flags={.terse}, text=card_title,
            text_format="<wrap,left,font=text_4l,color=primary>%s" },
        { point=.top_left, offset={20,0} },
        { point=.bottom_left, offset={20,0} },
    )

    control := ui.add_frame(card,
        { name="control" },
        { point=.top_left, rel_point=.top_right, rel_frame=title },
        { point=.bottom_right },
    )

    add_setting_card_control(control, item)
}

@private
add_setting_card_control :: proc (parent: ^ui.Frame, item: data.Setting) {
    ic := item.control
    ia := item.control.appearance

    if ia == .auto do switch len(ic.names) {
    case 0      : // skip (expected)
    case 2      : ia = .button_group
    case 3,4,5  : ia = .pins
    case        : ia = .dropdown
    }

    switch ia {
    case .auto          : // skip (no control)
    case .button_group  : partials.add_control_radio_button_group(parent, ic.names, ic.titles, ic.default_idx)
    case .pins          : partials.add_control_radio_pins(parent, ic.names, ic.titles, ic.default_idx)
    case .dropdown      : partials.add_control_dropdown(parent, ic.names, ic.titles, ic.default_idx)
    case .slider        : partials.add_control_slider(parent, ic.min, ic.max, ic.default_val)
    }
}

@private
add_list_column :: proc (page: ^ui.Frame) -> ^ui.Frame {
    pad :: partials.screen_pad

    list := ui.add_frame(page,
        { name="list", size={560,0}, layout=ui.Flow{ dir=.down,size={0,80},pad=1,gap=15,scroll={step=30} }, flags={.scissor} },
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
        { name="content", layout=ui.Flow{ dir=.down,scroll={step=30} }, flags={.scissor} },
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

    item := data.get_setting(name)
    item_desc := data.text_to_string(item.desc, context.temp_allocator)
    if item_desc != "" {
        ui.set_text(ui.get(details, "title"), item.title)
        ui.set_text(ui.get(details, "content/text"), item_desc)
        ui.scroll_abs(ui.get(details, "content"), 0)
        ui.show(details)
    } else {
        ui.hide(details)
    }
}
