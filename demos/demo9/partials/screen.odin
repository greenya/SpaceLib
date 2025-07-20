package partials

import "core:fmt"
import "spacelib:ui"

screen_pad :: 50

add_screen :: proc (parent: ^ui.Frame, name: string, is_empty := false) -> ^ui.Frame {
    screen := ui.add_frame(parent,
        { name=name, flags={.hidden} },
        { point=.top_left },
        { point=.bottom_right },
    )

    if !is_empty {
        add_screen_header_bar(screen)
        add_screen_footer_bar(screen)
        ui.add_frame(screen,
            { name="pages" },
            { point=.top_left, rel_point=.bottom_left, rel_frame=ui.get(screen, "header_bar") },
            { point=.bottom_right, rel_point=.top_right, rel_frame=ui.get(screen, "footer_bar") },
        )
    }

    return screen
}

@private
add_screen_header_bar :: proc (screen: ^ui.Frame) {
    header_bar := ui.add_frame(screen,
        { name="header_bar", text="bg0", size={0,80}, order=1, draw=draw_color_rect },
        { point=.top_left },
        { point=.top_right },
    )

    tabs := ui.add_frame(header_bar,
        { name="tabs", layout=ui.Flow{ dir=.left_and_right, auto_size=.dir } },
        { point=.top },
        { point=.bottom },
    )

    ui.add_frame(header_bar, {
        name    = "nav_next_tab",
        text    = "<pad=8,font=text_4l,icon=key/E>",
        flags   = {.hidden,.capture,.terse,.terse_size},
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { ui.select_next_child(ui.get(f.parent, "tabs"), allow_rotation=true) },
    }, { point=.left, rel_point=.right, rel_frame=tabs, offset={12,12} })

    ui.add_frame(header_bar, {
        name    = "nav_prev_tab",
        text    = "<pad=8,font=text_4l,icon=key/Q>",
        flags   = {.hidden,.capture,.terse,.terse_size},
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { ui.select_prev_child(ui.get(f.parent, "tabs"), allow_rotation=true) },
    }, { point=.right, rel_point=.left, rel_frame=tabs, offset={-12,12} })
}

@private
add_screen_footer_bar :: proc (screen: ^ui.Frame) {
    footer_bar := ui.add_frame(screen,
        { name="footer_bar", text="bg0", size={0,80}, order=1, draw=draw_color_rect },
        { point=.bottom_left },
        { point=.bottom_right },
    )

    ui.add_frame(footer_bar,
        { name="pyramid_buttons", layout=ui.Flow{ dir=.right, align=.end, gap=20 } },
    )

    move_screen_pyramid_buttons(screen, .left)

    ui.add_frame(footer_bar,
        { name="key_buttons", layout=ui.Flow{ dir=.left, align=.center, gap=6 } },
        { point=.right, offset={-screen_pad,0} },
    )
}

add_screen_tab_and_page :: proc (screen: ^ui.Frame, name, text: string) -> (tab, page: ^ui.Frame) {
    tab = ui.add_frame(ui.get(screen, "header_bar/tabs"), {
        name        = name,
        text        = text,
        text_format = "<bottom,font=text_4l,pad=20:10>%s",
        flags       = {.radio,.terse,.terse_width},
        size_min    = {120,0},
        draw        = draw_screen_tab,
        click       = proc (f: ^ui.Frame) {
            page := ui.get(f, fmt.tprintf("../../../pages/%s", f.name))
            ui.show(page, hide_siblings=true)
        },
    })

    ui.add_frame(tab, {
        name        = "points",
        text_format = "<font=text_4m,color=bg0,pad=6:0>%i",
        size_min    = {32,0},
        flags       = {.hidden,.pass,.terse,.terse_size},
        draw        = draw_screen_tab_points,
    }, { point=.center, rel_point=.bottom, offset={0,6} })

    page = ui.add_frame(ui.get(screen, "pages"),
        { name=name, text="bg2" , draw=draw_color_rect },
        { point=.top_left },
        { point=.bottom_right },
    )

    if len(tab.parent.children) > 1 {
        ui.show(ui.get(screen, "header_bar/nav_next_tab"))
        ui.show(ui.get(screen, "header_bar/nav_prev_tab"))
    }

    return
}

move_screen_pyramid_buttons :: proc (screen: ^ui.Frame, side: enum { left, center }) {
    list := ui.get(screen, "footer_bar/pyramid_buttons")
    flow := ui.layout_flow(list)
    switch side {
    case .left:
        flow.dir = .right
        ui.set_anchors(list, { point=.bottom_left, offset={screen_pad,0} })
    case .center:
        flow.dir = .left_and_right
        ui.set_anchors(list, { point=.bottom })
    }
}

add_screen_pyramid_button :: proc (screen: ^ui.Frame, name, text, icon: string) -> ^ui.Frame {
    button := ui.add_frame(ui.get(screen, "footer_bar/pyramid_buttons"), {
        name    = name,
        flags   = {.capture},
        size    = {250,125},
        draw    = draw_screen_pyramid_button,
    })

    ui.add_frame(button, {
        name    = "icon",
        text    = icon,
        size    = 46,
        flags   = {.pass_self},
        draw    = draw_screen_pyramid_button_icon,
    }, { point=.bottom, offset={0,-12} })

    ui.add_frame(button, {
        name    = "title",
        text    = fmt.tprintf("<pad=20:0,font=text_4r,color=primary> %s", text),
        flags   = {.pass_self,.terse,.terse_size},
        draw    = draw_hexagon_rect_with_half_transparent_bg,
    }, { point=.center, rel_point=.bottom, offset={0,-80} })

    return button
}

add_screen_key_button :: proc (screen: ^ui.Frame, name, text: string) -> ^ui.Frame {
    buttons := ui.get(screen, "footer_bar/key_buttons")
    return add_button(buttons, name, text)
}

add_screen_page_body_with_list_and_details :: proc (parent: ^ui.Frame, name: string, with_details_header := false, details_header_icon := "") -> (body, list, details: ^ui.Frame) {
    body = ui.add_frame(parent,
        { name=name },
        { point=.top_left },
        { point=.bottom_right },
    )

    list = ui.add_frame(body,
        { name="list", flags={.scissor}, layout=ui.Flow{ dir=.down,gap=10,scroll={step=30} } },
        { point=.top_left },
        { point=.bottom_right, rel_point=.bottom, offset={-40,0} },
    )

    add_scrollbar(list)

    details = ui.add_frame(body, {
        name    = "details",
        flags   = {.scissor},
        layout  = ui.Flow { dir=.down,pad=1,scroll={step=20} },
        text    = "#0005",
        draw    = draw_gradient_fade_down_rect,
    },
        { point=.bottom_left, rel_point=.bottom, offset={40,0} },
        { point=.top_right },
    )

    add_scrollbar(details)

    if with_details_header {
        header_h :: 40

        details_header := ui.add_frame(body, {
            name        = "details_header",
            size_min    = {0,header_h},
            flags       = {.terse,.terse_height},
            text_format = "<wrap,left,pad=14:6,font=text_4m,color=primary_l3>%s",
            draw        = draw_header_bar_primary,
        },
            { point=.top_left, rel_point=.top, offset={40,0} },
            { point=.top_right },
        )

        ui.set_anchors(details,
            { point=.top_left, rel_point=.bottom_left, rel_frame=details_header },
            { point=.bottom_right },
        )

        ui.add_frame(details_header, {
            name        = "aside",
            flags       = {.terse,.terse_size},
            text_format = "<pad=14:6,font=text_4r,color=primary_l3>%s",
        },
            { point=.right },
        )

        if details_header_icon != "" {
            diamond_size :: 60
            diamond_gap :: 15
            details_header.anchors[0].offset.x += diamond_size + diamond_gap

            icon := ui.add_frame(details_header, {
                name    = "icon",
                size    = diamond_size,
                text    = details_header_icon,
                draw    = draw_icon_diamond_primary,
            },
                { point=.right, rel_point=.left, offset={-diamond_gap,0} },
            )

            ui.add_frame(details_header, {
                name    = "bg_line_right",
                order   = -1,
                text    = "primary_d2",
                size    = {0,2},
                draw    = draw_gradient_fade_right_rect,
            },
                { point=.right, rel_point=.left, offset={4,0} },
                { point=.left, rel_point=.right, rel_frame=icon, offset={-1,0} },
            )

            ui.add_frame(details_header, {
                name    = "bg_line_down",
                order   = -1,
                text    = "primary_d2",
                size    = {1,0},
                draw    = draw_gradient_fade_down_rect,
            },
                { point=.top, rel_point=.bottom, rel_frame=icon },
                { point=.bottom, rel_point=.bottom_left, rel_frame=details, offset={-diamond_gap-diamond_size/2,0} },
            )
        }
    }

    return
}
