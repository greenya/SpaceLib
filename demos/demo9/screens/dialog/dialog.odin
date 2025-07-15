package dialog

import "core:fmt"

import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

@private screen : ^ui.Frame

@private current_talk: struct {
    dialog_id   : string,
    chat_id     : string,
}

max_replies :: 8

add :: proc (parent: ^ui.Frame) {
    assert(screen == nil)
    screen = partials.add_screen(parent, "dialog", is_empty=true)

    pad_x :: 300
    pad_y :: 40

    replies := ui.add_frame(screen, {
        name    = "replies",
        layout  = {dir=.down,gap=10,auto_size=.dir},
    },
        { point=.bottom_left, offset={300,-40} },
        { point=.bottom_right, offset={-300,-40} },
    )

    for i in 1..=max_replies {
        ui.add_frame(replies, {
            name        = fmt.tprintf("reply_%i", i),
            flags       = {.capture,.terse,.terse_height},
            text_format = "<wrap,left,pad=15:5,font=text_4l,color=primary_l8>%s",
            draw        = partials.draw_dialog_reply,
            click       = click_dialog_reply,
        })
    }

    ui.add_frame(screen, {
        name        = "talk",
        flags       = {.terse,.terse_height},
        text_format = "<wrap,pad=15:10,font=text_4m,color=primary>%s    <font=text_4l,color=primary_l8>%s",
        draw        = partials.draw_hexagon_rect_hangout_short_lines,
    },
        { point=.bottom_left, rel_point=.top_left, rel_frame=replies, offset={0,-30} },
        { point=.bottom_right, rel_point=.top_right, rel_frame=replies, offset={0,-30} },
    )

    ui.print_frame_tree(screen)

    events.listen(.open_dialog, open_dialog_listener)
}

open_dialog_listener :: proc (args: events.Args) {
    args := args.(events.Open_Dialog)
    dialog_id, chat_id := args.dialog_id, args.chat_id
    assert(dialog_id != "")
    assert(chat_id != "")

    dialog, chat := data.get_dialog_chat(dialog_id, chat_id)
    fmt.println(dialog.npc_name, chat)

    talk := ui.get(screen, "talk")
    ui.set_text(talk, dialog.npc_name, chat.text != "" ? chat.text : "...")

    replies := ui.get(screen, "replies")
    assert(len(replies.children) >= len(chat.replies))
    ui.hide_children(replies)
    for r, i in chat.replies {
        reply := replies.children[i]
        icon := data.dialog_reply_action_icon[r.action]
        text := icon != ""\
            ? fmt.tprintf("<icon=%s> %s", icon, r.text)\
            : r.text
        ui.set_text(reply, text, shown=true)
    }

    current_talk = { dialog_id=dialog_id, chat_id=chat_id }
}

click_dialog_reply :: proc (f: ^ui.Frame) {
    // TODO: handle reply click
    fmt.println("click!", ui.index(f), f.name)

    _, chat := data.get_dialog_chat(current_talk.dialog_id, current_talk.chat_id)
    reply := chat.replies[ui.index(f)]

    if reply.next != "" {
        // nav to next chat_id
    } else {
        // process action
        // switch reply.action { ... }
    }
}
