#+private
package interface

import "core:fmt"
import "core:math/rand"

import "spacelib:ui"

import "../events"
import "../partials"

screens: struct {
    layer           : ^ui.Frame,
    curtain_layer   : ^ui.Frame,
    transition      : struct { prev, next: ^ui.Frame },
}

add_screens_layer :: proc (order, curtain_order: int) {
    assert(screens.layer == nil)

    screens.layer = ui.add_frame(ui_.root,
        { name="screens_layer", order=order },
        { point=.top_left },
        { point=.bottom_right },
    )

    screens.curtain_layer = ui.add_frame(ui_.root,
        { name="curtain_layer", order=curtain_order, flags={.hidden,.block_wheel} },
        { point=.top_left },
        { point=.bottom_right },
    )

    events.listen(.open_screen, open_screen_listener)
}

open_screen_listener :: proc (args: events.Args) {
    args := args.(events.Open_Screen)
    screen_name, tab_name, skip_anim := args.screen_name, args.tab_name, args.skip_anim
    // fmt.printfln("open screen: %s, tab=%s", screen_name, tab_name != "" ? tab_name : "<not set>")

    prev_screen := ui.first_visible_child(screens.layer)
    next_screen := ui.get(screens.layer, screen_name)
    fmt.assertf(next_screen != nil, "Screen \"%s\" doesn't exist", screen_name)

    if tab_name != "" {
        fmt.println("[screens] preselect tab:", tab_name)
        tab := ui.find(next_screen, fmt.tprintf("header_bar/tabs/%s", tab_name))
        fmt.assertf(tab != nil, "Screen \"%s\" doesn't have tab \"%s\"", screen_name, tab_name)
        ui.click(tab)
    }

    if !skip_anim && prev_screen != nil {
        if next_screen != prev_screen {
            fmt.println("[screens] open (anim):", next_screen.name)
            anim_start_screen_transition(prev_screen, next_screen)
        }
    } else {
        fmt.println("[screens] open (instant):", next_screen.name)
        ui.show(next_screen, hide_siblings=true)
    }
}

anim_start_screen_transition :: proc (prev_screen, next_screen: ^ui.Frame) {
    assert(prev_screen != next_screen)
    assert(prev_screen != nil)
    assert(next_screen != nil)

    screens.transition = { prev=prev_screen, next=next_screen }
    screens.curtain_layer.draw = rand.choice([] ui.Frame_Proc {
        partials.draw_screen_curtain_cross_smooth,
        partials.draw_screen_curtain_cross_bouncy,
    })

    ui.animate(screens.curtain_layer, anim_tick_screen_curtain, 1.234)
}

anim_tick_screen_curtain :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 {
        fmt.println("[screens] anim start")
        ui.show(f)
    }

    sr :: partials.draw_screen_curtain_cross_switch_screen_ratio
    if f.anim.ratio > sr && .hidden not_in screens.transition.prev.flags {
        fmt.println("[screens] switching now")
        ui.show(screens.transition.next, hide_siblings=true)
    }

    if f.anim.ratio == 1 {
        fmt.println("[screens] anim end")
        ui.hide(f)
    }
}
