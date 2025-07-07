package demo9_partials

import "spacelib:ui"

add_text_and_scrollbar :: proc (target: ^ui.Frame) -> (text, track, thumb: ^ui.Frame) {
    text = ui.add_frame(target, {
        name="text",
        flags={.terse,.terse_height},
        text_format="<wrap,left,font=text_4l,color=primary>%s",
    })

    track, thumb = add_scrollbar(target)

    return
}

add_scrollbar :: proc (target: ^ui.Frame) -> (track, thumb: ^ui.Frame) {
    assert(target.parent != nil)
    assert(.scissor in target.flags)

    track = ui.add_frame(target.parent,
        { name="track", size={1,0}, text="primary_a2", draw=draw_color_rect },
        { point=.top_left, rel_point=.top_right, rel_frame=target, offset={10,0} },
        { point=.bottom_left, rel_point=.bottom_right, rel_frame=target, offset={10,0} },
    )

    thumb = ui.add_frame(track,
        { name="thumb", size={19,60}, draw=draw_scrollbar_thumb },
        { point=.top },
    )

    ui.setup_scrollbar_actors(target, thumb)

    return
}
