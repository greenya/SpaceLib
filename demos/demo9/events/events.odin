package demo9_events

import "core:fmt"
import "core:strings"

Event_Listener :: proc (args: ..any)

Event :: struct {
    listeners: [dynamic] Event_Listener,
}

@private events: map [string] ^Event

create :: proc () {
    assert(len(events) == 0)
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

send_open_screen :: proc (screen_name: string, tab_name := "", anim := true) {
    send("open_screen", screen_name, tab_name, anim)
}

@private
send :: proc (event_name: string, args: ..any) {
    fmt.println(#procedure, event_name, args)
    if event_name in events {
        event := events[event_name]
        assert(len(event.listeners) > 0)
        for listener in event.listeners do listener(..args)
    } else {
        fmt.panicf("Event \"%s\" is unknown", event_name)
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
