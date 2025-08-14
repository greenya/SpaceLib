#+private
package interface

import "core:fmt"
import "core:math/ease"
import "core:strings"

import "spacelib:ui"

import "../data"
import "../events"
import "../partials"

modals: struct {
    layer   : ^ui.Frame,
    modal   : ^ui.Frame,
    state   : struct {
        target  : ^ui.Frame,
        pages   : [] events.Open_Modal_Page,
        page_idx: int,
    },
}

max_buttons :: 4
max_pages   :: 8

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

destroy_modals_layer :: proc () {
    destroy_modal_state_pages()
}

destroy_modal_state_pages :: proc () {
    for p in modals.state.pages {
        delete(p.title)
        delete(p.message)
    }
    delete(modals.state.pages)
    modals.state = {}
}

add_modal :: proc () {
    modals.modal = ui.add_frame(modals.layer, {
        name    = "modal",
        size    = {680,0},
        layout  = ui.Flow { dir=.down, pad={40,40,25,35}, auto_size={.height} },
        draw    = partials.draw_window_rect,
    }, { point=.center })

    ui.add_frame(modals.modal, {
        name        = "title",
        flags       = {.terse,.terse_height},
        text_format = "<wrap,pad=30,font=text_5m,color=primary_d2>%s",
    })

    body := ui.add_frame(modals.modal, {
        name        = "body",
        flags       = {.scissor},
        layout      = ui.Flow { dir=.down, scroll={step=20}, auto_size={.height} },
        size_max    = {0,320},
    })

    ui.add_frame(body, {
        name        = "message",
        flags       = {.terse,.terse_height},
        text_format = "<wrap,font=text_4l,color=primary_d2>%s",
    })

    body_track, _ := partials.add_scrollbar(body)
    body_track.anchors[0].offset.x = 39
    body_track.anchors[1].offset.x = 39

    pagination := ui.add_frame(modals.modal, {
        name    = "pagination",
        size    = {0,50},
        layout  = ui.Flow { dir=.right_center, gap=4, align=.end },
    })

    for _ in 0..<max_pages {
        ui.add_frame(pagination, {
            flags   = {.radio},
            size    = 16,
            draw    = partials.draw_button_radio_pin,
            click   = proc (f: ^ui.Frame) { set_modal_page(ui.index(f)) },
        })
    }

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

    state := &modals.state
    state^ = { target=args.target }

    if args.instruction_id != "" {
        assert(args.pages==nil, "[modal] pages are not supposed to be used with instruction_id")
        inst := data.get_instruction(args.instruction_id)
        state.pages = make([] events.Open_Modal_Page, len(inst.pages))
        for p, i in inst.pages do state.pages[i] = {
            title   = strings.clone(p.title),
            message = data.text_to_string(p.text),
        }
    } else {
        assert(len(args.pages) > 0)
        state.pages = make([] events.Open_Modal_Page, len(args.pages))
        for p, i in args.pages do state.pages[i] = {
            title   = strings.clone(p.title),
            message = data.text_to_string(p.message),
        }
    }

    pagination := ui.get(modals.modal, "pagination")
    if len(state.pages) > 1 {
        ui.show(pagination)
        ui.hide_children(pagination)
        for i in 0..<len(state.pages) do ui.show(pagination.children[i])
        ui.click(pagination.children[0])
    } else {
        ui.hide(pagination)
    }

    args_buttons := args.buttons
    if len(args_buttons) == 0 {
        if len(state.pages) > 1 {
            args_buttons = {
                { text="<icon=key/A> Previous"      , role=.prev_page },
                { text="<icon=key/Esc:1.4:1> Close" , role=.cancel },
                { text="<icon=key/D> Next"          , role=.next_page },
            }
        } else {
            args_buttons = {
                { text="<icon=key/Esc:1.4:1> Close" , role=.cancel },
            }
        }
    }

    buttons := ui.get(modals.modal, "buttons")
    assert(len(buttons.children) >= len(args_buttons))
    ui.hide_children(buttons)
    for b, i in args_buttons {
        btn := buttons.children[i]
        ui.set_text(btn, b.text, shown=true)
        switch b.role {
        case .click:
            btn.click = b.click
        case .cancel:
            btn.click = proc (f: ^ui.Frame) {
                events.close_modal({ target=modals.state.target })
            }
        case .next_page:
            btn.click = proc (f: ^ui.Frame) {
                pagination := ui.get(modals.modal, "pagination")
                ui.select_next_child(pagination, allow_rotation=true)
            }
        case .prev_page:
            btn.click = proc (f: ^ui.Frame) {
                pagination := ui.get(modals.modal, "pagination")
                ui.select_prev_child(pagination, allow_rotation=true)
            }
        }
    }

    set_modal_page(0)

    ui.animate(modals.modal, anim_modal_appear, .222)
}

close_modal_listener :: proc (args: events.Args) {
    args := args.(events.Close_Modal)
    assert(args.target != nil)
    assert(args.target == modals.state.target)

    // we can destroy pages here, as following disappear anim will set .pass for the layer,
    // so user will not be able to click a button; the pages only needed when navigating to
    // next/prev page (and the current state is in UI frames)
    destroy_modal_state_pages()

    ui.animate(modals.modal, anim_modal_disappear, .222)
}

set_modal_page :: proc (new_page_idx: int) {
    state := &modals.state
    assert(len(state.pages) > 0)

    state.page_idx = new_page_idx
    if state.page_idx >= len(state.pages) do state.page_idx = 0
    if state.page_idx < 0 do state.page_idx = len(state.pages) - 1

    title := ui.get(modals.modal, "title")
    ui.set_text(title, state.pages[state.page_idx].title)

    message := ui.get(modals.modal, "body/message")
    ui.set_text(message, state.pages[state.page_idx].message)

    ui.update(modals.modal, repeat=3)
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
