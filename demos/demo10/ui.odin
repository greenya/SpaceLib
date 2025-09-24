package demo10

import "core:fmt"
import "core:reflect"
import "spacelib:ui"

ui_add_tab_and_content :: proc (tab_parent, content_parent: ^ui.Frame, text: string) -> (tab, content: ^ui.Frame) {
    tab = ui.add_frame(tab_parent, {
        flags   = {.terse,.terse_width,.radio},
        text    = fmt.tprintf("<pad=20:0>%s", text),
        draw    = draw_tab_button,
        click   = proc (f: ^ui.Frame) {
            content := ui.user_ptr(f, ^ui.Frame)
            ensure(content != nil)
            ui.show(content, hide_siblings=true)

            options.active_tab_idx = ui.index(f)
            options_save()
        },
    })

    content = ui.add_frame(content_parent,
        { layout=ui.Flow { dir=.down, pad={0,0,20,0}, align=.center, auto_size={.height} } },
    )

    ui.set_user_ptr(tab, content)
    return
}

ui_add_scrollbar :: proc (target: ^ui.Frame, position: enum { left, right }) -> (track, thumb: ^ui.Frame) {
    assert(target.parent != nil)
    assert(.scissor in target.flags)

    track = ui.add_frame(target.parent,
        { size={4,0}, draw=draw_scrollbar_track },
    )

    switch position {
    case .left:
        ui.set_anchors(track,
            { point=.top_right, rel_point=.top_left, rel_frame=target, offset={-30,80} },
            { point=.bottom_right, rel_point=.bottom_left, rel_frame=target, offset={-30,-80} },
        )
    case .right:
        ui.set_anchors(track,
            { point=.top_left, rel_point=.top_right, rel_frame=target, offset={30,80} },
            { point=.bottom_left, rel_point=.bottom_right, rel_frame=target, offset={30,-80} },
        )
    }

    thumb = ui.add_frame(track,
        { flags={.capture}, size=32, draw=draw_scrollbar_thumb },
        { point=.top },
    )

    ui.setup_scrollbar_actors(target, thumb)
    return
}

ui_add_slider :: proc (parent: ^ui.Frame, idx, total: int, thumb_click: ui.Frame_Proc) -> (track, thumb: ^ui.Frame) {
    track = ui.add_frame(parent,
        { size={0,32}, draw=draw_scrollbar_track },
    )

    thumb = ui.add_frame(track,
        { flags={.capture}, size=32, draw=draw_scrollbar_thumb, click=thumb_click },
        { point=.left },
    )

    ui.setup_slider_actors({ idx=idx, total=total }, thumb)
    return
}

ui_add_checkbox :: proc (parent: ^ui.Frame, text: string, selected: bool, click: ui.Frame_Proc) {
    ui.add_frame(parent, {
        flags       = {.terse,.terse_size,.check},
        selected    = selected,
        text        = fmt.tprintf("<pad=10>%s", text),
        draw        = draw_button,
        click       = click,
    })
}

ui_add_enum_radio :: proc (parent: ^ui.Frame, selected: $T, button_click: ui.Frame_Proc) {
    bar := ui.add_frame(parent, { layout=ui.Flow { dir=.right_center, auto_size={.height} } })

    for field in reflect.enum_fields_zipped(T) {
        ui.add_frame(bar, {
            flags       = {.terse,.terse_size,.radio},
            selected    = selected == T(field.value),
            name        = field.name,
            text        = fmt.tprintf("<pad=10>%s", field.name),
            draw        = draw_button,
            click       = button_click,
        })
    }
}
