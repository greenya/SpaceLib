package demo9_partials

import "spacelib:ui"

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

    parent.layout = { dir=.left_and_right, size={120,40}, align=.center }

    for name, i in names {
        ui.add_frame(parent, {
            name    = name,
            text    = titles[i],
            flags   = {.radio,.continue_enter},
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
        { name="title", flags={.pass_self,.terse,.terse_height}, text_format="<wrap,bottom,font=text_4l,color=primary_d2>%s" },
        { point=.top_left },
        { point=.bottom_right, rel_point=.right },
    )

    pin_pad :: 8
    pin_h :: 12

    pins := ui.add_frame(parent,
        { name="pins", layout={dir=.left_and_right,gap=4,pad=pin_pad} },
        { point=.top_left, rel_point=.left },
        { point=.bottom_right },
    )

    for name, i in names {
        ui.add_frame(pins, {
            name    = name,
            text    = titles[i],
            size    = {40,pin_h},
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
