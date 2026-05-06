package main

import hi ".."

add_dialog :: proc (name, title, content, button1: string, button2 := "", button3 := "", with_header_close_button := false) -> (id: hi.ID) {
    id = hi.begin_view({
        name        = name,
        flags       = {.fit_y},
        size        = {300,0},
        layout      = {dir=.column},
        placement   = {anchor=.5,pivot=.5},
    })
    defer hi.end_view()

    hi.begin_view({ name="header", flags={.fill_x,.fit_y}, padding={10,0,0,0}, layout={dir=.row,align=.center,gap=10} })
        hi.add_view({ name="title", flags={.fill_x}, size={0,14}, /*, text=title*/ })
        if with_header_close_button {
            add_icon_button(name="button_close", icon="cross")
        }
    hi.end_view()

    hi.add_view({ name="content", flags={.fill_x}, size={0,80} /*, padding=10, text=content*/ })

    hi.begin_view({ name="footer", flags={.fill_x,.fit_y}, padding=5, layout={dir=.row,justify=.center,align=.center,gap=10} })
        add_text_button(name="button1", text=button1)
        if button2 != "" do add_text_button(name="button2", text=button2)
        if button3 != "" do add_text_button(name="button3", text=button3)
    hi.end_view()

    return
}
