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

add_button_small_icon :: proc (parent: ^ui.Frame, name, icon: string, size: f32) -> ^ui.Frame {
    return ui.add_frame(parent, {
        name    = name,
        text    = icon,
        size    = size,
        draw    = draw_button_small_icon,
    })
}

add_text_and_scrollbar :: proc (target: ^ui.Frame) -> (text, track, thumb: ^ui.Frame) {
    text = ui.add_frame(target, {
        name="text",
        flags={.terse,.terse_height,.terse_shrink},
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

add_control_dropdown :: proc (parent: ^ui.Frame, names, titles: [] string, current_idx := 0) {
    assert(len(names) > 0 )
    assert(len(names) > current_idx)
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

    ui.set_name(selected, names[current_idx])
    ui.set_text(selected, titles[current_idx])

    events.set_dropdown_data({ target=button, selected=selected, names=names, titles=titles })
}

add_control_radio_button_group :: proc (parent: ^ui.Frame, names, titles: [] string, current_idx := 0) {
    assert(len(names) > 0 )
    assert(len(names) > current_idx)
    assert(len(names) == len(titles))

    parent.layout = ui.Flow { dir=.right_center, size={124,40}, align=.center }

    for name, i in names {
        ui.add_frame(parent, {
            name    = name,
            text    = titles[i],
            flags   = {.radio},
            draw    = draw_button_radio_with_text,
        })
    }

    ui.click(parent.children[current_idx])
}

add_control_radio_pins :: proc (parent: ^ui.Frame, names, titles: [] string, current_idx := 0) {
    assert(len(names) > 0 )
    assert(len(names) > current_idx)
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
        { name="pins", layout=ui.Flow{ dir=.right_center,gap=4,pad=pin_pad } },
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

    next := add_button_small_icon(parent, name="next", icon="arrow_forward", size=24)
    ui.set_anchors(next, { point=.right, rel_point=.right, offset={-20,nav_offset_y} })
    next.click = proc (f: ^ui.Frame) {
        ui.select_next_child(ui.get(f.parent, "pins"))
    }

    prev := add_button_small_icon(parent, name="prev", icon="arrow_back", size=24)
    ui.set_anchors(prev, { point=.left, rel_point=.left, offset={20,nav_offset_y} })
    prev.click = proc (f: ^ui.Frame) {
        ui.select_prev_child(ui.get(f.parent, "pins"))
    }

    ui.click(pins.children[current_idx])
}

add_control_slider :: proc (parent: ^ui.Frame, total, idx: int, thumb_click: ui.Frame_Proc) {
    assert(total > 1 && idx >= 0 && idx < total)

    ui.add_frame(parent,
        { name="value", flags={.terse,.terse_height}, text="???", text_format="<wrap,bottom,font=text_4l,color=primary_d2>%s" },
        { point=.top_left },
        { point=.bottom_right, rel_point=.right },
    )

    track := ui.add_frame(parent, {
        name = "track",
        size = {166,4},
        draw = total <= 6 ? draw_slider_track_with_marks : draw_slider_track,
    },
        { point=.top, rel_point=.center, offset={0,10} },
    )

    thumb := ui.add_frame(track, {
        name    = "thumb",
        flags   = {.capture},
        size    = 24,
        draw    = draw_slider_thumb,
        click   = thumb_click,
    },
        { point=.center, rel_point=.left },
    )

    next := add_button_small_icon(parent, name="next", icon="arrow_forward", size=24)
    ui.set_anchors(next, { point=.left, rel_point=.right, rel_frame=track, offset={16,0} })

    prev := add_button_small_icon(parent, name="prev", icon="arrow_back", size=24)
    ui.set_anchors(prev, { point=.right, rel_point=.left, rel_frame=track, offset={-16,0} })

    ui.setup_slider_actors({ total=total, idx=idx }, thumb, next, prev)
}

Category_Tab_Details :: struct {
    name: string,
    icon: string,
}

add_category_tabs :: proc (parent: ^ui.Frame, name: string, items: [] Category_Tab_Details, click: ui.Frame_Proc = nil) -> ^ui.Frame {
    tabs := ui.add_frame(parent, {
        name    = name,
        layout  = ui.Flow { dir=.right, gap=20, auto_size={.width}, align=.center },
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

add_panel_header :: proc (parent: ^ui.Frame, text, icon: string) -> ^ui.Frame {
    row := ui.add_frame(parent, {
        name="header",
        size={0,40},
        text="#0008",
        draw=draw_color_rect_with_primary_border,
        layout=ui.Flow{ dir=.right, pad=2, align=.center },
    })

    ui.add_frame(row, {
        name="icon",
        text=icon,
        size_aspect=1,
        draw=draw_icon_box_fill_primary,
    })

    ui.add_frame(row, {
        name="text",
        flags={.terse,.terse_size},
        text=text,
        text_format="<left,pad=10:0,font=text_4m,color=primary_d2>%s",
        draw=draw_text_drop_shadow,
    })

    return row
}

add_progress_bar :: proc (parent: ^ui.Frame, title: string, progress_ratio: f32) -> ^ui.Frame {
    progress_bar := ui.add_frame(parent, {
        name="progress_bar",
        layout=ui.Flow{ dir=.down, auto_size={.height} },
    })

    title := ui.add_frame(progress_bar, {
        name="title",
        flags={.terse,.terse_height},
        text=title,
        text_format="<left,font=text_4l,color=primary>%s",
        draw=draw_text_drop_shadow,
    })

    text := ui.add_frame(progress_bar, {
        name="text",
        flags={.terse,.terse_size},
        text_format="<left,font=text_4m,color=primary>%i%%",
        draw=draw_text_drop_shadow,
    },
        {point=.right,rel_frame=title},
    )

    ui.set_text(text, int(progress_ratio*100))

    bar := ui.add_frame(progress_bar, {
        name="bar",
        size={0,10},
        layout=ui.Flow{ dir=.right },
        text="#0006",
        draw=draw_color_rect,
    })

    ui.add_frame(bar, {
        name="fill",
        size_ratio={.001+progress_ratio,0},
        text="progress",
        draw=draw_color_rect,
    })

    return progress_bar
}

add_chevron_label :: proc (parent: ^ui.Frame, name, icon: string, text := "") -> ^ui.Frame {
    label := ui.add_frame(parent, {
        name=name,
        text=icon,
        size={130,30},
        draw=draw_chevron_label_rect,
    })

    ui.add_frame(label, {
        name="text",
        flags={.terse},
    },
        { point=.top_left, offset={40,0} },
        { point=.bottom_right },
    )

    return label
}
