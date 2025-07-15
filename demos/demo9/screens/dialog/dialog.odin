package dialog

import "core:fmt"

import "spacelib:core"
import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

@private screen : ^ui.Frame
@private current_talk, next_talk: events.Open_Dialog

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
        text_format = "<wrap,pad=15:10,font=text_4r,color=primary>%s    <font=text_4l,color=primary_l8>%s",
        draw        = partials.draw_hexagon_rect_hangout_short_lines,
    },
        { point=.bottom_left, rel_point=.top_left, rel_frame=replies, offset={0,-30} },
        { point=.bottom_right, rel_point=.top_right, rel_frame=replies, offset={0,-30} },
    )

    // ui.print_frame_tree(screen)

    events.listen(.open_dialog, open_dialog_listener)
}

@private
open_dialog_listener :: proc (args: events.Args) {
    args := args.(events.Open_Dialog)
    dialog_id, chat_id, chat_text_override := args.dialog_id, args.chat_id, args.chat_text_override
    assert(dialog_id != "")
    assert(chat_id != "")

    dialog, chat := data.get_dialog_chat(dialog_id, chat_id)
    if current_talk == {} do fmt.println("[dialog start]", dialog.npc_name)

    talk := ui.get(screen, "talk")
    chat_text := chat_text_override != ""\
        ? chat_text_override\
        : chat.text != ""\
            ? chat.text\
            : "..."

    ui.set_text(talk, dialog.npc_name, chat_text)

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

    current_talk = args
}

@private
click_dialog_reply :: proc (f: ^ui.Frame) {
    reply_idx := ui.index(f)
    fmt.println("[reply clicked]", reply_idx)

    _, chat := data.get_dialog_chat(current_talk.dialog_id, current_talk.chat_id)
    reply := chat.replies[reply_idx]

    if reply.action != .none {
        fmt.println("[reply action]", reply.action)
    } else {
        next_chat_id := reply.next != "" ? reply.next : chat.id
        next_talk = {
            dialog_id           = current_talk.dialog_id,
            chat_id             = next_chat_id,
            chat_text_override  = reply.next_text,
        }
        ui.animate(screen, anim_next_talk, .222)
    }
}

@private
anim_next_talk :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 {
        screen.flags += {.pass}
        ui.set_opacity(screen, 0)
        events.open_dialog(next_talk)
    }

    ratio := core.ease_ratio(f.anim.ratio, .Cubic_In)
    ui.set_opacity(screen, ratio)

    if f.anim.ratio == 1 {
        ui.set_opacity(screen, 1)
        screen.flags -= {.pass}
    }
}
