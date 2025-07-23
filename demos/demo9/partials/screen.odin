package partials

import "core:fmt"
import "core:slice"

import "spacelib:core"
import "spacelib:ui"

screen_pad :: 50

Screen :: struct {
    root            : ^ui.Frame,

    header          : ^ui.Frame,
    header_left     : ^ui.Frame,
    header_right    : ^ui.Frame,
    tabs            : ^ui.Frame,
    tabs_prev       : ^ui.Frame,
    tabs_next       : ^ui.Frame,

    footer          : ^ui.Frame,
    pyramid_buttons : ^ui.Frame,
    key_buttons     : ^ui.Frame,

    pages           : ^ui.Frame,
}

add_screen :: proc (parent: ^ui.Frame, name: string, is_empty := false) -> Screen {
    screen: Screen

    if ui.find(parent, name) != nil {
        fmt.panicf("Screen with name \"%s\" already exists", name)
    }

    screen.root = ui.add_frame(parent,
        { name=name, flags={.hidden} },
        { point=.top_left },
        { point=.bottom_right },
    )

    if !is_empty {
        add_screen_header(&screen)
        add_screen_footer(&screen)
        screen.pages = ui.add_frame(screen.root,
            { name="pages" },
            { point=.top_left, rel_point=.bottom_left, rel_frame=screen.header },
            { point=.bottom_right, rel_point=.top_right, rel_frame=screen.footer },
        )
    }

    return screen
}

@private
add_screen_header :: proc (screen: ^Screen) {
    bar_h :: 80
    tab_nav_pad :: 8

    screen.header = ui.add_frame(screen.root, {
        order   = 1,
        name    = "header",
        text    = "bg0",
        size    = {0,bar_h},
        draw    = draw_color_rect,
        tick    = proc (f: ^ui.Frame) {
            tabs := ui.get(f, "tabs")
            if len(tabs.children) < 2 do return

            tabs_prev := ui.get(f, "tabs_prev")
            tabs_next := ui.get(f, "tabs_next")
            tabs_flow := ui.layout_flow(tabs)

            tabs_prev.anchors[0].offset.x = -tab_nav_pad
            tabs_next.anchors[0].offset.x = tab_nav_pad

            if tabs_flow.scroll.offset_max != 0 {
                selected := ui.first_selected_child(tabs)
                offset := core.rect_offset_into_view(selected.rect, tabs.rect)
                if abs(offset.x) > .1 {
                    dx := offset.x * f.ui.clock.dt * .333
                    ui.scroll(tabs, dx)
                }
            } else {
                first := tabs.children[0]
                tabs_prev.anchors[0].offset.x += first.rect.x-first.parent.rect.x

                last := slice.last(tabs.children[:])
                tabs_next.anchors[0].offset.x += (last.rect.x+last.rect.w)-(last.parent.rect.x+last.parent.rect.w)
            }
        },
    },
        { point=.top_left },
        { point=.top_right },
    )

    screen.header_left = ui.add_frame(screen.header,
        { name="header_left", size={100,0} },
        { point=.top_left },
        { point=.bottom_left },
    )

    screen.header_right = ui.add_frame(screen.header,
        { name="header_right", size={100,0} },
        { point=.top_right },
        { point=.bottom_right },
    )

    tabs_extra_hangout_h :: 50

    screen.tabs = ui.add_frame(screen.header, {
        name="tabs",
        flags={.scissor,.pass_self},
        size={0,bar_h+tabs_extra_hangout_h},
        layout=ui.Flow{ dir=.left_and_right, size={0,bar_h}, scroll={step=20} },
    },
        { point=.top_left, rel_point=.top_right, rel_frame=screen.header_left },
        { point=.top_right, rel_point=.top_left, rel_frame=screen.header_right },
    )

    screen.tabs_prev = ui.add_frame(screen.header, {
        name    = "tabs_prev",
        text    = "<pad=8,font=text_4l,icon=key/Q>",
        flags   = {.hidden,.capture,.terse,.terse_size},
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { ui.select_prev_child(ui.get(f.parent, "tabs"), allow_rotation=true) },
    },
        { point=.right, rel_point=.left, rel_frame=screen.tabs, offset={0,12-tabs_extra_hangout_h/2} },
    )

    screen.tabs_next = ui.add_frame(screen.header, {
        name    = "tabs_next",
        text    = "<pad=8,font=text_4l,icon=key/E>",
        flags   = {.hidden,.capture,.terse,.terse_size},
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { ui.select_next_child(ui.get(f.parent, "tabs"), allow_rotation=true) },
    },
        { point=.left, rel_point=.right, rel_frame=screen.tabs, offset={0,12-tabs_extra_hangout_h/2} },
    )
}

@private
add_screen_footer :: proc (screen: ^Screen) {
    bar_h :: 80

    screen.footer = ui.add_frame(screen.root,
        { name="footer_bar", text="bg0", size={0,bar_h}, order=1, draw=draw_color_rect },
        { point=.bottom_left },
        { point=.bottom_right },
    )

    screen.pyramid_buttons = ui.add_frame(screen.footer,
        { name="pyramid_buttons", layout=ui.Flow{ dir=.right, align=.end, gap=20 } },
    )

    move_screen_pyramid_buttons(screen, .left)

    screen.key_buttons = ui.add_frame(screen.footer,
        { name="key_buttons", layout=ui.Flow{ dir=.left, align=.center, gap=6 } },
        { point=.right, offset={-screen_pad,0} },
    )
}

add_screen_tab_and_page :: proc (screen: ^Screen, name, text: string) -> (tab, page: ^ui.Frame) {
    tab = ui.add_frame(screen.tabs, {
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
        wheel       = proc (f: ^ui.Frame, dy: f32) -> bool {
            return ui.wheel(f.parent, dy)
        },
    })

    ui.add_frame(tab, {
        name        = "points",
        text_format = "<font=text_4m,color=bg0,pad=6:0>%i",
        size_min    = {32,0},
        flags       = {.hidden,.pass,.terse,.terse_size},
        draw        = draw_screen_tab_points,
    }, { point=.center, rel_point=.bottom, offset={0,6} })

    page = ui.add_frame(screen.pages,
        { name=name, text="bg2" , draw=draw_color_rect },
        { point=.top_left },
        { point=.bottom_right },
    )

    if len(tab.parent.children) > 1 {
        ui.show(screen.tabs_prev)
        ui.show(screen.tabs_next)
    }

    return
}

move_screen_pyramid_buttons :: proc (screen: ^Screen, side: enum { left, center }) {
    list := screen.pyramid_buttons
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

add_screen_pyramid_button :: proc (screen: ^Screen, name, text, icon: string) -> ^ui.Frame {
    button := ui.add_frame(screen.pyramid_buttons, {
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

add_screen_key_button :: proc (screen: ^Screen, name, text: string) -> ^ui.Frame {
    return add_button(screen.key_buttons, name, text)
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
            text_format = "<wrap,left,pad=15:6,font=text_4m,color=primary_l3>%s",
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
