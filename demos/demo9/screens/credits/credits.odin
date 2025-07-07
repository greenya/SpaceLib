package demo9_screens_credits

import "spacelib:ui"

import "../../events"
import "../../partials"

@private screen: ^ui.Frame
@private is_autoscroll: bool

add :: proc (parent: ^ui.Frame) {
    screen = ui.add_frame(parent, { name="credits",
            show=proc (f: ^ui.Frame) {
                // reset state each time credits screen is opened
                ui.set_scroll_offset(ui.get(f, "pages/credits/content"), 0)
                ui.show(f, "footer_bar/key_buttons/autoscroll_on")
                ui.hide(f, "footer_bar/key_buttons/autoscroll_off")
                is_autoscroll = false
            },
        },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen_base(screen)

    partials.add_screen_footer_key_button(screen, "close", "Close", key="Esc",
        click=proc (f: ^ui.Frame) {
            events.send_open_screen("home")
        },
    )

    partials.add_screen_footer_key_button(screen, "autoscroll_off", "Disable Auto-Scroll", key="D",
        click=proc (f: ^ui.Frame) {
            is_autoscroll = false
            ui.show(f, "../autoscroll_on")
            ui.hide(f)
        },
    )

    partials.add_screen_footer_key_button(screen, "autoscroll_on", "Enable Auto-Scroll", key="E",
        click=proc (f: ^ui.Frame) {
            is_autoscroll = true
            ui.show(f, "../autoscroll_off")
            ui.hide(f)
        },
    )

    add_credits_page()

    ui.click(screen, "header_bar/tabs/credits")
}

@private
add_credits_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "credits", "CREDITS")

    content_pad :: 320
    track_pad_x :: 80
    track_pad_y :: 40

    content := ui.add_frame(page,
        { name="content", layout={dir=.down,scroll={step=10}}, flags={.scissor},
            tick=proc (f: ^ui.Frame) { if is_autoscroll do ui.wheel(f, -.033) } },
        { point=.top_left, offset={content_pad,0} },
        { point=.bottom_right, offset={-content_pad,0} },
    )

    text, track, _ := partials.add_text_and_scrollbar(content)

    text.text_format = "<pad=0:40,wrap,left,font=text_4l,color=primary>%s"
    ui.set_text(text, #load("credits.txt"))

    track.anchors[0].offset = {track_pad_x,track_pad_y}
    track.anchors[1].offset = {track_pad_x,-track_pad_y}

    // redirect page wheel events to the content, so its possible to scroll even if mouse doesn't hit content
    page.wheel = proc (f: ^ui.Frame, dy: f32) -> bool {
        return ui.wheel(f, "content", dy)
    }
}
