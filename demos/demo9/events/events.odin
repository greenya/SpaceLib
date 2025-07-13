package events

// import "core:fmt"
import "spacelib:ui"

ID :: enum {
    exit_app,
    open_screen,
    set_dropdown_data,
    open_dropdown,
    close_dropdown,
}

Args :: union {
    Open_Screen,
    Set_Dropdown_Data,
    Open_Dropdown,
    Close_Dropdown,
}

exit_app :: proc () { send(.exit_app) }

open_screen :: proc (args: Open_Screen) { send(.open_screen, args) }
Open_Screen :: struct { screen_name, tab_name: string, skip_anim: bool }

set_dropdown_data :: proc (args: Set_Dropdown_Data) { send(.set_dropdown_data, args) }
Set_Dropdown_Data :: struct { target, selected: ^ui.Frame, names, titles: [] string }

open_dropdown :: proc (args: Open_Dropdown) { send(.open_dropdown, args) }
Open_Dropdown :: struct { target: ^ui.Frame }

close_dropdown :: proc (args: Close_Dropdown) { send(.close_dropdown, args) }
Close_Dropdown :: struct { target: ^ui.Frame }

Event :: struct {
    listeners: [dynamic] Listener,
}

Listener :: proc (args: Args)

@private events: map [ID] ^Event

@private get :: #force_inline proc (id: ID) -> ^Event {
    if id not_in events do events[id] = new(Event)
    return events[id]
}

@private send :: #force_inline proc (id: ID, args: Args = nil) {
    // fmt.printfln("[send] %v |%i| %#v", name, len(events[name].listeners), args)
    for l in events[id].listeners do l(args)
}

create :: proc () {
    assert(events == nil)
}

destroy :: proc () {
    for _, event in events {
        delete(event.listeners)
        free(event)
    }
    delete(events)
    events = {}
}

listen :: proc (id: ID, listener: Listener) {
    append(&get(id).listeners, listener)
}
