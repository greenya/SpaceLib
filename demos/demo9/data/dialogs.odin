package data

import "core:encoding/json"
import "core:fmt"

Dialogs_Item :: struct {
    id          : string,
    npc_name    : string,
    chatter     : [] Dialog_Chat,
}

Dialog_Chat :: struct {
    id      : string,
    text    : string,
    replies : [] Dialog_Reply,
}

Dialog_Reply :: struct {
    text    : string,
    next    : string,
    action  : Dialog_Reply_Action,
}

Dialog_Reply_Action :: enum {
    none,
    close,
    trade,
    fly_to_crossroads,
}

dialog_reply_action_icon := [Dialog_Reply_Action] string {
    .none               = "",
    .close              = "close",
    .trade              = "shopping_cart",
    .fly_to_crossroads  = "travel",
}

@private dialogs: [] Dialogs_Item

@private
create_dialogs :: proc () {
    assert(dialogs == nil)

    err := json.unmarshal_any(#load("dialogs.json"), &dialogs)
    fmt.ensuref(err == nil, "Failed to load dialogs.json: %v", err)
    // fmt.printfln("%#v", dialogs)
}

@private
destroy_dialogs :: proc () {
    for d in dialogs {
        delete(d.id)
        delete(d.npc_name)
        for c in d.chatter {
            delete(c.id)
            delete(c.text)
            for r in c.replies {
                delete(r.text)
                delete(r.next)
            }
            delete(c.replies)
        }
        delete(d.chatter)
    }
    delete(dialogs)
    dialogs = nil
}

get_dialog_chat :: proc (dialog_id, chat_id: string) -> (Dialogs_Item, Dialog_Chat) {
    assert(dialog_id != "")
    assert(chat_id != "")

    // FIXME: map would be better (for dialogs only, chatter is relatively small so array is fine)
    for dialog in dialogs {
        if dialog.id == dialog_id {
            for chat in dialog.chatter {
                if chat.id == chat_id do return dialog, chat
            }
            fmt.panicf("Dialog \"%s\" has no chat \"%s\"", dialog_id, chat_id)
        }
    }

    fmt.panicf("Dialog \"%s\" is absent", dialog_id)
}
