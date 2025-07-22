package credits

import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

@private screen: struct {
    using screen    : partials.Screen,
    is_autoscroll   : bool,
}

add :: proc (parent: ^ui.Frame) {
    screen.screen = partials.add_screen(parent, "credits")

    screen.root.show = proc (f: ^ui.Frame) {
        // reset state each time credits screen is opened
        ui.scroll(ui.get(f, "pages/credits/content"), 0)
        ui.show(screen.key_buttons, "autoscroll_on")
        ui.hide(screen.key_buttons, "autoscroll_off")
        screen.is_autoscroll = false
    }

    close := partials.add_screen_key_button(&screen, "close", "<icon=key/Esc:1.4:1> Close")
    close.click = proc (f: ^ui.Frame) {
        events.open_screen({ screen_name="home" })
    }

    as_off := partials.add_screen_key_button(&screen, "autoscroll_off", "<icon=key/D> Disable Auto-Scroll")
    as_off.click = proc (f: ^ui.Frame) {
        screen.is_autoscroll = false
        ui.show(f, "../autoscroll_on")
        ui.hide(f)
    }

    as_on := partials.add_screen_key_button(&screen, "autoscroll_on", "<icon=key/E> Enable Auto-Scroll")
    as_on.click = proc (f: ^ui.Frame) {
        screen.is_autoscroll = true
        ui.show(f, "../autoscroll_off")
        ui.hide(f)
    }

    add_credits_page()

    ui.click(screen.tabs, "credits")
}

@private
add_credits_page :: proc () {
    _, page := partials.add_screen_tab_and_page(&screen, "credits", "CREDITS")

    content_pad :: 320
    track_pad_x :: 80
    track_pad_y :: 40

    content := ui.add_frame(page, {
        name    = "content",
        flags   = {.scissor},
        layout  = ui.Flow { dir=.down, scroll={step=30} },
        tick    = proc (f: ^ui.Frame) {
            if screen.is_autoscroll do ui.wheel(f, -.011)
        },
    },
        { point=.top_left, offset={content_pad,0} },
        { point=.bottom_right, offset={-content_pad,0} },
    )

    text, track, _ := partials.add_text_and_scrollbar(content)

    text.text_format = "<pad=0:40,wrap,left,font=text_4l,color=primary>%s"
    ui.set_text(text, data.credits_text)

    track.anchors[0].offset = {track_pad_x,track_pad_y}
    track.anchors[1].offset = {track_pad_x,-track_pad_y}

    // redirect page wheel events to the content, so its possible to scroll even if mouse doesn't hit content
    page.wheel = proc (f: ^ui.Frame, dy: f32) -> bool {
        return ui.wheel(f, "content", dy)
    }
}
