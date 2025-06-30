package demo9_partials

import "spacelib:ui"

add_screen :: proc (parent: ^ui.Frame) {
    add_header_bar(parent)
    add_footer_bar(parent)

    ui.add_frame(parent,
        { name="pages" },
        { point=.top_left, rel_point=.bottom_left, rel_frame=ui.get(parent, "header_bar") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=ui.get(parent, "footer_bar") },
    )
}

add_screen_tab_and_page :: proc (screen: ^ui.Frame, tab_name, tab_text, page_name: string) -> (tab, page: ^ui.Frame) {
    tab = ui.add_frame(ui.get(screen, "tabs"), {
        name        = tab_name,
        text        = tab_text,
        text_format = "<bottom,font=text_4l,pad=20:10>%s",
        flags       = {.no_capture,.radio,.terse,.terse_width},
        draw        = draw_screen_tab,
    })

    ui.add_frame(tab, {
        name        = "points",
        text_format = "<font=text_4l,color=bg0,pad=6:0>%i",
        size_min    = {32,0},
        flags       = {.hidden,.pass,.terse,.terse_width,.terse_height},
        draw        = draw_screen_tab_points,
    }, { point=.center, rel_point=.bottom, offset={0,6} })

    page = ui.add_frame(ui.get(screen, "pages"),
        { name=page_name, text="bg1" , draw=draw_color_rect },
        { point=.top_left },
        { point=.bottom_right },
    )

    return
}

@private
add_header_bar :: proc (parent: ^ui.Frame) {
    header_bar := ui.add_frame(parent,
        { name="header_bar", text="bg0", size={0,80}, order=1, draw=draw_color_rect },
        { point=.top_left },
        { point=.top_right },
    )

    tabs := ui.add_frame(header_bar,
        { name="tabs", layout={ dir=.left_and_right, auto_size=.dir } },
        { point=.top },
        { point=.bottom },
    )

    ui.add_frame(header_bar, {
        name    = "nav_left",
        text    = "<pad=6,font=text_4l,icon=key/Q>",
        flags   = {.terse,.terse_width,.terse_height},
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { ui.select_prev_child(ui.get(f.parent, "tabs")) },
    }, { point=.right, rel_point=.left, rel_frame=tabs, offset={-12,12} })

    ui.add_frame(header_bar, {
        name    = "nav_right",
        text    = "<pad=6,font=text_4l,icon=key/E>",
        flags   = {.terse,.terse_width,.terse_height},
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { ui.select_next_child(ui.get(f.parent, "tabs")) },
    }, { point=.left, rel_point=.right, rel_frame=tabs, offset={12,12} })
}

@private
add_footer_bar :: proc (parent: ^ui.Frame) {
    ui.add_frame(parent,
        { name="footer_bar", text="bg0", size={0,80}, order=1, draw=draw_color_rect },
        { point=.bottom_left },
        { point=.bottom_right },
    )
}
