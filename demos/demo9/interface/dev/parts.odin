#+private
package interface_dev

import "core:fmt"

import "spacelib:core"
import "spacelib:ui"
import "spacelib:raylib/draw"

import "../../partials"

add_window :: proc (name, title: string, empty_background := false) -> ^ui.Frame {
    window := ui.add_frame(dev.layer, {
        name=name,
        flags={.hidden,.block_wheel},
        rect={10,10,dev_window_min_size.x,dev_window_min_size.y},
        draw=empty_background ? draw_empty_background : draw_normal_background,
    })

    header := ui.add_frame(window, {
        name="header",
        flags={.capture,.terse,.terse_height},
        text=title,
        text_format="<pad=15:10,left,wrap,color=#eee>%s",
        draw=proc (f: ^ui.Frame) {
            draw.rect(f.rect, core.gray1)
            partials.draw_terse(f)
        },
        drag=proc (f: ^ui.Frame, info: ui.Drag_Info) {
            offset := f.ui.mouse.pos - info.start_offset
            f.parent.rect.x = offset.x
            f.parent.rect.y = offset.y
            ui.update(f.parent)
        },
    },
        { point=.top_left },
        { point=.top_right },
    )

    ui.add_frame(window, {
        name="content",
        flags={.scissor},
    },
        { point=.top_left, rel_point=.bottom_left, rel_frame=header },
        { point=.bottom_right },
    )

    ui.add_frame(window, {
        name="resize_handle",
        flags={.capture},
        size=32,
        draw=proc (f: ^ui.Frame) {
            partials.draw_sprite("drag_indicator", f.rect, tint=core.gray6)
        },
        drag=proc (f: ^ui.Frame, info: ui.Drag_Info) {
            offset := f.ui.mouse.pos - info.start_offset - {f.rect.x,f.rect.y}
            rect := &f.parent.rect
            rect.w = max(dev_window_min_size.x, rect.w + offset.x)
            rect.h = max(dev_window_min_size.y, rect.h + offset.y)
        },
    },
        { point=.bottom_right },
    )

    return window

    draw_normal_background :: proc (f: ^ui.Frame) {
        draw.rect_lines(core.rect_inflated(f.rect, 4), 4, core.alpha(core.black, .4))
        draw.rect(core.rect_inflated(f.rect, 5), core.alpha(core.black, .4))
        draw.rect(f.rect, core.gray2)
    }

    draw_empty_background :: proc (f: ^ui.Frame) {
        draw.rect_lines(core.rect_inflated(f.rect, 4), 4, core.alpha(core.black, .4))
    }
}

add_header :: proc (parent: ^ui.Frame, text: string) {
    ui.add_frame(parent, {
        flags={.terse,.terse_height},
        text=fmt.tprintf("<pad=5:10,left,wrap,color=#333>%s", text),
        draw=proc (f: ^ui.Frame) {
            bg_rect := core.rect_inflated(f.rect, {15,0})
            draw.rect(bg_rect, core.gray9)
            partials.draw_terse(f)
        },
    })
}

add_text :: proc (parent: ^ui.Frame, text: string) -> ^ui.Frame {
    return ui.add_frame(parent, {
        flags={.terse,.terse_height},
        text=fmt.tprintf("<left,wrap,color=#eee>%s", text),
    })
}

add_list_grid :: proc (parent: ^ui.Frame, cell_size := Vec2 {72,30}, wrap := 0) -> ^ui.Frame {
    return ui.add_frame(parent, {
        layout=ui.Grid{ dir=.right_down, size=cell_size, wrap=wrap, auto_size={.height} },
        draw=proc (f: ^ui.Frame) { draw.rect_gradient_horizontal(f.rect, core.gray3, core.gray2) },
    })
}

add_button :: proc (parent: ^ui.Frame, name := "", text := "", click: ui.Frame_Proc = nil) -> ^ui.Frame {
    return ui.add_frame(parent, {
        name=name,
        flags={.terse,.terse_height},
        text=fmt.tprintf("<wrap>%s", text),
        click=click,
        draw=proc (f: ^ui.Frame) {
            if f.selected                   do draw.rect(f.rect, core.gray7)
            else          do if f.entered   do draw.rect(f.rect, core.gray4)
            partials.draw_terse(f, color=f.selected?core.gray1:core.gray7)
        },
    })
}
