#+private
package interface

import "core:fmt"
import "core:time"
import "vendor:raylib"

import "spacelib:core"
import "spacelib:ui"
import "spacelib:raylib/draw"

import "../colors"
import "../fonts"
import "../partials"
import "../sprites"

Vec2 :: core.Vec2
Rect :: core.Rect

dev: struct {
    layer           : ^ui.Frame,
    layer_split     : ^ui.Frame,

    window          : ^ui.Frame,
    resize_handle   : ^ui.Frame,
    content         : ^ui.Frame,

    monitor         : ^ui.Frame,
    monitor_floating: bool,

    frames_under_mouse_drawing  : bool,
    frames_under_mouse_store    : [100] ^ui.Frame,
    frames_under_mouse_slice    : [] ^ui.Frame,

    window_mode         : Dev_Window_Mode,
    window_rect_saved   : Rect,

    ui_stats_buffer     : [200] ui.Stats,
    ui_stats_buffer_idx : int,

    color_list  : ^ui.Frame,
    color_ed    : ^ui.Frame,
}

Dev_Window_Mode :: enum { invisible, visible, aside }

dev_window_min_size :: [2] f32 { 380, 230 }

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
    add_dev_stat_colors()
    add_dev_stat_fonts()
    add_dev_stat_texture_atlas()

    // add order to every child in dev.content flow so removing dev.monitor and adding it back
    // will place it at the same spot
    for child, i in dev.content.children do child.order = i

    add_dev_split_mode_layer()

    // name root frame for debug display
    ui.set_name(ui_.root, "root")
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
        text="<pad=15:10,left,wrap,color=#eee>Dev",
        draw=proc (f: ^ui.Frame) {
            draw.rect(f.rect, core.gray1)
            partials.draw_terse(f)
        },
        drag=proc (f: ^ui.Frame, info: ui.Drag_Info) {
            offset := f.ui.mouse.pos - info.start_offset
            f.parent.rect.x = offset.x
            f.parent.rect.y = offset.y
            ui.update(f.parent)
        },
    },
        { point=.top_left },
        { point=.top_right },
    )

    view := ui.add_frame(header,
        { name="view", layout=ui.Flow{ dir=.right, auto_size={.width}, size=40, align=.center } },
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
        layout=ui.Flow{ dir=.down, scroll={step=20}, pad={10,10,0,10}, gap=10 },
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
        drag=proc (f: ^ui.Frame, info: ui.Drag_Info) {
            offset := f.ui.mouse.pos - info.start_offset - {f.rect.x,f.rect.y}
            rect := &dev.window.rect
            rect.w = max(dev_window_min_size.x, rect.w + offset.x)
            rect.h = max(dev_window_min_size.y, rect.h + offset.y)
            ui.update(f.parent)
        },
    },
        { point=.bottom_right },
    )

    ui.update(dev.window)
}

add_dev_stat_perf :: proc () {
    add_dev_stat_header(dev.content, "Perf")

    add_dev_stat_perf_monitor()

    {
        add_dev_stat_text(dev.content, "VSync:")
        list := add_dev_stat_list_grid(dev.content)
        on := add_dev_stat_button(list, "ON", click=proc (f: ^ui.Frame) { raylib.SetWindowState({ .VSYNC_HINT }) })
        on.selected = true
        on.flags += {.radio}
        off := add_dev_stat_button(list, "OFF", click=proc (f: ^ui.Frame) { raylib.ClearWindowState({ .VSYNC_HINT }) })
        off.flags += {.radio}
    }

    {
        add_dev_stat_text(dev.content, "Borderless:")
        list := add_dev_stat_list_grid(dev.content, {100,30})
        add_dev_stat_button(list, "Toggle", click=proc (f: ^ui.Frame) { raylib.ToggleBorderlessWindowed() })
    }

    {
        label := add_dev_stat_text(dev.content, "")
        ui.set_text_format(label, "<left,wrap,color=#eee>Drawn: %i of %i\nMouse cursor frame stack:")
        label.tick = proc (f: ^ui.Frame) {
            stats := dev_last_stats_buffer()
            ui.set_text(f, stats.frames_drawn, stats.frames_total)
        }

        list := add_dev_stat_list_grid(dev.content, {100,30})
        toggle := add_dev_stat_button(list, "Toggle", click=proc (f: ^ui.Frame) { dev.frames_under_mouse_drawing ~= true })
        toggle.flags += {.check}
    }
}

add_dev_stat_perf_monitor :: proc () {
    dev.monitor = ui.add_frame(dev.content, {
        flags={.capture},
        name="monitor",
        size={len(dev.ui_stats_buffer)+160,130},
        draw=proc (f: ^ui.Frame) {
            if dev.monitor_floating {
                br_rect := core.rect_inflated(f.rect, 5)
                br_color := core.alpha(core.black, .4)
                draw.rect(br_rect, br_color)
            }

            draw.rect(f.rect, core.gray3)

            dot_size :: 4
            dot_bounds := core.rect_inflated(f.rect, -2)
            bottom_left_corner := Vec2 { f.rect.x, f.rect.y+f.rect.h }
            j := 0

            for span in ([] [2] int {
                { dev.ui_stats_buffer_idx, len(dev.ui_stats_buffer) },  // idx (first) -> <100
                { 0, dev.ui_stats_buffer_idx },                         // 0 -> <idx (last)
            }) {
                for i in span[0]..<span[1] {
                    stats := dev.ui_stats_buffer[i]

                    {
                        dot := bottom_left_corner + { f32(j), -f32(stats.draw_time/(time.Microsecond*10)) }
                        draw.rect(core.rect_from_center(core.clamp_vec_to_rect(dot, dot_bounds), dot_size), core.yellow)
                    }

                    {
                        dot := bottom_left_corner + { f32(j), -f32(stats.tick_time/(time.Microsecond*10)) }
                        draw.rect(core.rect_from_center(core.clamp_vec_to_rect(dot, dot_bounds), dot_size), core.magenta)
                    }

                    j += 1
                }
            }

            {
                point := bottom_left_corner + { f32(j)+10, -f32(100) }
                rect := Rect { f.rect.x, f.rect.y, f32(j)+50, point.y-f.rect.y }
                draw.rect(rect, core.alpha(core.gray5, .6))
                draw.text("1 ms", point+{0,-20}, fonts.get(.default), core.gray3)

                draw.text(fmt.tprintf("FPS: %i", raylib.GetFPS()), point+{45,-20}, fonts.get(.default), core.gray8)
            }

            stats := dev_last_stats_buffer()
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
        drag=proc (f: ^ui.Frame, info: ui.Drag_Info) {
            if !dev.monitor_floating do return
            offset := f.ui.mouse.pos - info.start_offset
            f.rect.x = offset.x
            f.rect.y = offset.y
        },
    })

    ui.add_frame(dev.monitor, {
        name="float_toggle",
        flags={.capture},
        size=30,
        draw=proc (f: ^ui.Frame) {
            if f.entered do draw.rect(f.rect, core.alpha(core.black, .3))
            icon := dev.monitor_floating ? "keyboard_tab" : "keyboard_tab_rtl"
            partials.draw_sprite(icon, f.rect, tint=core.gray8)
        },
        click=proc (f: ^ui.Frame) {
            dev.monitor_floating ~= true
            if dev.monitor_floating {
                ui.set_parent(dev.monitor, dev.layer)
                dev.monitor.rect.x -= dev.monitor.rect.w+30
            } else {
                ui.set_parent(dev.monitor, dev.content)
            }
        },
    },
        {point=.top_left},
    )
}

add_dev_stat_clock :: proc () {
    add_dev_stat_header(dev.content, "Clock")

    add_dev_stat_text(dev.content, "Time scale:")
    list := add_dev_stat_list_grid(dev.content)

                add_dev_stat_button(list, "x0.3", click=proc (f: ^ui.Frame) { ui_.clock.time_scale = .3 })
                add_dev_stat_button(list, "x0.5", click=proc (f: ^ui.Frame) { ui_.clock.time_scale = .5 })
    selected := add_dev_stat_button(list, "x1", click=proc (f: ^ui.Frame) { ui_.clock.time_scale = 1 })
                add_dev_stat_button(list, "x2", click=proc (f: ^ui.Frame) { ui_.clock.time_scale = 2 })
                add_dev_stat_button(list, "x3", click=proc (f: ^ui.Frame) { ui_.clock.time_scale = 3 })

    for child in list.children do child.flags += {.radio}
    selected.selected = true

    ui.add_frame(dev.content, {
        size={0,60},
        draw=proc (f: ^ui.Frame) {
            c := &ui_.clock
            text := fmt.tprintf("tick: %v\ntime: %v\ndt: %v", c.tick, c.time, c.dt)
            draw.text(text, {f.rect.x,f.rect.y}, fonts.get(.default), core.gray9)
        },
    })
}

color_slider_thumb_size :: Vec2 { 60, 25 }

add_dev_stat_colors :: proc () {
    add_dev_stat_header(dev.content, "Colors")

    dev.color_list = add_dev_stat_list_grid(dev.content, cell_size={120,30})
    for id in colors.ID {
        text := fmt.tprint(id)
        button := add_dev_stat_button(dev.color_list, text, click=proc (f: ^ui.Frame) {
            color := colors.get_by_name(f.name)

            red_thumb, _ := ui.actor_slider(ui.get(dev.color_ed, "red/thumb"))
            ui.set_actor_slider_idx(red_thumb, int(color.r), trigger_thumb_click=false)

            green_thumb, _ := ui.actor_slider(ui.get(dev.color_ed, "green/thumb"))
            ui.set_actor_slider_idx(green_thumb, int(color.g), trigger_thumb_click=false)

            blue_thumb, _ := ui.actor_slider(ui.get(dev.color_ed, "blue/thumb"))
            ui.set_actor_slider_idx(blue_thumb, int(color.b))
        })
        button.flags += {.radio}
        ui.set_name(button, text)
    }

    dev.color_ed = ui.add_frame(dev.content, { name="color_ed", size={0,100} })
    preview := ui.add_frame(dev.color_ed, {
        name="preview",
        size_aspect=1,
        draw=proc (f: ^ui.Frame) {
            draw.rect(f.rect, current_color())
        },
    },
        { point=.top_left },
        { point=.bottom_left },
    )

    thumb_size :: color_slider_thumb_size
    line_step_y :: thumb_size.y + 4

    red := add_dev_stat_color_component_slider(dev.color_ed, "red", "#f64", proc (f: ^ui.Frame) { update_color() })
    ui.set_anchors(red,
        { point=.left, rel_point=.right, rel_frame=preview, offset={10,-line_step_y} },
        { point=.right, rel_point=.right, offset={0,-line_step_y} },
    )

    green := add_dev_stat_color_component_slider(dev.color_ed, "green", "#4f6", proc (f: ^ui.Frame) { update_color() })
    ui.set_anchors(green,
        { point=.left, rel_point=.right, rel_frame=preview, offset={10,0} },
        { point=.right, rel_point=.right },
    )

    blue := add_dev_stat_color_component_slider(dev.color_ed, "blue", "#68f", proc (f: ^ui.Frame) { update_color() })
    ui.set_anchors(blue,
        { point=.left, rel_point=.right, rel_frame=preview, offset={10,line_step_y} },
        { point=.right, rel_point=.right, offset={0,line_step_y} },
    )

    ui.click(dev.color_list, "primary")

    current_color :: proc () -> core.Color {
        _, r := ui.actor_slider(ui.get(dev.color_ed, "red/thumb"))
        _, g := ui.actor_slider(ui.get(dev.color_ed, "green/thumb"))
        _, b := ui.actor_slider(ui.get(dev.color_ed, "blue/thumb"))
        return { u8(r.idx), u8(g.idx), u8(b.idx), 255 }
    }

    update_color :: proc () {
        button := ui.first_selected_child(dev.color_list)
        if button == nil do return

        name := button.name
        new_color := current_color()
        old_color := colors.get_by_name(name)
        if new_color != old_color {
            colors.set_by_name(name, new_color)
            ui.reset_terse(ui_)
            ui.update(ui_.root)
        }
    }
}

add_dev_stat_color_component_slider :: proc (parent: ^ui.Frame, name, text: string, thumb_click: ui.Frame_Proc) -> ^ui.Frame {
    thumb_size :: color_slider_thumb_size

    track := ui.add_frame(dev.color_ed, {
        name=name,
        text=text,
        size={0,25},
        draw=proc (f: ^ui.Frame) {
            draw.rect(f.rect, core.gray3)

            _, data := ui.actor_slider(f.children[0])
            color := core.color_from_hex(f.text)
            color = core.brightness(color, -.4)
            scale_x := f32(data.idx) / f32(data.total-1)
            draw.rect(core.rect_scaled_top_left(f.rect, {scale_x,1}), color)
        },
    })

    thumb := ui.add_frame(track, {
        name="thumb",
        flags={.capture},
        size=thumb_size,
        click=thumb_click,
        draw=proc (f: ^ui.Frame) {
            bg_color := core.color_from_hex(f.parent.text)
            draw.rect(f.rect, bg_color)

            ln_color := core.brightness(bg_color, .3)
            draw.rect_lines(f.rect, 1, ln_color)

            _, data := ui.actor_slider(f)
            text := fmt.tprintf("%i%%", int((100*f32(data.idx))/f32(data.total-1)))
            draw.text_center(text, core.rect_center(f.rect), fonts.get(.default), core.gray1)
        },
    },
        { point=.left, rel_point=.left },
    )

    ui.setup_slider_actors({ total=256 }, thumb)

    return track
}

add_dev_stat_fonts :: proc () {
    add_dev_stat_header(dev.content, "Fonts")

    add_dev_stat_text(dev.content, "Scale:")
    list := add_dev_stat_list_grid(dev.content)

                add_dev_stat_button(list, "x0.8", click=proc (f: ^ui.Frame) { scale_fonts(.8) })
                add_dev_stat_button(list, "x0.9", click=proc (f: ^ui.Frame) { scale_fonts(.9) })
    selected := add_dev_stat_button(list, "x1"  , click=proc (f: ^ui.Frame) { scale_fonts(1) })
                add_dev_stat_button(list, "x1.1", click=proc (f: ^ui.Frame) { scale_fonts(1.1) })
                add_dev_stat_button(list, "x1.2", click=proc (f: ^ui.Frame) { scale_fonts(1.2) })

    for child in list.children do child.flags += {.radio}
    selected.selected = true

    for id in fonts.ID {
        ui.add_frame(dev.content, {
            flags={.terse,.terse_height},
            text=fmt.tprintf("<left,wrap,color=#eee>%s<tab=120,font=%s>Hellope!", id, id),
        })
    }

    scale_fonts :: proc (scale: f32) {
        fonts.destroy()
        fonts.create(scale)
        ui.reset_terse(ui_)
        ui.update(ui_.root)
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
        text=fmt.tprintf("<pad=5:10,left,wrap,color=#333>%s", text),
        draw=proc (f: ^ui.Frame) {
            bg_rect := core.rect_inflated(f.rect, {15,0})
            draw.rect(bg_rect, core.gray9)
            partials.draw_terse(f)
        },
    })
}

add_dev_stat_text :: proc (parent: ^ui.Frame, text: string) -> ^ui.Frame {
    return ui.add_frame(parent, {
        flags={.terse,.terse_height},
        text=fmt.tprintf("<left,wrap,color=#eee>%s", text),
    })
}

add_dev_stat_list_grid :: proc (parent: ^ui.Frame, cell_size := Vec2 {72,30}) -> ^ui.Frame {
    return ui.add_frame(parent, {
        layout=ui.Grid{ dir=.right_down, size=cell_size, auto_size={.height} },
        draw=proc (f: ^ui.Frame) { draw.rect_gradient_horizontal(f.rect, core.gray3, core.gray2) },
    })
}

add_dev_stat_button :: proc (parent: ^ui.Frame, text: string, click: ui.Frame_Proc) -> ^ui.Frame {
    return ui.add_frame(parent, {
        flags={.terse,.terse_height},
        text=fmt.tprintf("<wrap>%s", text),
        click=click,
        draw=proc (f: ^ui.Frame) {
            if f.selected                   do draw.rect(f.rect, core.gray7)
            else          do if f.entered   do draw.rect(f.rect, core.gray4)
            partials.draw_terse(f, color=f.selected?core.gray1:core.gray7)
        },
    })
}

dev_last_stats_buffer :: proc () -> ^ui.Stats {
    last_idx := dev.ui_stats_buffer_idx-1
    if last_idx < 0 do last_idx = len(dev.ui_stats_buffer)-1
    return &dev.ui_stats_buffer[last_idx]
}

dev_switch_window_mode :: proc (next_mode: Dev_Window_Mode) {
    prev_mode := dev.window_mode
    if next_mode == prev_mode do return
    dev.window_mode = next_mode

    if prev_mode == .aside {
        ui.show(dev.resize_handle)
        disable_dev_split_mode()
    } else if next_mode == .aside {
        ui.hide(dev.resize_handle)
        enable_dev_split_mode()
    }

    #partial switch next_mode {
    case .invisible : ui.hide(dev.window)
    case .visible   : ui.show(dev.window)
    }
}

dev_draw_ended :: proc () {
    dev.ui_stats_buffer[dev.ui_stats_buffer_idx] = ui_.stats
    dev.ui_stats_buffer_idx += 1
    if dev.ui_stats_buffer_idx >= len(dev.ui_stats_buffer) do dev.ui_stats_buffer_idx = 0
}

dev_draw_frame_list_under_mouse :: proc () {
    if !dev.frames_under_mouse_drawing do return

    font := fonts.get(.default)
    pos := Vec2 { 10, 10 }

    for j, i in ui_.mouse_frames {
        path := ui.path_string(j, allocator=context.temp_allocator)
        text := fmt.tprintf("[%i] %s", i, path)
        draw.text(text, pos+{1,2}, font, tint=core.gray1)
        draw.text(text, pos, font, tint=core.gray9)
        pos.y += 20
    }
}
