package credits

import "core:fmt"

import "spacelib:terse"
import "spacelib:ui"

import "../../colors"
import "../../data"
import "../../events"
import "../../partials"

@private screen: struct {
    using screen    : partials.Screen,

    autoscroll          : ^ui.Frame,
    autoscroll_enabled  : bool,

    view_source         : ^ui.Frame,
    view_source_enabled : bool,

    lorem_content       : ^ui.Frame,
    lorem_info          : ^ui.Frame,
    lorem_info_target   : ^terse.Terse,
    lorem_offset_target : f32, // -1 for no target
}

add :: proc (parent: ^ui.Frame) {
    screen.screen = partials.add_screen(parent, "credits")

    screen.root.show = proc (f: ^ui.Frame) {
        // reset state each time credits screen is opened
        if screen.autoscroll_enabled do ui.click(screen.autoscroll)
        ui.scroll_abs(ui.get(f, "pages/credits/content"), 0)
        ui.click(screen.tabs, "credits")
    }

    close := partials.add_screen_key_button(&screen, "close", "<icon=key/Esc:1.4:1> Close")
    close.click = proc (f: ^ui.Frame) {
        events.open_screen({ screen_name="home" })
    }

    add_credits_page()
    add_lorem_ipsum_page()

    // ui.print_frame_tree(screen.root)
}

@private
add_credits_page :: proc () {
    _, page := partials.add_screen_tab_and_page(&screen, "credits", "CREDITS")

    content := add_content(page, data.credits_text)
    content.tick = proc (f: ^ui.Frame) {
        if screen.autoscroll_enabled {
            ui.wheel(f, -f.ui.clock.dt)

            flow := ui.layout_flow(f)
            if flow.scroll.offset == flow.scroll.offset_max {
                // turn off autoscroll when scrolled to the end
                ui.click(screen.autoscroll)
            }
        }
    }

    {
        text_on  :: "<icon=key/E> Enable Auto-Scroll"
        text_off :: "<icon=key/D> Disable Auto-Scroll"

        screen.autoscroll = partials.add_screen_key_button(&screen, "autoscroll", text_on)
        screen.autoscroll.click = proc (f: ^ui.Frame) {
            screen.autoscroll_enabled ~= true
            ui.set_text(f, screen.autoscroll_enabled ? text_off : text_on)
        }
    }

    {
        text_on  :: "View Source Text"
        text_off :: "View Formatted Text"

        screen.view_source = partials.add_screen_key_button(&screen, "view_source", text_on)
        screen.view_source.click = proc (f: ^ui.Frame) {
            screen.view_source_enabled ~= true
            ui.set_text(f, screen.view_source_enabled ? text_off : text_on)

            text := ui.get(screen.root, "pages/credits/content/text")
            if screen.view_source_enabled {
                credits_text_escaped, _ := terse.text_escaped(data.credits_text, context.temp_allocator)
                ui.set_text(text, credits_text_escaped)
            } else {
                ui.set_text(text, data.credits_text)
            }
        }
    }

    page.show = proc (f: ^ui.Frame) {
        ui.show(screen.autoscroll)
        ui.show(screen.view_source)
    }

    page.hide = proc (f: ^ui.Frame) {
        ui.hide(screen.autoscroll)
        ui.hide(screen.view_source)
    }
}

@private
add_lorem_ipsum_page :: proc () {
    _, page := partials.add_screen_tab_and_page(&screen, "lorem_ipsum", "LOREM IPSUM")

    screen.lorem_content = add_content(page, data.lorem_ipsum_text)

    screen.lorem_info = ui.add_frame(page, {
        name    = "info",
        text    = "#0008",
        size    = {240,0},
        layout  = ui.Flow { dir=.down, pad={20,20,50,50}, gap=20, auto_size={.height} },
        draw    = partials.draw_gradient_fade_up_and_down_rect,
    },
        { point=.right, rel_point=.left, rel_frame=screen.lorem_content, offset={-40,0} },
    )

    ui.add_frame(screen.lorem_info, {
        name        = "stats",
        flags       = {.terse,.terse_height},
        text_format = "<wrap,left,font=text_4l,color=primary_d2>%s",
        tick        = proc (f: ^ui.Frame) {
            tr := ui.get(screen.lorem_content, "text").terse
            if screen.lorem_info_target != tr {
                // update stats on terse update
                screen.lorem_info_target = tr
                ui.set_text(f, fmt.tprintf(
                    "File:<tab=80>%M\n" +
                    "<gap=.4>Terse:<tab=80>%M\n" +
                    "Words:<tab=80>%i\n" +
                    "Lines:<tab=80>%i\n" +
                    "Groups:<tab=80>%i",
                    len(data.lorem_ipsum_text),
                    terse.size_of_terse(tr),
                    tr != nil ? len(tr.words) : 0,
                    tr != nil ? len(tr.lines) : 0,
                    tr != nil ? len(tr.groups) : 0,
                ))
            }

            if screen.lorem_offset_target != -1 {
                // advance smooth scroll for content
                flow := ui.layout_flow(screen.lorem_content)
                offset_change := flow.scroll.offset - screen.lorem_offset_target
                ui.scroll(screen.lorem_content, offset_change*f.ui.clock.dt*.5)
                if 1 > abs(flow.scroll.offset-screen.lorem_offset_target) {
                    screen.lorem_offset_target = -1
                }
            }
        },
    })

    ui.add_frame(screen.lorem_info, {
        name = "line",
        text = "primary_d5",
        size = {0,2},
        draw = partials.draw_gradient_fade_left_and_right_rect,
    })

    nav_list := ui.add_frame(screen.lorem_info, {
        name    = "nav_list",
        size    = {0,340},
        flags   = {.scissor,.block_wheel},
        layout  = ui.Flow { dir=.down, scroll={step=30} },
    })

    track, _ := partials.add_scrollbar(nav_list)
    track.anchors[0].offset.x = 19
    track.anchors[1].offset.x = 19

    // we don't expect group list to change,
    // only group positions will change when content gets scrolled or resized
    tr := ui.get(screen.lorem_content, "text").terse
    for _, i in tr.groups {
        text := terse.text_of_group(tr, i, context.temp_allocator)
        ui.add_frame(nav_list, {
            name    = "nav",
            flags   = {.terse,.terse_height},
            text    = fmt.tprintf("<wrap,left,font=text_4l>%i. %s", i+1, text),
            draw    = proc (f: ^ui.Frame) {
                color := colors.get(.primary, brightness=f.entered?.4:-.4)
                partials.draw_terse(f, color=color)
            },
            click   = proc (f: ^ui.Frame) {
                lorem_text := ui.get(screen.lorem_content, "text")
                lorem_terse := lorem_text.terse
                group_idx := ui.index(f)
                group := &lorem_terse.groups[group_idx]
                assert(len(group.rects) > 0)

                flow := ui.layout_flow(screen.lorem_content)
                screen.lorem_offset_target = clamp(
                    group.rects[0].y - lorem_terse.rect.y - 10,
                    flow.scroll.offset_min,
                    flow.scroll.offset_max,
                )
            },
        })
    }

    // ui.print_frame_tree(page)
}

@private
add_content :: proc (page: ^ui.Frame, data_text: string) -> ^ui.Frame {
    content := ui.add_frame(page, {
        name    = "content",
        flags   = {.scissor},
        layout  = ui.Flow { dir=.down, scroll={step=30} },
    },
        { point=.top_left, offset={320,0} },
        { point=.bottom_right, offset={-320,0} },
    )

    text, track, _ := partials.add_text_and_scrollbar(content)

    ui.set_text_format(text, "<pad=0:40,wrap,left,font=text_4l,color=primary>%s")
    ui.set_text(text, data_text)

    track.anchors[0].offset = {80,40}
    track.anchors[1].offset = {80,-40}

    // redirect page wheel events to the content, so its possible to scroll even if mouse doesn't hit content
    page.wheel = proc (f: ^ui.Frame, dy: f32) -> bool {
        return ui.wheel(f, "content", dy)
    }

    return content
}
