package demo9_screens_credits

import "spacelib:ui"

import "../../events"
import "../../partials"

is_autoscroll := true

add :: proc (parent: ^ui.Frame) {
    screen := ui.add_frame(parent, { name="credits",
            show=proc (f: ^ui.Frame) {
                ui.set_scroll_offset(ui.get(f, "pages/credits/content"), 0)
            },
        },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen_base(screen)

    partials.add_screen_footer_key_button(screen, "close", "Close", key="Esc",
        click=proc (f: ^ui.Frame) {
            events.send_open_screen("opening")
        },
    )

    partials.add_screen_footer_key_button(screen, "autoscroll_off", "Disable Auto-Scroll", key="D",
        click=proc (f: ^ui.Frame) {
            is_autoscroll = false
            ui.show(f, "../autoscroll_on")
            ui.hide(f)
        },
    )

    partials.add_screen_footer_key_button(screen, "autoscroll_on", "Enable Auto-Scroll", key="E", flags={.hidden},
        click=proc (f: ^ui.Frame) {
            is_autoscroll = true
            ui.show(f, "../autoscroll_off")
            ui.hide(f)
        },
    )

    add_credits_page(screen)

    ui.click(screen, "header_bar/tabs/credits")
}

@private
add_credits_page :: proc (screen: ^ui.Frame) {
    _, page := partials.add_screen_tab_and_page(screen, "credits", "CREDITS")

    content := ui.add_frame(page,
        { name="content", layout={dir=.down,scroll={step=10}}, flags={.scissor},
            tick=proc (f: ^ui.Frame) { if is_autoscroll do ui.wheel(f, -.033) } },
        { point=.top_left, offset={260,0} },
        { point=.bottom_right, offset={-260,0} },
    )

    ui.add_frame(content, {
        name="text",
        flags={.terse,.terse_height},
        text_format="<pad=0:20,wrap,left,font=text_4l,color=primary>%s",
        text=#load("credits.txt"),
    })

    track := ui.add_frame(page,
        { name="track", size={1,0}, text="primary_a2", draw=partials.draw_color_rect },
        { point=.top_left, rel_point=.top_right, rel_frame=content, offset={40,40} },
        { point=.bottom_left, rel_point=.bottom_right, rel_frame=content, offset={40,-40} },
    )

    thumb := ui.add_frame(track,
        { name="thumb", size={19,60}, draw=partials.draw_scrollbar_thumb },
        { point=.top },
    )

    ui.setup_scrollbar_actors(content, thumb)

    // redirect page wheel events to the content, so its possible to scroll even if mouse doesn't hit content
    page.wheel = proc (f: ^ui.Frame, dy: f32) -> bool {
        return ui.wheel(f, "content", dy)
    }
}
