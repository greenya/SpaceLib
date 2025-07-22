#+private
package interface

import "spacelib:ui"

import "../fonts"
import "../partials"

dev: struct {
    layer   : ^ui.Frame,
    window  : ^ui.Frame,
}

add_dev_layer :: proc (order: int) {
    assert(dev.layer == nil)

    dev.layer = ui.add_frame(ui_.root, {
        name    = "dev",
        flags   = {/*.hidden,*/.pass_self},
        order   = order,
    }, { point=.top_left }, { point=.bottom_right })

    add_dev_window()
}

add_dev_window :: proc () {
    body := ui.add_frame(dev.layer, {
        name="body",
        rect={450,250,400,300},
        text="#742",
        draw=partials.draw_color_rect,
    })

    ui.add_frame(body, {
        name="header",
        flags={.capture},
        size={0,40},
        text="#d74",
        draw=partials.draw_color_rect,
        drag=proc (f: ^ui.Frame, mouse_pos, captured_pos: [2] f32) {
            offset := mouse_pos-captured_pos
            f.parent.rect.x=offset.x
            f.parent.rect.y=offset.y+f.size.y
            ui.update(f.parent)
        },
    },
        {point=.bottom_left,rel_point=.top_left},
        {point=.bottom_right,rel_point=.top_right},
    )

    ui.add_frame(body, {
        name="resize_handle",
        flags={.capture},
        size=30,
        text="#d74",
        draw=partials.draw_color_rect,
        drag=proc (f: ^ui.Frame, mouse_pos, captured_pos: [2] f32) {
            offset := mouse_pos-captured_pos-{f.rect.x,f.rect.y}
            f.parent.rect.w += offset.x
            f.parent.rect.h += offset.y
        },
    },
        {point=.bottom_right},
    )

    ui.add_frame(body, {
        name="reload_fonts",
        size={100,40},
        text="#cc4",
        draw=partials.draw_color_rect,
        click=proc (f: ^ui.Frame) {
            fonts.destroy()
            fonts.create(scale=1.1)
            ui.reset_terse(f.ui)
        },
    },
        {point=.top_left,offset=20},
    )
}
