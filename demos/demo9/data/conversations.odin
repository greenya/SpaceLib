package data

import "core:encoding/json"
import "core:fmt"

Conversation :: struct {
    id          : string,
    npc_name    : string,
    chatter     : [] Conversation_Chat,
}

Conversation_Chat :: struct {
    id      : string,
    text    : string,
    replies : [] Conversation_Reply,
}

Conversation_Reply :: struct {
    text        : string,
    next        : string,
    next_text   : string,
    action      : Conversation_Reply_Action,
}

Conversation_Reply_Action :: enum {
    none,
    close,
    trade,
    fly_to_arrakeen,
    fly_to_harko_village,
    fly_to_griffins_reach,
    fly_to_pinnacle_station,
    fly_to_crossroads,
}

conversation_reply_action_icon := [Conversation_Reply_Action] string {
    .none                       = "",
    .close                      = "close",
    .trade                      = "shopping_cart",
    .fly_to_arrakeen            = "travel",
    .fly_to_harko_village       = "travel",
    .fly_to_griffins_reach      = "travel",
    .fly_to_pinnacle_station    = "travel",
    .fly_to_crossroads          = "travel",
}

@private conversations: [] Conversation

@private
create_conversations :: proc () {
    assert(conversations == nil)

    err := json.unmarshal_any(#load("conversations.json"), &conversations)
    fmt.ensuref(err == nil, "Failed to load conversations.json: %v", err)
    // fmt.printfln("%#v", conversations)
}

@private
destroy_conversations :: proc () {
    for cn in conversations {
        delete(cn.id)
        delete(cn.npc_name)
        for c in cn.chatter {
            delete(c.id)
            delete(c.text)
            for r in c.replies {
                delete(r.text)
                delete(r.next)
                delete(r.next_text)
            }
            delete(c.replies)
        }
        delete(cn.chatter)
    }
    delete(conversations)
    conversations = nil
}

get_conversation_chat :: proc (conversation_id, chat_id: string) -> (Conversation, Conversation_Chat) {
    assert(conversation_id != "")
    assert(chat_id != "")

    for cn in conversations {
        if cn.id == conversation_id {
            for chat in cn.chatter {
                if chat.id == chat_id do return cn, chat
            }
            fmt.panicf("Conversation \"%s\" has no chat \"%s\"", conversation_id, chat_id)
        }
    }

    fmt.panicf("Conversation \"%s\" is absent", conversation_id)
}

get_conversation_ids :: proc (allocator := context.allocator) -> [] string {
    result := make([dynamic] string, allocator)
    for cn in conversations do append(&result, cn.id)
    return result[:]
}
