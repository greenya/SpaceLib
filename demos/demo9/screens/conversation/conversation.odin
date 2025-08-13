package conversation

import "core:fmt"
import "core:math/ease"

import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

@private screen: struct {
    using screen: partials.Screen,

    talk        : ^ui.Frame,
    replies     : ^ui.Frame,

    current_talk: events.Start_Conversation,
    next_talk   : events.Start_Conversation,
}

max_replies :: 8

add :: proc (parent: ^ui.Frame) {
    screen.screen = partials.add_screen(parent, "conversation", is_empty=true)

    pad_x :: 300
    pad_y :: 40

    screen.replies = ui.add_frame(screen.root, {
        name    = "replies",
        layout  = ui.Flow { dir=.down, gap=10, auto_size={.height} },
    },
        { point=.bottom_left, offset={300,-40} },
        { point=.bottom_right, offset={-300,-40} },
    )

    for i in 1..=max_replies {
        ui.add_frame(screen.replies, {
            name        = fmt.tprintf("reply_%i", i),
            flags       = {.capture,.terse,.terse_height},
            text_format = "<wrap,left,pad=15:5,font=text_4l,color=primary_l8>%s",
            draw        = partials.draw_conversation_reply,
            click       = click_conversation_reply,
        })
    }

    screen.talk = ui.add_frame(screen.root, {
        name        = "talk",
        flags       = {.terse,.terse_height},
        text_format = "<wrap,pad=15:10,font=text_4r,color=primary>%s    <font=text_4l,color=primary_l8>%s",
        draw        = partials.draw_hexagon_rect_hangout_short_lines,
    },
        { point=.bottom_left, rel_point=.top_left, rel_frame=screen.replies, offset={0,-30} },
        { point=.bottom_right, rel_point=.top_right, rel_frame=screen.replies, offset={0,-30} },
    )

    // ui.print_frame_tree(screen)

    events.listen(.start_conversation, start_conversation_listener)
}

@private
start_conversation_listener :: proc (args: events.Args) {
    events.open_screen({ screen_name="conversation" })

    args := args.(events.Start_Conversation)
    conversation_id, chat_id, chat_text_override := args.conversation_id, args.chat_id, args.chat_text_override
    assert(conversation_id != "")
    assert(chat_id != "")

    conversation, chat := data.get_conversation_chat(conversation_id, chat_id)
    if screen.current_talk == {} do fmt.println("[conversation start]", conversation.npc_name)

    chat_text := chat_text_override != ""\
        ? chat_text_override\
        : chat.text != ""\
            ? chat.text\
            : "..."

    ui.set_text(screen.talk, conversation.npc_name, chat_text)

    assert(len(screen.replies.children) >= len(chat.replies))
    ui.hide_children(screen.replies)
    for r, i in chat.replies {
        reply := screen.replies.children[i]
        icon := data.conversation_reply_action_icon[r.action]
        text := icon != ""\
            ? fmt.tprintf("<icon=%s> %s", icon, r.text)\
            : r.text
        ui.set_text(reply, text, shown=true)
    }

    ui.update(screen.root)

    screen.current_talk = args
}

@private
click_conversation_reply :: proc (f: ^ui.Frame) {
    reply_idx := ui.index(f)
    fmt.println("[reply clicked]", reply_idx)

    _, chat := data.get_conversation_chat(screen.current_talk.conversation_id, screen.current_talk.chat_id)
    reply := chat.replies[reply_idx]

    if reply.action != .none {
        fmt.println("[reply action]", reply.action)
        if reply.action == .close {
            events.open_screen({ screen_name="player" })
        }
    } else {
        next_chat_id := reply.next != "" ? reply.next : chat.id
        screen.next_talk = {
            conversation_id     = screen.current_talk.conversation_id,
            chat_id             = next_chat_id,
            chat_text_override  = reply.next_text,
        }
        ui.animate(screen.root, anim_next_talk, .222)
    }
}

@private
anim_next_talk :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 {
        screen.root.flags += {.pass}
        ui.set_opacity(screen.root, 0)
        events.start_conversation(screen.next_talk)
    }

    ratio := ease.cubic_in(f.anim.ratio)
    ui.set_opacity(screen.root, ratio)

    if f.anim.ratio == 1 {
        ui.set_opacity(screen.root, 1)
        screen.root.flags -= {.pass}
    }
}
