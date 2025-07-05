package demo9_screens_credits

import "spacelib:ui"

import "../../partials"

add :: proc (parent: ^ui.Frame) {
    screen := ui.add_frame(parent,
        { name="credits" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen_base(screen)
    partials.add_screen_footer_key_button(screen, "close", "Close", key="Esc")

    add_credits_page(screen)

    ui.click(screen, "header_bar/tabs/credits")
}

add_credits_page :: proc (screen: ^ui.Frame) {
    _, page := partials.add_screen_tab_and_page(screen, "credits", "CREDITS")

    scroll_container := ui.add_frame(page,
        { name="scroll_container", layout={dir=.down,scroll={step=10}}, flags={.scissor} },
        { point=.top_left, offset={240,0} },
        { point=.bottom_right, offset={-240,0} },
    )

    ui.add_frame(scroll_container, {
        name="content",
        flags={.terse,.terse_height},
        text_format="<pad=0:20,wrap,left,font=text_4l,color=primary>%s",
        text=#load("credits.txt"),
    })
}
