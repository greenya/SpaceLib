#+private
package interface

import "core:fmt"
import "core:math/ease"

import "spacelib:ui"

import "../events"
import "../partials"

modals: struct {
    layer   : ^ui.Frame,
    modal   : ^ui.Frame,
    target  : ^ui.Frame,
}

max_buttons :: 4

add_modals_layer :: proc (order: int) {
    assert(modals.layer == nil)

    modals.layer = ui.add_frame(ui_.root, {
        name    = "modals_layer",
        flags   = {.hidden,.block_wheel},
        order   = order,
        text    = "#000b",
        draw    = partials.draw_color_rect,
    }, { point=.top_left }, { point=.bottom_right })

    add_modal()

    events.listen(.open_modal, open_modal_listener)
    events.listen(.close_modal, close_modal_listener)
}

add_modal :: proc () {
    modals.modal = ui.add_frame(modals.layer, {
        name    = "modal",
        size    = {640,0},
        layout  = ui.Flow { dir=.down, pad=30, auto_size={.height} },
        draw    = partials.draw_window_rect,
    }, { point=.center })

    ui.add_frame(modals.modal, {
        name        = "title",
        flags       = {.terse,.terse_height},
        text_format = "<wrap,pad=30,font=text_4m,color=primary_d2>%s",
    })

    ui.add_frame(modals.modal, {
        name        = "message",
        flags       = {.terse,.terse_height},
        text_format = "<wrap,font=text_4l,color=primary_d2>%s",
    })

    buttons := ui.add_frame(modals.modal, {
        name    = "buttons",
        size    = {0,90},
        layout  = ui.Flow { dir=.right_center, gap=20, align=.end },
    })

    for i in 1..=max_buttons {
        name := fmt.tprintf("button_%i", i)
        button := partials.add_button(buttons, name, "")
        button.size_min = {140,0}
    }
}

open_modal_listener :: proc (args: events.Args) {
    args := args.(events.Open_Modal)
    assert(args.target != nil)

    title := ui.get(modals.modal, "title")
    ui.set_text(title, args.title)

    message := ui.get(modals.modal, "message")
    ui.set_text(message, args.message)

    buttons := ui.get(modals.modal, "buttons")
    assert(len(buttons.children) >= len(args.buttons))
    ui.hide_children(buttons)
    for b, i in args.buttons {
        button := buttons.children[i]
        ui.set_text(button, b.text, shown=true)
        switch b.role {
        case .click:
            button.click = b.click
        case .cancel:
            button.click = proc (f: ^ui.Frame) {
                events.close_modal({ target=modals.target })
            }
        }
    }

    modals.target = args.target
    ui.animate(modals.modal, anim_modal_appear, .222)
}

close_modal_listener :: proc (args: events.Args) {
    args := args.(events.Close_Modal)
    assert(args.target != nil)
    assert(args.target == modals.target)

    modals.target = nil
    ui.animate(modals.modal, anim_modal_disappear, .222)
}

anim_modal_appear :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 {
        ui.show(modals.layer)
        f.flags += {.pass}
    }

    ui.set_opacity(modals.layer, f.anim.ratio)
    f.offset = { -80 + 80 * ease.cubic_out(f.anim.ratio), 0 }

    if f.anim.ratio == 1 {
        f.flags -= {.pass}
        f.offset = 0
        ui.set_opacity(modals.layer, 1)
    }
}

anim_modal_disappear :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 {
        f.flags += {.pass}
    }

    ui.set_opacity(modals.layer, 1-f.anim.ratio)
    f.offset = { 80 * ease.cubic_in(f.anim.ratio), 0 }

    if f.anim.ratio == 1 {
        f.flags -= {.pass}
        f.offset = 0
        ui.hide(modals.layer)
    }
}
