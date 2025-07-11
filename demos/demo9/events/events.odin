package demo9_events

import "core:fmt"
import "core:strings"

import "spacelib:ui"

Event_Listener :: proc (args: Args)

Event :: struct {
    listeners: [dynamic] Event_Listener,
}

Args :: struct {
    s1, s2  : [] string,
    i1      : [] int,
    f1      : [] f32,
    b1      : [] bool,
    frame1  : [] ^ui.Frame,
}

@private events: map [string] ^Event

create :: proc () {
    assert(events == nil)
}

destroy :: proc () {
    for name, event in events {
        delete(name)
        delete(event.listeners)
        free(event)
    }
    delete(events)
    events = {}
}

listen :: proc (event_name: string, listener: Event_Listener) {
    append(&get(event_name).listeners, listener)
}

exit_app :: proc () {
    send(#procedure)
}

open_screen :: proc (screen_name: string, tab_name := "", anim := true) {
    send(#procedure, { s1={screen_name,tab_name}, b1={anim} })
}

set_dropdown_data :: proc (target, selected: ^ui.Frame, names, titles: [] string) {
    send(#procedure, { frame1={target,selected}, s1=names, s2=titles })
}

open_dropdown :: proc (target: ^ui.Frame) {
    send(#procedure, { frame1={target} })
}

close_dropdown :: proc (target: ^ui.Frame = nil) {
    send(#procedure, { frame1={target} })
}

@private
send :: proc (event_name: string, event_args: Args = {}) {
    // fmt.println(#procedure, event_name, event_args)
    if event_name in events {
        event := events[event_name]
        assert(len(event.listeners) > 0)
        for listener in event.listeners do listener(event_args)
    } else {
        fmt.panicf("Event \"%s\" has no listeners", event_name)
    }
}

@private
get :: #force_inline proc (name: string) -> ^Event {
    name := name
    if name not_in events {
        name = strings.clone(name)
        events[name] = new(Event)
    }
    return events[name]
}
