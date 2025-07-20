package partials

import "spacelib:ui"

import "../events"

add_button :: proc (parent: ^ui.Frame, name, text: string, flags: bit_set [ui.Flag] = {}) -> ^ui.Frame {
    return ui.add_frame(parent, {
        name        = name,
        text        = text,
        text_format = "<pad=12:6,font=text_4l,color=primary>%s",
        flags       = flags | {.capture,.terse,.terse_size},
        draw        = draw_button,
    })
}

add_text_and_scrollbar :: proc (target: ^ui.Frame) -> (text, track, thumb: ^ui.Frame) {
    text = ui.add_frame(target, {
        name="text",
        flags={.terse,.terse_height},
        text_format="<wrap,left,font=text_4l,color=primary>%s",
    })

    track, thumb = add_scrollbar(target)

    return
}

add_scrollbar :: proc (target: ^ui.Frame) -> (track, thumb: ^ui.Frame) {
    assert(target.parent != nil)
    assert(.scissor in target.flags)

    track = ui.add_frame(target.parent,
        { name="track", size={1,0}, draw=draw_scrollbar_track },
        { point=.top_left, rel_point=.top_right, rel_frame=target, offset={10,0} },
        { point=.bottom_left, rel_point=.bottom_right, rel_frame=target, offset={10,0} },
    )

    thumb = ui.add_frame(track,
        { name="thumb", flags={.capture}, size={19,60}, draw=draw_scrollbar_thumb },
        { point=.top },
    )

    ui.setup_scrollbar_actors(target, thumb)

    return
}

add_control_radio_button_group :: proc (parent: ^ui.Frame, names, titles: [] string, default_idx := 0) {
    assert(len(names) > 0 )
    assert(len(names) > default_idx)
    assert(len(names) == len(titles))

    parent.layout = ui.Flow { dir=.left_and_right, size={120,40}, align=.center }

    for name, i in names {
        ui.add_frame(parent, {
            name    = name,
            text    = titles[i],
            flags   = {.radio},
            draw    = draw_button_radio_with_text,
        })
    }

    ui.click(parent.children[default_idx])
}

add_control_radio_pins :: proc (parent: ^ui.Frame, names, titles: [] string, default_idx := 0) {
    assert(len(names) > 0 )
    assert(len(names) > default_idx)
    assert(len(names) == len(titles))

    ui.add_frame(parent,
        { name="title", flags={.terse,.terse_height}, text_format="<wrap,bottom,font=text_4l,color=primary_d2>%s" },
        { point=.top_left },
        { point=.bottom_right, rel_point=.right },
    )

    pin_pad :: 8
    pin_w :: 36
    pin_h :: 12

    pins := ui.add_frame(parent,
        { name="pins", layout=ui.Flow{ dir=.left_and_right,gap=4,pad=pin_pad } },
        { point=.top_left, rel_point=.left },
        { point=.bottom_right },
    )

    for name, i in names {
        ui.add_frame(pins, {
            name    = name,
            text    = titles[i],
            size    = {pin_w,pin_h},
            flags   = {.radio},
            draw    = draw_button_radio_pin,
            click   = proc (f: ^ui.Frame) {
                title := ui.get(f, "../../title")
                ui.set_text(title, f.text)
            },
        })
    }

    nav_offset_y :: pin_pad + pin_h/2

    ui.add_frame(parent, {
        name    = "nav_next",
        text    = "arrow_forward",
        size    = 24,
        draw    = draw_button_radio_pin_nav,
        click   = proc (f: ^ui.Frame) { ui.select_next_child(ui.get(f.parent, "pins")) },
    }, { point=.right, rel_point=.right, offset={-20,nav_offset_y} })

    ui.add_frame(parent, {
        name    = "nav_prev",
        text    = "arrow_back",
        size    = 24,
        draw    = draw_button_radio_pin_nav,
        click   = proc (f: ^ui.Frame) { ui.select_prev_child(ui.get(f.parent, "pins")) },
    }, { point=.left, rel_point=.left, offset={20,nav_offset_y} })

    ui.click(pins.children[default_idx])
}

add_control_radio_dropdown :: proc (parent: ^ui.Frame, names, titles: [] string, default_idx := 0) {
    assert(len(names) > 0 )
    assert(len(names) > default_idx)
    assert(len(names) == len(titles))

    arrow_w :: 20

    button := ui.add_frame(parent, {
        name    = "button",
        flags   = {.check},
        draw    = draw_button_dropdown_button,
        click   = proc (f: ^ui.Frame) {
            if f.selected   do events.open_dropdown({ target=f })
            else            do events.close_dropdown({ target=f })
        },
    }, { point=.top_left, offset=20 }, { point=.bottom_right, offset=-20 })

    selected := ui.add_frame(button, {
        flags       = {.pass_self,.terse,.terse_height},
        text_format = "<wrap,left,font=text_4l,color=primary_d2>%s",
    }, { point=.left, offset={15,0} }, { point=.right, offset={-20-arrow_w,0} })

    ui.set_name(selected, names[default_idx])
    ui.set_text(selected, titles[default_idx])

    events.set_dropdown_data({ target=button, selected=selected, names=names, titles=titles })
}

Category_Tab_Details :: struct {
    name: string,
    icon: string,
}

add_category_tabs :: proc (parent: ^ui.Frame, name: string, items: [] Category_Tab_Details, click: ui.Frame_Proc = nil) -> ^ui.Frame {
    tabs := ui.add_frame(parent, {
        name    = name,
        layout  = ui.Flow { dir=.right, gap=20, auto_size=.dir, align=.center },
    })

    ensure(len(items) > 0 && len(items) < 10)
    // tabs.children order layout:
    //      -2: bg_line
    //      -1: prev
    //    0..9: items
    //      11: next
    //      12: title

    for d, i in items do ui.add_frame(tabs, {
        name        = d.name,
        text        = d.icon,
        order       = i,
        flags       = {.radio,.capture},
        size        = 64,
        click       = click,
        draw        = draw_button_diamond,
    })

    nav_button_flags := bit_set [ui.Flag] {.capture,.terse,.terse_size}
    if len(items) < 2 do nav_button_flags += { .hidden }

    ui.add_frame(tabs, {
        name    = "prev",
        flags   = nav_button_flags,
        order   = -1,
        text    = "<pad=8,font=text_4l,icon=key/Z>",
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { ui.select_prev_child(f.parent, allow_rotation=true) },
    })

    ui.add_frame(tabs, {
        name    = "next",
        flags   = nav_button_flags,
        order   = 11,
        text    = "<pad=8,font=text_4l,icon=key/C>",
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { ui.select_next_child(f.parent, allow_rotation=true) },
    })

    ui.add_frame(tabs, {
        name        = "title",
        flags       = {.terse,.terse_size},
        order       = 12,
        text_format = "<pad=12:0,font=text_4m>%s",
        text        = "TITLE",
        draw        = draw_label_box,
    })

    ui.add_frame(tabs, {
        name    = "bg_line",
        order   = -2,
        size    = {0,2},
        flags   = {.pass},
        text    = "primary_d4",
        draw    = draw_color_rect,
    },
        { point=.left, rel_point=.center, rel_frame=ui.get(tabs, "prev") },
        { point=.right, rel_point=.center, rel_frame=ui.get(tabs, "title") },
    )

    return tabs
}
