#+private
package interface

import "core:fmt"
import "core:time"
import "vendor:raylib"

import "spacelib:core"
import "spacelib:ui"
import "spacelib:raylib/draw"

import "../fonts"
import "../partials"
import "../sprites"

Vec2 :: core.Vec2
Rect :: core.Rect

dev: struct {
    layer           : ^ui.Frame,

    window          : ^ui.Frame,
    resize_handle   : ^ui.Frame,
    content         : ^ui.Frame,

    window_mode     : Dev_Window_Mode,

    ui_stats_buffer     : [200] ui.Stats,
    ui_stats_buffer_idx : int,
}

Dev_Window_Mode :: enum { invisible, visible, aside }

dev_window_min_size :: [2] f32 { 410, 240 }

add_dev_layer :: proc (order: int) {
    assert(dev.layer == nil)

    dev.layer = ui.add_frame(ui_.root, {
        name    = "dev",
        flags   = {.pass_self},
        order   = order,
        tick    = proc (f: ^ui.Frame) {
            if dev.window_mode == .invisible {
                if raylib.IsKeyDown(.LEFT_CONTROL)  do dev.window.flags -= {.hidden}
                else                                do dev.window.flags += {.hidden}
            }
        },
    }, { point=.top_left }, { point=.bottom_right })

    add_dev_window()
    add_dev_stat_perf()
    add_dev_stat_clock()
    add_dev_stat_fonts()
    add_dev_stat_texture_atlas()
}

add_dev_window :: proc () {
    dev.window = ui.add_frame(dev.layer, {
        name="window",
        flags={.hidden,.block_wheel},
        rect={450,250,dev_window_min_size.x,dev_window_min_size.y},
        draw=proc (f: ^ui.Frame) {
            draw.rect(core.rect_inflated(f.rect, 5), core.alpha(core.black, .4))
            draw.rect(f.rect, core.gray2)
        },
    })

    header := ui.add_frame(dev.window, {
        name="header",
        flags={.capture,.terse,.terse_height},
        text="<pad=15:10,left,wrap,color=#eee>Dev Window",
        draw=proc (f: ^ui.Frame) {
            draw.rect(f.rect, core.gray1)
            partials.draw_terse(f.terse)
        },
        drag=proc (f: ^ui.Frame, mouse_pos, captured_pos: Vec2) {
            offset := mouse_pos - captured_pos
            f.parent.rect.x = offset.x
            f.parent.rect.y = offset.y
            ui.update(f.parent)
        },
    },
        { point=.top_left },
        { point=.top_right },
    )

    view := ui.add_frame(header,
        { name="view", layout=ui.Flow{ dir=.right, auto_size=.dir, size=40, align=.center } },
        { point=.right },
    )

    for b, i in ([] struct { icon:string, click:ui.Frame_Proc } {
        { icon="visibility_off" , click=proc (f: ^ui.Frame) { dev_switch_window_mode(.invisible) } },
        { icon="visibility"     , click=proc (f: ^ui.Frame) { dev_switch_window_mode(.visible) } },
        { icon="side_navigation", click=proc (f: ^ui.Frame) { dev_switch_window_mode(.aside) } },
    }) {
        ui.add_frame(view, {
            text=b.icon,
            flags={.radio,.capture},
            selected=i==0,
            draw=proc (f: ^ui.Frame) {
                if f.selected                   do draw.rect(f.rect, core.gray7)
                else          do if f.entered   do draw.rect(f.rect, core.gray2)
                partials.draw_sprite(f.text, f.rect, tint=f.selected?core.gray1:core.gray7)
            },
            click=b.click,
        })
    }

    dev.content = ui.add_frame(dev.window, {
        name="content",
        flags={.scissor},
        layout=ui.Flow{ dir=.down, scroll={step=20}, pad={15,0}, gap=5 },
    },
        { point=.top_left, rel_point=.bottom_left, rel_frame=header },
        { point=.bottom_right },
    )

    track, _ := partials.add_scrollbar(dev.content)
    track.anchors[0].offset = 0
    track.anchors[1].offset = 0

    dev.resize_handle = ui.add_frame(dev.window, {
        name="resize_handle",
        flags={.capture},
        size=32,
        draw=proc (f: ^ui.Frame) {
            partials.draw_sprite("drag_indicator", f.rect, tint=core.gray6)
        },
        drag=proc (f: ^ui.Frame, mouse_pos, captured_pos: Vec2) {
            offset := mouse_pos-captured_pos-{f.rect.x,f.rect.y}
            win_rect := &dev.window.rect
            win_rect.w = max(dev_window_min_size.x, win_rect.w+offset.x)
            win_rect.h = max(dev_window_min_size.y, win_rect.h+offset.y)
            ui.update(f.parent)
        },
    },
        { point=.bottom_right },
    )
}

add_dev_stat_perf :: proc () {
    add_dev_stat_header(dev.content,"Perf")

    ui.add_frame(dev.content, {
        size={len(dev.ui_stats_buffer)+180,150},
        draw=proc (f: ^ui.Frame) {
            draw.rect(f.rect, core.gray3)

            j := 0
            bottom_left_corner := Vec2 { f.rect.x, f.rect.y+f.rect.h }

            for span in ([] [2] int {
                { dev.ui_stats_buffer_idx, len(dev.ui_stats_buffer) },  // idx (first) -> <100
                { 0, dev.ui_stats_buffer_idx },                         // 0 -> <idx (last)
            }) {
                for i in span[0]..<span[1] {
                    stats := dev.ui_stats_buffer[i]

                    {
                        point := bottom_left_corner + { f32(j), -f32(stats.draw_time/(time.Microsecond*10)) }
                        if core.vec_in_rect(point, f.rect) do draw.rect(core.rect_from_center(point, 4), core.yellow)
                    }

                    {
                        point := bottom_left_corner + { f32(j), -f32(stats.tick_time/(time.Microsecond*10)) }
                        if core.vec_in_rect(point, f.rect) do draw.rect(core.rect_from_center(point, 4), core.magenta)
                    }

                    j += 1
                }
            }

            {
                point := bottom_left_corner + { f32(j)+10, -f32(100) }
                rect := Rect { f.rect.x, point.y-22, f32(j)+60, 22 }
                draw.rect(rect, core.alpha(core.gray5, .75))
                draw.text("1 ms", point+{5,-20}, fonts.get(.default), core.gray3)
            }

            last_idx := dev.ui_stats_buffer_idx-1
            if last_idx < 0 do last_idx = len(dev.ui_stats_buffer)-1
            stats := dev.ui_stats_buffer[last_idx]
            cursor := Vec2 {f.rect.x+f32(j)+10,f.rect.y+f.rect.h-5}

            cursor.y -= 20
            frames_drawn_text := fmt.tprintf("frames: %i", stats.frames_drawn)
            draw.text(frames_drawn_text, cursor, fonts.get(.default), core.gray8)

            cursor.y -= 20
            scissors_set_text := fmt.tprintf("scissors: %i", stats.scissors_set)
            draw.text(scissors_set_text, cursor, fonts.get(.default), core.gray8)

            cursor.y -= 20
            draw_time_text := fmt.tprintf("draw: %v", stats.draw_time)
            draw.text(draw_time_text, cursor, fonts.get(.default), core.yellow)

            cursor.y -= 20
            tick_time_text := fmt.tprintf("tick: %v", stats.tick_time)
            draw.text(tick_time_text, cursor, fonts.get(.default), core.magenta)
        },
    })

    {
        add_dev_stat_text(dev.content, "VSync:")
        list := add_dev_stat_list_grid(dev.content)
        add_dev_stat_button(list, "ON", click=proc (f: ^ui.Frame) {  })
        add_dev_stat_button(list, "OFF", click=proc (f: ^ui.Frame) {  })
    }

    {
        add_dev_stat_text(dev.content, "Fullscreen:")
        list := add_dev_stat_list_grid(dev.content)
        add_dev_stat_button(list, "ON", click=proc (f: ^ui.Frame) {  })
        add_dev_stat_button(list, "OFF", click=proc (f: ^ui.Frame) {  })
    }
}

add_dev_stat_clock :: proc () {
    add_dev_stat_header(dev.content,"Clock")

    add_dev_stat_text(dev.content, "Set time scale:")
    list := add_dev_stat_list_grid(dev.content)

                add_dev_stat_button(list, "x0.25", click=proc (f: ^ui.Frame) { ui_.clock.time_scale = .25 })
                add_dev_stat_button(list, "x0.5", click=proc (f: ^ui.Frame) { ui_.clock.time_scale = .5 })
    selected := add_dev_stat_button(list, "x1", click=proc (f: ^ui.Frame) { ui_.clock.time_scale = 1 })
                add_dev_stat_button(list, "x2", click=proc (f: ^ui.Frame) { ui_.clock.time_scale = 2 })
                add_dev_stat_button(list, "x4", click=proc (f: ^ui.Frame) { ui_.clock.time_scale = 4 })

    for child in list.children do child.flags += {.radio}
    selected.selected = true

    ui.add_frame(dev.content, {
        size={0,200},
        draw=proc (f: ^ui.Frame) {
            text := fmt.tprintf("%#v", ui_.clock)
            draw.text(text, {f.rect.x,f.rect.y}, fonts.get(.default), core.gray9)
        },
    })
}

add_dev_stat_fonts :: proc () {
    add_dev_stat_header(dev.content,"Fonts")

    add_dev_stat_text(dev.content, "Set font scale:")
    list := add_dev_stat_list_grid(dev.content)

                add_dev_stat_button(list, "x0.8", click=proc (f: ^ui.Frame) { dev_set_fonts_scale(.8) })
                add_dev_stat_button(list, "x0.9", click=proc (f: ^ui.Frame) { dev_set_fonts_scale(.9) })
    selected := add_dev_stat_button(list, "x1.0", click=proc (f: ^ui.Frame) { dev_set_fonts_scale(1) })
                add_dev_stat_button(list, "x1.1", click=proc (f: ^ui.Frame) { dev_set_fonts_scale(1.1) })
                add_dev_stat_button(list, "x1.2", click=proc (f: ^ui.Frame) { dev_set_fonts_scale(1.2) })

    for child in list.children do child.flags += {.radio}
    selected.selected = true

    for id in fonts.ID {
        ui.add_frame(dev.content, {
            flags={.terse,.terse_height},
            text=fmt.tprintf("<left,wrap,color=#eee>%s<tab=120,font=%s>Hello, World!", id, id),
        })
    }
}

add_dev_stat_texture_atlas :: proc () {
    scale :: .25
    tex := sprites.get_textures()[0]

    add_dev_stat_header(dev.content, fmt.tprintf("Texture atlas: %ix%i", tex.width, tex.height))

    ui.add_frame(dev.content, {
        tick=proc (f: ^ui.Frame) {
            tex := sprites.get_textures()[0]
            f.size = scale * { f32(tex.width), f32(tex.height) }
        },
        draw=proc (f: ^ui.Frame) {
            tex := sprites.get_textures()[0]
            tex_rect := Rect {0,0,f32(tex.width),f32(tex.height)}
            tex_rect_scaled := core.rect_scaled(tex_rect, scale)
            dst_rect := f.rect
            dst_rect.w = tex_rect_scaled.w
            dst_rect.h = tex_rect_scaled.h
            draw.rect_lines(dst_rect, 1, core.red)
            draw.texture(tex^, tex_rect, dst_rect)
        },
    })
}

add_dev_stat_header :: proc (parent: ^ui.Frame, text: string) {
    ui.add_frame(parent, {
        flags={.terse,.terse_height},
        text=fmt.tprintf("<pad=0:10,left,wrap,color=#333>%s", text),
        draw=proc (f: ^ui.Frame) {
            bg_rect := core.rect_inflated(f.rect, {15,0})
            draw.rect(bg_rect, core.gray9)
            partials.draw_terse(f.terse)
        },
    })
}

add_dev_stat_text :: proc (parent: ^ui.Frame, text: string) {
    ui.add_frame(parent, {
        flags={.terse,.terse_height},
        text=fmt.tprintf("<left,wrap,color=#eee>%s", text),
    })
}

add_dev_stat_list_grid :: proc (parent: ^ui.Frame) -> ^ui.Frame {
    return ui.add_frame(parent, {
        layout=ui.Grid{ dir=.right_down, wrap=4, gap=5, aspect_ratio=3, auto_size=true },
        tick=proc (f: ^ui.Frame) { ui.layout_grid(f).wrap = 1+int(f.rect.w/100) },
    })
}

add_dev_stat_button :: proc (parent: ^ui.Frame, text: string, click: ui.Frame_Proc) -> ^ui.Frame {
    return ui.add_frame(parent, {
        flags={.terse,.terse_height},
        text=fmt.tprintf("<wrap,color=#eee>%s", text),
        click=click,
        draw=proc (f: ^ui.Frame) {
            if f.selected   do draw.rect(f.rect, core.gray6)
            else            do draw.rect(f.rect, f.entered ? core.gray4 : core.gray3)
            draw.rect_lines(f.rect, 1, core.gray4)
            partials.draw_terse(f.terse)
        },
    })
}

dev_set_fonts_scale :: proc (scale: f32) {
    fonts.destroy()
    fonts.create(scale)
    ui.reset_terse(ui_)
    ui.update(ui_.root)
}

dev_record_ui_stats :: proc (stats: ui.Stats) {
    dev.ui_stats_buffer[dev.ui_stats_buffer_idx] = stats
    dev.ui_stats_buffer_idx += 1
    if dev.ui_stats_buffer_idx >= len(dev.ui_stats_buffer) do dev.ui_stats_buffer_idx = 0
}

dev_switch_window_mode :: proc (next_mode: Dev_Window_Mode) {
    prev_mode := dev.window_mode
    if next_mode == prev_mode do return
    dev.window_mode = next_mode

    if prev_mode == .aside {
        ui.show(dev.resize_handle)
    } else if next_mode == .aside {
        ui.hide(dev.resize_handle)
    }

    #partial switch next_mode {
    case .invisible : ui.hide(dev.window)
    case .visible   : ui.show(dev.window)
    }
}
