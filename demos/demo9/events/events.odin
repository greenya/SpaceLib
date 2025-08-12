package events

// import "core:fmt"
import "core:slice"
import "spacelib:ui"

ID :: enum {
    close_dropdown,
    close_modal,
    container_updated,
    exit_app,
    open_dropdown,
    open_modal,
    open_screen,
    push_notification,
    set_dropdown_data,
    start_conversation,
}

Args :: union {
    Close_Dropdown,
    Close_Modal,
    Container_Updated,
    Open_Dropdown,
    Open_Modal,
    Open_Screen,
    Push_Notification,
    Set_Dropdown_Data,
    Start_Conversation,
}

close_dropdown :: proc (args: Close_Dropdown) { send(.close_dropdown, args) }
Close_Dropdown :: struct {
    target: ^ui.Frame `fmt:"p"`,
}

close_modal :: proc (args: Close_Modal) { send(.close_modal, args) }
Close_Modal :: struct {
    target: ^ui.Frame `fmt:"p"`,
}

container_updated :: proc (args: Container_Updated) { send(.container_updated, args) }
Container_Updated :: struct {
    container: rawptr,
}

exit_app :: proc () { send(.exit_app) }

open_dropdown :: proc (args: Open_Dropdown) { send(.open_dropdown, args) }
Open_Dropdown :: struct {
    target: ^ui.Frame `fmt:"p"`,
}

open_modal :: proc (args: Open_Modal) { send(.open_modal, args) }
Open_Modal :: struct {
    target  : ^ui.Frame `fmt:"p"`,
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

open_screen :: proc (args: Open_Screen) { send(.open_screen, args) }
Open_Screen :: struct {
    screen_name : string,
    tab_name    : string,
    skip_anim   : bool,
}

push_notification :: proc (args: Push_Notification) { send(.push_notification, args) }
Push_Notification :: struct {
    type    : Push_Notification_Type,
    title   : string,
    text    : string,
}
Push_Notification_Type :: enum {
    info,
    error,
}

set_dropdown_data :: proc (args: Set_Dropdown_Data) { send(.set_dropdown_data, args) }
Set_Dropdown_Data :: struct {
    target  : ^ui.Frame `fmt:"p"`,
    selected: ^ui.Frame `fmt:"p"`,
    names   : [] string,
    titles  : [] string,
}

start_conversation :: proc (args: Start_Conversation) { send(.start_conversation, args) }
Start_Conversation :: struct {
    conversation_id     : string,
    chat_id             : string,
    chat_text_override  : string,
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
    // fmt.printfln("[send] %v |%i| %#v", id, len(events[id].listeners), args)
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

listen :: proc (id: ID, listener: Listener, on_listener_duplication: enum { panic, skip } = .panic) {
    event := get(id)

    i, _ := slice.linear_search(event.listeners[:], listener)
    if i >= 0 do switch on_listener_duplication {
        case .panic : panic("Listener duplication")
        case .skip  : return
    }

    append(&event.listeners, listener)
}
