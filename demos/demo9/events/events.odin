package events

import "core:fmt"
import "spacelib:ui"

ID :: enum {
    exit_app,
    open_screen,
    set_dropdown_data,
    open_dropdown,
    close_dropdown,
    open_modal,
}

Args :: union {
    Open_Screen,
    Set_Dropdown_Data,
    Open_Dropdown,
    Close_Dropdown,
    Open_Modal,
}

exit_app :: proc () { send(.exit_app) }

open_screen :: proc (args: Open_Screen) { send(.open_screen, args) }
Open_Screen :: struct {
    screen_name : string,
    tab_name    : string,
    skip_anim   : bool,
}

set_dropdown_data :: proc (args: Set_Dropdown_Data) { send(.set_dropdown_data, args) }
Set_Dropdown_Data :: struct {
    target  : ^ui.Frame `fmt:"p"`,
    selected: ^ui.Frame `fmt:"p"`,
    names   : [] string,
    titles  : [] string,
}

open_dropdown :: proc (args: Open_Dropdown) { send(.open_dropdown, args) }
Open_Dropdown :: struct {
    target: ^ui.Frame `fmt:"p"`,
}

close_dropdown :: proc (args: Close_Dropdown) { send(.close_dropdown, args) }
Close_Dropdown :: struct {
    target: ^ui.Frame `fmt:"p"`,
}

open_modal :: proc (args: Open_Modal) { send(.open_modal, args) }
Open_Modal :: struct {
    title   : string,
    message : string,
    buttons : [] Open_Modal_Button,
}
Open_Modal_Button :: struct {
    text    : string,
    role    : Open_Modal_Button_Role,
    click   : ui.Frame_Proc,
}
Open_Modal_Button_Role :: enum {
    click,
    cancel,
}

Event :: struct {
    listeners: [dynamic] Listener,
}

Listener :: proc (args: Args)

@private events: map [ID] ^Event

@private
get :: #force_inline proc (id: ID) -> ^Event {
    assert(id in events)
    return events[id]
}

@private
send :: #force_inline proc (id: ID, args: Args = nil) {
    fmt.printfln("[send] %v |%i| %#v", id, len(events[id].listeners), args)
    for l in events[id].listeners do l(args)
}

create :: proc () {
    assert(events == nil)
    for id in ID do events[id] = new(Event)
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
