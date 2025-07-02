package demo9_screens_opening

import "spacelib:ui"

import "../../data"
import "../../partials"

add_to :: proc (parent: ^ui.Frame) {
    screen := ui.add_frame(parent,
        { name="opening" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen_base(screen)
    partials.add_screen_footer_pyramid_button(screen, "settings", "SETTINGS", icon="cog")
    partials.add_screen_footer_pyramid_button(screen, "credits", "CREDITS", icon="stabbed-note")
    partials.add_screen_footer_key_button(screen, "close", "Close", key="Esc")
    partials.add_screen_footer_key_button(screen, "request_help", "Request Help", key="H")
    partials.add_screen_footer_key_button(screen, "report_bug", "Report Bug", key="B")
    partials.add_screen_footer_key_button(screen, "account", "Account", key="A")

    add_home_page(screen)
    add_social_links(screen)
    add_account_info(screen)

    ui.click(screen, "header_bar/tabs/home")
}

add_home_page :: proc (screen: ^ui.Frame) {
    _, page := partials.add_screen_tab_and_page(screen, "home", "HOME")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>HOME PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_social_links :: proc (screen: ^ui.Frame) {
    header_bar := ui.get(screen, "header_bar")

    social_links := ui.add_frame(header_bar,
        { name="social_links", layout={ dir=.left, size=62, gap=15, align=.center, auto_size=.dir } },
        { point=.right, rel_point=.bottom_right, offset={-30,0} },
    )

    ui.add_frame(social_links, { text="world", draw=partials.draw_diamond_button })
    ui.add_frame(social_links, { text="envelope", draw=partials.draw_diamond_button })

    ui.add_frame(header_bar,
        { name="social_links_bg_line", order=-1, size={0,2}, text="primary_d2", draw=partials.draw_color_rect },
        { point=.right, rel_frame=header_bar },
        { point=.left, rel_frame=social_links },
    )
}

add_account_info :: proc (screen: ^ui.Frame) {
    account_info := ui.add_frame(ui.get(screen, "header_bar"),
        { name="account_info", text_format="<left,font=text_4l,color=primary_a6>%s\n%s", flags={.terse,.terse_height} },
        { point=.left, offset={30,0} },
    )
    ui.set_text(account_info, data.player.account_name, data.player.character_name)
}
