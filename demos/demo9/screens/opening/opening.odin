package demo9_screens_opening

import "spacelib:ui"

import "../../partials"

add_to :: proc (parent: ^ui.Frame) {
    screen := ui.add_frame(parent,
        { name="opening" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen_base(screen)
    partials.add_screen_footer_pyramid_button(screen, "settings", "SETTINGS")
    partials.add_screen_footer_pyramid_button(screen, "credits", "CREDITS")
    partials.add_screen_footer_key_button(screen, "close", "Close", "Esc")
    partials.add_screen_footer_key_button(screen, "request_help", "Request Help", "H")
    partials.add_screen_footer_key_button(screen, "report_bug", "Report Bug", "B")
    partials.add_screen_footer_key_button(screen, "account", "Account", "A")

    add_home_page(screen)

    ui.click(screen, "header_bar/tabs/home")
}

add_home_page :: proc (screen: ^ui.Frame) {
    _, page := partials.add_screen_tab_and_page(screen, "home", "HOME")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>HOME PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}
