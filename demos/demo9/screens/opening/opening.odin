package demo9_screens_opening

import "spacelib:ui"

create :: proc (parent: ^ui.Frame) {
    opening := ui.add_frame(parent,
        { name="opening" },
        { point=.top_left },
        { point=.bottom_right },
    )

    ui.add_frame(opening,
        { name="msg", text="<font=text_4l,color=primary>OPENING SCREEN GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}
