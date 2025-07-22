package partials

import "spacelib:ui"

add_placeholder_note :: proc (parent: ^ui.Frame, text: string) -> ^ui.Frame {
    return ui.add_frame(parent, {
        name        = "ph_note",
        flags       = {.terse},
        text_format = "<wrap,pad=20,font=text_6l,color=primary_a2>%s",
        text        = text,
    },
        { point=.top_left },
        { point=.bottom_right },
    )
}

add_placeholder_image :: proc (parent: ^ui.Frame, size_aspect := f32(0)) -> ^ui.Frame {
    frame := ui.add_frame(parent, {
        name        = "ph_image",
        text        = "IMAGE PLACEHOLDER",
        size_aspect = size_aspect,
        draw        = draw_image_placeholder,
    })

    if size_aspect == 0 {
        ui.set_anchors(frame, { point=.top_left }, { point=.bottom_right })
    }

    return frame
}
