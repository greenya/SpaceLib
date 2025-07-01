package demo9_partials

import "core:fmt"
import "spacelib:ui"

add_screen_base :: proc (screen: ^ui.Frame) {
    add_header_bar(screen)
    add_footer_bar(screen)

    ui.add_frame(screen,
        { name="pages" },
        { point=.top_left, rel_point=.bottom_left, rel_frame=ui.get(screen, "header_bar") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=ui.get(screen, "footer_bar") },
    )
}

@private
add_header_bar :: proc (screen: ^ui.Frame) {
    header_bar := ui.add_frame(screen,
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
        name    = "nav_next",
        text    = "<pad=6,font=text_4l,icon=key/E>",
        flags   = {.hidden,.terse,.terse_width,.terse_height},
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { ui.select_next_child(ui.get(f.parent, "tabs")) },
    }, { point=.left, rel_point=.right, rel_frame=tabs, offset={12,12} })

    ui.add_frame(header_bar, {
        name    = "nav_prev",
        text    = "<pad=6,font=text_4l,icon=key/Q>",
        flags   = {.hidden,.terse,.terse_width,.terse_height},
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { ui.select_prev_child(ui.get(f.parent, "tabs")) },
    }, { point=.right, rel_point=.left, rel_frame=tabs, offset={-12,12} })
}

@private
add_footer_bar :: proc (screen: ^ui.Frame) {
    footer_bar := ui.add_frame(screen,
        { name="footer_bar", text="bg0", size={0,80}, order=1, draw=draw_color_rect },
        { point=.bottom_left },
        { point=.bottom_right },
    )

    ui.add_frame(footer_bar,
        { name="pyramid_buttons", layout={ dir=.right, align=.end, gap=20 } },
        { point=.bottom_left, offset={30,0} },
    )

    ui.add_frame(footer_bar,
        { name="key_buttons", layout={ dir=.left, align=.center, gap=6 } },
        { point=.right, offset={-30,0} },
    )
}

add_screen_tab_and_page :: proc (screen: ^ui.Frame, name, text: string) -> (tab, page: ^ui.Frame) {
    tab = ui.add_frame(ui.get(screen, "tabs"), {
        name        = name,
        text        = text,
        text_format = "<bottom,font=text_4l,pad=20:10>%s",
        flags       = {.no_capture,.radio,.terse,.terse_width},
        draw        = draw_screen_tab,
        click       = on_screen_tab_click,
    })

    ui.add_frame(tab, {
        name        = "points",
        text_format = "<font=text_4m,color=bg0,pad=6:0>%i",
        size_min    = {32,0},
        flags       = {.hidden,.pass,.terse,.terse_width,.terse_height},
        draw        = draw_screen_tab_points,
    }, { point=.center, rel_point=.bottom, offset={0,6} })

    page = ui.add_frame(ui.get(screen, "pages"),
        { name=name, text="bg1" , draw=draw_color_rect },
        { point=.top_left },
        { point=.bottom_right },
    )

    if len(tab.parent.children) > 1 {
        ui.show(ui.get(screen, "nav_next"))
        ui.show(ui.get(screen, "nav_prev"))
    }

    return
}

@private
on_screen_tab_click :: proc (f: ^ui.Frame) {
    page := ui.get(f, fmt.tprintf("../../../pages/%s", f.name))
    ui.show(page, hide_siblings=true)
}

add_screen_footer_pyramid_button :: proc (screen: ^ui.Frame, name, text: string) -> ^ui.Frame {
    button := ui.add_frame(ui.get(screen, "footer_bar/pyramid_buttons"), {
        name    = name,
        size    = {250,125},
        draw    = draw_pyramid_button,
    })

    ui.add_frame(button, {
        name    = "title",
        text    = fmt.tprintf("<pad=6:0,font=text_4r,color=primary> %s", text),
        flags   = {.pass_self,.terse,.terse_width,.terse_height},
        draw    = draw_pyramid_button_title,
    }, { point=.center, rel_point=.bottom, offset={0,-80} })

    return button
}

add_screen_footer_key_button :: proc (screen: ^ui.Frame, name, text, key: string) -> ^ui.Frame {
    assert(len(key) == 1 || len(key) == 3 || len(key) == 6) // "H", "Esc", "L.Ctrl"
    key_width_ratios := [] string { "?", "1", "?", "1.4", "?", "?", "2" }
    key_width_ratio := key_width_ratios[len(key)]
    return ui.add_frame(ui.get(screen, "footer_bar/key_buttons"), {
        name    = name,
        text    = fmt.tprintf("<pad=12:6,font=text_4l,color=primary,icon=key/%s:%s:1> %s", key, key_width_ratio, text),
        flags   = {.terse,.terse_width,.terse_height},
        draw    = draw_button,
    })
}
