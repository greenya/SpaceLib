package spacelib_ui

Actor :: union {
    Actor_Scrollbar_Content,
    Actor_Scrollbar_Next,
    Actor_Scrollbar_Prev,
    Actor_Scrollbar_Thumb,

    Actor_Slider_Thumb,
    Actor_Slider_Next,
    Actor_Slider_Prev,
}

@private
update_actor :: proc (f: ^Frame) {
    #partial switch _ in f.actor {
    case Actor_Scrollbar_Content: wheel_actor_scrollbar_content(f)
    case Actor_Slider_Thumb     : update_actor_slider(f)
    }
}

@private
click_actor :: proc (f: ^Frame) {
    #partial switch a in f.actor {
    case Actor_Scrollbar_Next: wheel(a.content, -1)
    case Actor_Scrollbar_Prev: wheel(a.content, +1)

    case Actor_Slider_Next: thumb, data := actor_slider(f); set_actor_slider_idx(thumb, data.idx + 1)
    case Actor_Slider_Prev: thumb, data := actor_slider(f); set_actor_slider_idx(thumb, data.idx - 1)
    }
}

@private
wheel_actor :: proc (f: ^Frame, dy := f32(0)) -> (consumed: bool) {
    #partial switch _ in f.actor {
    case Actor_Scrollbar_Content: return wheel_actor_scrollbar_content(f)
    case                        : return false
    }
}

@private
drag_actor :: proc (f: ^Frame, info: Drag_Info) {
    #partial switch _ in f.actor {
    case Actor_Scrollbar_Thumb  : drag_actor_scrollbar_thumb(f, info)
    case Actor_Slider_Thumb     : drag_actor_slider_thumb(f, info)
    }
}
