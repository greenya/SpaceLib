package demo9_screens_opening

import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

add :: proc (parent: ^ui.Frame) {
    screen := ui.add_frame(parent,
        { name="opening" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen_base(screen)
    partials.add_screen_footer_pyramid_button(screen, "settings", "SETTINGS", icon="cog")
    partials.add_screen_footer_pyramid_button(screen, "credits", "CREDITS", icon="stabbed-note",
        click=proc (f: ^ui.Frame) {
            events.send("open_screen", "credits")
        },
    )
    partials.add_screen_footer_key_button(screen, "close", "Close", key="Esc")
    partials.add_screen_footer_key_button(screen, "request_help", "Request Help", key="H")
    partials.add_screen_footer_key_button(screen, "report_bug", "Report Bug", key="B")
    partials.add_screen_footer_key_button(screen, "account", "Account", key="A")

    add_social_links(screen)
    add_account_info(screen)

    add_home_page(screen)

    ui.click(screen, "header_bar/tabs/home")
}

add_social_links :: proc (screen: ^ui.Frame) {
    header_bar := ui.get(screen, "header_bar")

    social_links := ui.add_frame(header_bar,
        { name="social_links", layout={ dir=.left, size=62, gap=15, align=.center, auto_size=.dir } },
        { point=.right, rel_point=.bottom_right, offset={-partials.screen_pad,0} },
    )

    ui.add_frame(social_links, { text="world", draw=partials.draw_diamond_button })
    ui.add_frame(social_links, { text="envelope", draw=partials.draw_diamond_button })

    ui.add_frame(header_bar,
        { name="social_links_bg_line", flags={.pass}, order=-1, size={0,2}, text="primary_d4",
            draw=partials.draw_color_rect },
        { point=.right },
        { point=.left, rel_frame=social_links },
    )
}

add_account_info :: proc (screen: ^ui.Frame) {
    account_info := ui.add_frame(ui.get(screen, "header_bar"),
        { name="account_info", text_format="<left,font=text_4l,color=primary_a6>%s\n%s", flags={.terse,.terse_height} },
        { point=.left, offset={partials.screen_pad,0} },
    )
    ui.set_text(account_info, data.player.account_name, data.player.character_name)
}

add_home_page :: proc (screen: ^ui.Frame) {
    _, page := partials.add_screen_tab_and_page(screen, "home", "HOME")

    add_home_page_welcome_area(page)
    add_home_page_notification_area(page)
    add_home_page_game_title(page)
}

add_home_page_welcome_area :: proc (page: ^ui.Frame) {
    welcome_area := ui.add_frame(page,
        { name="welcome_area", size={520,0}, text="#0005", draw=partials.draw_gradient_fade_up_and_down_rect },
        { point=.top_left, offset={partials.screen_pad,0} },
        { point=.bottom_left, offset={partials.screen_pad,0} },
    )

    header := ui.add_frame(welcome_area,
        { name="header", flags={.terse,.terse_height}, text_format="<font=text_6l,color=primary_l2,pad=0:4>%s",
            draw=partials.draw_hexagon_rect_wide },
        { point=.top_left, offset={0,180} },
        { point=.top_right, offset={0,180} },
    )

    ui.add_frame(welcome_area,
        { name="header_bg_line", flags={.pass}, order=-1, size={0,2}, text="primary_d4", draw=partials.draw_color_rect },
        { point=.left, rel_frame=page },
        { point=.right, rel_point=.left, rel_frame=header },
    )

    scroll_container := ui.add_frame(welcome_area,
        { name="scroll_container", layout={dir=.down,scroll={step=10}}, flags={.scissor} },
        { point=.top_left, rel_point=.bottom_left, rel_frame=header },
        { point=.bottom_right },
    )

    ui.add_frame(scroll_container,
        { name="banner", size_aspect=16./9, draw=partials.draw_image_placeholder },
    )

    content := ui.add_frame(scroll_container,
        { name="content", text_format="<wrap,pad=20:10,left,font=text_4r,color=primary_d2>%s", flags={.terse,.terse_height} },
    )

    ui.set_text(header, data.info.welcome.title)
    ui.set_text(content, data.info.welcome.content)

    buttons_bar := ui.add_frame(welcome_area,
        { name="buttons_bar", size={0,60}, layout={dir=.left_and_right,size={200,0},gap=30} },
        { point=.bottom_left, rel_point=.top_left, rel_frame=header, offset={0,-40} },
        { point=.bottom_right, rel_point=.top_right, rel_frame=header, offset={0,-40} },
    )

    ui.add_frame(buttons_bar, { name="continue", text="<font=text_6l,pad=0:4>CONTINUE", flags={.terse},
        draw=partials.draw_featured_button })

    ui.add_frame(buttons_bar, { name="servers", text="<font=text_6l,pad=0:4>SERVERS", flags={.terse},
        draw=partials.draw_featured_button })
}

add_home_page_notification_area :: proc (page: ^ui.Frame) {
    notifications_area := ui.add_frame(page,
        { name="notifications_area", size={400,0}, flags={.hidden}, text="#0005", draw=partials.draw_gradient_fade_down_rect },
        { point=.top_right, offset={-partials.screen_pad,120} },
        { point=.bottom_right, offset={-partials.screen_pad,-160} },
    )

    header := ui.add_frame(notifications_area,
        { name="header", text="<left,font=text_4l,color=primary_l2,pad=0:2,tab=20>NOTIFICATIONS", flags={.terse,.terse_height}, draw=partials.draw_hexagon_rect_wide },
        { point=.top_left },
        { point=.top_right },
    )
    ui.add_frame(header,
        { name="icon", text="<left,font=text_4l,color=primary,icon=key2/!:.9>", flags={.terse,.terse_height,.terse_width} },
        { point=.center, rel_point=.left, offset={1,0} },
    )
    ui.add_frame(notifications_area,
        { name="header_bg_line", flags={.pass}, order=-1, size={0,2}, text="primary_d4", draw=partials.draw_color_rect },
        { point=.right, rel_frame=page },
        { point=.left, rel_point=.right, rel_frame=header },
    )

    title := ui.add_frame(notifications_area,
        { name="title", text_format="<left,pad=6:0,font=text_4l,color=primary_d2>%s", flags={.terse,.terse_height}, draw=partials.draw_hexagon_rect },
        { point=.top_left, rel_point=.bottom_left, rel_frame=header, offset={0,10} },
        { point=.top_right, rel_point=.bottom_right, rel_frame=header, offset={0,10} },
    )

    scroll_container := ui.add_frame(notifications_area,
        { name="scroll_container", layout={dir=.down,scroll={step=10}}, flags={.scissor} },
        { point=.top_left, rel_point=.bottom_left, offset={0,10}, rel_frame=title },
        { point=.bottom_right },
    )

    content := ui.add_frame(scroll_container,
        { name="content", text_format="<wrap,pad=20:0,left,font=text_4r,color=primary_d2>%s", flags={.terse,.terse_height} },
    )

    if data.info.notification.title != "" {
        ui.set_text(title, data.info.notification.title)
        ui.set_text(content, data.info.notification.content)
        ui.show(notifications_area)
    }
}

add_home_page_game_title :: proc (page: ^ui.Frame) {
    ui.add_frame(page,
        { name="game_title", flags={.pass}, size={280,80}, draw=partials.draw_game_title },
        { point=.bottom_right, offset={-partials.screen_pad,-50} },
    )
}
