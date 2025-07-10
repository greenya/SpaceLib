package demo9_screens

import "core:fmt"
import "core:math/rand"

import "spacelib:ui"

import "../events"
import "partials"
import "screens/credits"
import "screens/home"
import "screens/player"
import "screens/settings"

@private screens_layer  : ^ui.Frame
@private dropdown_layer : ^ui.Frame
@private curtain_layer  : ^ui.Frame

@private screens_transition: struct { prev, next: ^ui.Frame }

add :: proc (parent: ^ui.Frame) {
    assert(screens_layer == nil)
    assert(dropdown_layer == nil)
    assert(curtain_layer == nil)

    screens_layer = ui.add_frame(parent,
        { name="screens_layer" },
        { point=.top_left },
        { point=.bottom_right },
    )

    dropdown_layer = ui.add_frame(parent,
        { name="dropdown_layer", flags={.hidden,.block_wheel} },
        { point=.top_left },
        { point=.bottom_right },
    )

    curtain_layer = ui.add_frame(parent,
        { name="curtain_layer", flags={.hidden,.block_wheel} },
        { point=.top_left },
        { point=.bottom_right },
    )

    credits.add(screens_layer)
    home.add(screens_layer)
    player.add(screens_layer)
    settings.add(screens_layer)

    events.listen("open_screen", open_screen_listener)
}

@private
open_screen_listener :: proc (args: ..any) {
    screen_name, tab_name, anim := any_args_ordered_ssb(args)

    prev_screen := ui.first_visible_child(screens_layer)
    next_screen := ui.get(screens_layer, screen_name)
    fmt.assertf(next_screen != nil, "Screen \"%s\" doesn't exist", screen_name)

    if tab_name != "" {
        tab := ui.get(next_screen, fmt.tprintf("header_bar/tabs/%s", tab_name))
        fmt.assertf(tab != nil, "Screen \"%s\" doesn't have tab \"%s\"", screen_name, tab_name)
        ui.click(tab)
    }

    if anim && prev_screen != nil {
        anim_start_screen_transition(prev_screen, next_screen)
    } else {
        ui.show(next_screen, hide_siblings=true)
    }
}

@private
anim_start_screen_transition :: proc (prev_screen, next_screen: ^ui.Frame) {
    assert(prev_screen != next_screen)
    assert(prev_screen != nil)
    assert(next_screen != nil)

    screens_transition = { prev=prev_screen, next=next_screen }
    curtain_layer.draw = rand.choice([] ui.Frame_Proc {
        partials.draw_screen_curtain_cross_smooth,
        partials.draw_screen_curtain_cross_bouncy,
    })

    ui.animate(curtain_layer, anim_tick_screen_curtain, 1.111)
}

@private
anim_tick_screen_curtain :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 {
        ui.show(f)
    }

    sr :: partials.draw_screen_curtain_cross_switch_screen_ratio
    if f.anim.ratio > sr && .hidden not_in screens_transition.prev.flags {
        ui.show(screens_transition.next, hide_siblings=true)
    }

    if f.anim.ratio == 1 {
        ui.hide(f)
    }
}
