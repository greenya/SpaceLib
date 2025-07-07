package demo9_screens

import "core:fmt"
import "core:math/rand"

import "spacelib:ui"

import "../events"
import "../partials"
import "credits"
import "home"
import "player"
import "settings"

@private screens: ^ui.Frame

@private transition: struct {
    curtain: ^ui.Frame,
    prev_screen: ^ui.Frame,
    next_screen: ^ui.Frame,
}

add :: proc (parent: ^ui.Frame) {
    assert(screens == nil)

    screens = ui.add_frame(parent,
        { name="screens" },
        { point=.top_left },
        { point=.bottom_right },
    )

    transition.curtain = ui.add_frame(parent,
        { name="screen_curtain", flags={.hidden,.block_wheel}, /* we set "draw" when starting animation */ },
        { point=.top_left },
        { point=.bottom_right },
    )

    credits.add(screens)
    home.add(screens)
    player.add(screens)
    settings.add(screens)

    events.listen("open_screen", open_screen_listener)
}

@private
open_screen_listener :: proc (args: ..any) {
    screen_name, tab_name, anim := any_args_ordered_ssb(args)

    prev_screen := ui.first_visible_child(screens)
    next_screen := ui.get(screens, screen_name)
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

    transition.prev_screen = prev_screen
    transition.next_screen = next_screen
    transition.curtain.draw = rand.choice([] ui.Frame_Proc {
        partials.draw_screen_curtain_cross_smooth,
        partials.draw_screen_curtain_cross_bouncy,
    })
    ui.animate(transition.curtain, anim_tick_screen_curtain, 1.111)
}

@private
anim_tick_screen_curtain :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 {
        ui.show(f)
    }

    sr :: partials.draw_screen_curtain_cross_switch_screen_ratio
    if f.anim.ratio > sr && .hidden not_in transition.prev_screen.flags {
        ui.show(transition.next_screen, hide_siblings=true)
    }

    if f.anim.ratio == 1 {
        ui.hide(f)
    }
}
