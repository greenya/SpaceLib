package dialog

import "core:fmt"

import "spacelib:core"
import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

@private screen: struct {
    using screen: partials.Screen,

    talk        : ^ui.Frame,
    replies     : ^ui.Frame,

    current_talk: events.Open_Dialog,
    next_talk   : events.Open_Dialog,
}

max_replies :: 8

add :: proc (parent: ^ui.Frame) {
    screen.screen = partials.add_screen(parent, "dialog", is_empty=true)

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
            draw        = partials.draw_dialog_reply,
            click       = click_dialog_reply,
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

    events.listen(.open_dialog, open_dialog_listener)
}

@private
open_dialog_listener :: proc (args: events.Args) {
    events.open_screen({ screen_name="dialog" })

    args := args.(events.Open_Dialog)
    dialog_id, chat_id, chat_text_override := args.dialog_id, args.chat_id, args.chat_text_override
    assert(dialog_id != "")
    assert(chat_id != "")

    dialog, chat := data.get_dialog_chat(dialog_id, chat_id)
    if screen.current_talk == {} do fmt.println("[dialog start]", dialog.npc_name)

    chat_text := chat_text_override != ""\
        ? chat_text_override\
        : chat.text != ""\
            ? chat.text\
            : "..."

    ui.set_text(screen.talk, dialog.npc_name, chat_text)

    assert(len(screen.replies.children) >= len(chat.replies))
    ui.hide_children(screen.replies)
    for r, i in chat.replies {
        reply := screen.replies.children[i]
        icon := data.dialog_reply_action_icon[r.action]
        text := icon != ""\
            ? fmt.tprintf("<icon=%s> %s", icon, r.text)\
            : r.text
        ui.set_text(reply, text, shown=true)
    }

    screen.current_talk = args
}

@private
click_dialog_reply :: proc (f: ^ui.Frame) {
    reply_idx := ui.index(f)
    fmt.println("[reply clicked]", reply_idx)

    _, chat := data.get_dialog_chat(screen.current_talk.dialog_id, screen.current_talk.chat_id)
    reply := chat.replies[reply_idx]

    if reply.action != .none {
        fmt.println("[reply action]", reply.action)
        if reply.action == .close {
            events.open_screen({ screen_name="player" })
        }
    } else {
        next_chat_id := reply.next != "" ? reply.next : chat.id
        screen.next_talk = {
            dialog_id           = screen.current_talk.dialog_id,
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
        events.open_dialog(screen.next_talk)
    }

    ratio := core.ease_ratio(f.anim.ratio, .Cubic_In)
    ui.set_opacity(screen.root, ratio)

    if f.anim.ratio == 1 {
        ui.set_opacity(screen.root, 1)
        screen.root.flags -= {.pass}
    }
}
