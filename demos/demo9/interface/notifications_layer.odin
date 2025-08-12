#+private
package interface

// import "core:fmt"
import "core:strings"

import "spacelib:core"
import "spacelib:ui"

import "../events"
import "../partials"

notifications: struct {
    layer   : ^ui.Frame,
    cards   : ^ui.Frame,
    queue   : [dynamic] events.Push_Notification,
}

notification_cards_max_shown_at_once    :: 4
notification_cards_appear_dur           :: .333
notification_cards_disappear_dur        :: .333
notification_cards_stay_dur             :: 5

add_notifications_layer :: proc (order: int) {
    assert(notifications.layer == nil)

    notifications.layer = ui.add_frame(ui_.root, {
        name    = "notifications_layer",
        flags   = {.pass},
        order   = order,
    }, { point=.top_left }, { point=.bottom_right })

    notifications.cards = ui.add_frame(notifications.layer, {
        name    = "cards",
        size    = {400,0},
        layout  = ui.Flow{ dir=.down, gap=20 },
        tick    = proc (f: ^ui.Frame) {
            // fmt.println("---------")
            // for c, i in f.children do fmt.println(i, c.order, c.flags)
            if len(notifications.queue) == 0 do return

            card := ui.first_hidden_child(notifications.cards)
            if card != nil {
                item := pop(&notifications.queue)
                defer destroy_notification_queue_item(item)
                set_notification_card_view(card, title=item.title, text=item.text, is_error=item.is_error)
                ui.update(notifications.cards, repeat=3)
                ui.animate(card, anim_notification_card_appear, notification_cards_appear_dur)
            }
        },
    },
        { point=.top_right, offset={0,100} },
    )

    for i in 0..<notification_cards_max_shown_at_once {
        add_notification_card(order=i+1)
    }

    events.listen(.push_notification, push_notification_listener)
}

destroy_notifications_layer :: proc () {
    for item in notifications.queue do destroy_notification_queue_item(item)
    delete(notifications.queue)
}

destroy_notification_queue_item :: proc (item: events.Push_Notification) {
    delete(item.title)
    delete(item.text)
}

push_notification_listener :: proc (args: events.Args) {
    args := args.(events.Push_Notification)

    append(&notifications.queue, events.Push_Notification {
        title       = strings.clone(args.title),
        text        = strings.clone(args.text),
        is_error    = args.is_error,
    })
}

add_notification_card :: proc (order: int) {
    card := ui.add_frame(notifications.cards, {
        name="card",
        order=order,
        flags={.hidden},
        layout=ui.Flow{ dir=.down, auto_size={.height} },
        text="primary_d8",
        draw=partials.draw_color_rect,
    })

    ui.add_frame(card, {
        name="title",
        text_format="<wrap,left,pad=4,font=text_4r,color=primary>%s",
        flags={.terse,.terse_height},
    })

    ui.add_frame(card, {
        name="text",
        text_format="<wrap,left,pad=20:10,font=text_4l,color=primary>%s",
        flags={.terse,.terse_height},
    })
}

set_notification_card_view :: proc (card: ^ui.Frame, title, text: string, is_error: bool) {
    card_title := ui.get(card, "title")
    ui.set_text(card_title, title)
    card_title.draw = is_error\
        ? partials.draw_hexagon_rect_wide_hangout_error\
        : partials.draw_hexagon_rect_wide_hangout_accent

    card_text := ui.get(card, "text")
    ui.set_text(card_text, text)
}

anim_notification_card_appear :: proc (f: ^ui.Frame) {
    switch f.anim.ratio {
    case 0:
        f.offset = {f.rect.w,0}
        ui.set_opacity(f, 0)
        ui.show(f)
    case:
        ratio := core.ease_ratio(f.anim.ratio, .Cubic_Out)
        f.offset = {f.rect.w*(1-ratio),0}
        ui.set_opacity(f, ratio)
    case 1:
        f.offset = 0
        ui.set_opacity(f, 1)
        ui.animate(f, anim_notification_card_stay, notification_cards_stay_dur)
    }
}

anim_notification_card_stay :: proc (f: ^ui.Frame) {
    switch f.anim.ratio {
    case 1:
        ui.animate(f, anim_notification_card_disappear, notification_cards_disappear_dur)
    }
}

anim_notification_card_disappear :: proc (f: ^ui.Frame) {
    switch f.anim.ratio {
    case:
        ratio := core.ease_ratio(f.anim.ratio, .Cubic_In)
        f.offset = {f.rect.w*ratio,0}
        ui.set_opacity(f, 1-ratio)
    case 1:
        ui.hide(f)
        ui.set_order(f, f.order + notification_cards_max_shown_at_once) // move this card to the end
    }
}
