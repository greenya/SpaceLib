package partials

import "spacelib:ui"

add_placeholder_note :: proc (parent: ^ui.Frame, text: string) -> ^ui.Frame {
    frame := ui.add_frame(parent, {
        name        = "ph_note",
        flags       = {.terse},
        text_format = "<wrap,pad=20,font=text_6l,color=primary_a2>%s",
        text        = text,
    })

    if parent.layout.dir == .none {
        ui.set_anchors(frame, { point=.top_left }, { point=.bottom_right })
    }

    return frame
}

Placeholder_Image_Aspect_Ratio :: enum {
    default,
    _16x9,
}

add_placeholder_image :: proc (parent: ^ui.Frame, aspect_ratio := Placeholder_Image_Aspect_Ratio.default) -> ^ui.Frame {
    frame := ui.add_frame(parent, { name="ph_image", draw=draw_image_placeholder })

    switch aspect_ratio {
    case .default:
        assert(parent.layout.dir == .none)
        ui.set_anchors(frame, { point=.top_left }, { point=.bottom_right })
    case ._16x9:
        frame.size_aspect = 16./9
    }

    return frame
}
