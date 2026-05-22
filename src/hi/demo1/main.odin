package main

import "core:fmt"
import "../../core"
import "../../core/tracking_allocator"
import hi ".."
import k2 "../../../../karl2d"

ctx: ^hi.Context

main :: proc () {
    context.allocator = tracking_allocator.init(verbosity=.minimal)
    defer {
        tracking_allocator.print()
        tracking_allocator.destroy()
    }

    fmt.println("-------------------------------------------")
    fmt.println("Context size       :", size_of(hi.Context))
    fmt.println("View size          :", size_of(hi.View))
    fmt.println("Active_View size   :", size_of(hi.Active_View))
    fmt.println("Text_Token size    :", size_of(hi.Text_Token))
    fmt.println("-------------------------------------------")

    k2.init(1280, 720, "demo", { window_mode=.Windowed_Resizable })

    ctx = hi.create_context({
        ref_size = {320,180},
        ref_font_height = 16,
        align_center = true,
        aspect_ratio_matching = -1,
        on_event = proc (ctx: ^hi.Context, event: hi.Context_Event) {
            fmt.println("[ctx.on_event]", event)
        },
        on_scissor = proc (ctx: ^hi.Context, scissor: hi.Rect) {
            k2.set_scissor_rect(
                scissor != {}\
                ? k2.Rect(hi.ref_rect_to_screen(ctx, scissor))\
                : nil,
            )
        },
        on_measure_text = proc (ctx: ^hi.Context, style: ^hi.Text_Style, text: string, is_whitespace: bool) -> (size: [2] f32) {
            default_font_height := f32(ctx.screen_font_height) / 2
            return k2.measure_text(text, default_font_height)
        },
        on_text_custom_command = proc (ctx: ^hi.Context, style: ^hi.Text_Style, cmd, args: string) -> (size: [2] f32) {
            default_font_height := f32(ctx.screen_font_height) / 2
            switch cmd {
            case "f": style.font = args
            case "c": style.color = core.color_from_hex(args) // or named color
            case "icon": size = default_font_height
            }
            return
        },
        on_draw_text = proc (v: ^hi.Active_View) {
            pos := hi.ref_pos_to_screen(v.ctx, {v.solved_rect.x,v.solved_rect.y})
            k2.draw_text(v.text, pos, f32(ctx.screen_font_height)/2, k2.WHITE)
        },
        debug_draw_line = proc (from, to: [2] f32, thick: f32, color: [4] u8) {
            k2.draw_line(from, to, thick, color)
        },
        debug_draw_text = proc (text: string, pos: [2] f32, color: [4] u8) {
            k2.draw_text(text, pos, 20, color)
        },
    })

    add_dialog(
        ctx.root,
        name = "dialog_exit_game",
        title = "Exit Game?",
        content = "[c=#fff]All unsaved [c=#f00]progress will be lost[c=#fff].[br][center]Proceed?",
        button1 = "Yes",
        button2 = "No",
        button3 = "Maybe",
        with_header_close_button = true,
    )

    hi.set_debug(ctx.root, true)

    hi.solve_context(ctx)
    hi.print_view_tree(ctx.root)

    fmt.println("ctx.active_views == {")
    for v in ctx.active_views {
        fmt.printfln("\t%v\tL%d\t#%4d %20s |%f| %10s\t%v",
            v.strata,
            v.level,
            v.sid,
            v.name,
            v.solved_opacity,
            .scissor in v.flags ? "+scissor" : "",
            v.solved_scissor,
        )
    }
    fmt.println("}")

    for main_update() {
        main_draw()
        free_all(context.temp_allocator)
    }

    hi.destroy_context(ctx)
    k2.shutdown()
}

main_update :: proc () -> (keep_running: bool) {
    keep_running = k2.update() && !k2.key_went_down(.Escape)

    dt := k2.get_frame_time()
    screen_size := k2.get_screen_size()
    mouse_input := hi.Mouse_Input {
        lmb_down = k2.mouse_button_is_held(.Left),
        screen_pos = k2.get_mouse_position(),
        wheel_delta = k2.get_mouse_wheel_delta(),
    }

    hi.update_context(ctx, screen_size, mouse_input, dt)

    return
}

main_draw :: proc () {
    k2.clear(k2.DARK_GRAY)
    hi.draw_context(ctx)
    k2.present()
}

draw_view :: proc (v: ^hi.Active_View) {
    rect := k2.Rect(hi.ref_view_to_screen(v))
    alpha := u8(v.solved_opacity * 255)
    k2.draw_rect(rect, {30,80,50,alpha})
    k2.draw_rect_outline(rect, 4, {30,180,50,alpha})
}

add_dialog :: proc (parent: ^hi.View, name, title, content, button1: string, button2 := "", button3 := "", with_header_close_button := false) -> (root: ^hi.View) {
    root = hi.add_view(parent, {
        name    = "dialog",
        flags   = {.fit_y},
        size    = {160,0},
        layout  = {dir=.column},
        place   = {anchor=.5,pivot=.5},
        on_draw = draw_view,
    })

    header := hi.add_view(root, { name="header", flags={.fill_x,.fit_y}, padding={10,0,0,0}, layout={dir=.row,align=.center,gap=10} })
    hi.add_view(header, { name="title", flags={.fill_x,.text}, size={0,14}, text=title })
    if with_header_close_button {
        add_icon_button(header, name="button_close", icon="close")
    }

    content_ := hi.add_view(root, { name="content", flags={.fill_x,.scissor}, size={0,80}, padding=10 })
    hi.add_view(content_, { name="text", flags={.text,.fill_y}, size={80,0}, padding=3, text=content })
    clip := hi.add_view(content_, { name="clip_in_content", flags={.scissor}, size={100,40}, place={anchor={1,.5},pivot=.5} })
    hi.add_view(clip, { name="box_in_clip", size={50,30}, place={anchor={.5,1},pivot=.5}, on_draw=draw_view })
    hi.add_view(content_, { name="box_in_content", size={50,30}, place={anchor={1,.25},pivot=.5}, on_draw=draw_view })

    // options_menu := hi.add_view(content_, { name="options_menu", size={100,0}, place={anchor=.5}, layout={dir=.column}, strata=.overlay })
    // hi.add_view(options_menu, { name="option1", flags={.fill_x}, size={0,20} })
    // hi.add_view(options_menu, { name="option2", flags={.fill_x}, size={0,20} })
    // hi.add_view(options_menu, { name="option3", flags={.fill_x}, size={0,20} })
    // hi.add_view(options_menu, { name="option4", flags={.fill_x}, size={0,20} })

    button2_view: ^hi.View
    footer := hi.add_view(root, { name="footer", flags={.scissor,.fill_x,.fit_y}, padding=5, layout={dir=.row,justify=.center,align=.center,gap=10} })
    if button1 != "" do add_text_button(footer, name="button1", text=button1)
    if button2 != "" do button2_view = add_text_button(footer, name="button2", text=button2)
    if button3 != "" do add_text_button(footer, name="button3", text=button3)

    hint := hi.add_view(footer, { name="hint", flags={.ratio_y}, size={60,1}, padding=5, layout={dir=.row,gap=5}, place={anchor={1,0},offset={5,0}}, strata=.overlay, on_draw=draw_view, opacity=.8 })
    hi.add_view(hint, { name="icon", size=15 })
    hi.add_view(hint, { name="desc", flags={.text,.fill_x,.fill_y}, text="Hello[br]World!" })

    hi.remove_view(button2_view)
    add_text_button(footer, name="button4", text="Four")
    add_text_button(footer, name="button5", text="Five")
    add_text_button(footer, name="button6", text="Six")

    fmt.println("Footer buttons: // Iterator test, should include only buttons")
    it := hi.child_iterate(footer)
    for c, i in hi.child_next(&it) do fmt.println("\t", i, c.name)

    return
}

add_icon_button :: proc (parent: ^hi.View, name, icon: string) -> ^hi.View {
    return hi.add_view(parent, { name=name, size={20,20}, on_draw=draw_view })
}

add_text_button :: proc (parent: ^hi.View, name, text: string) -> (root: ^hi.View) {
    root = hi.add_view(parent, { name=name, size={60,20}, on_draw=draw_view })
    hi.add_view(root, { name="label", flags={.text,.fill_x,.fill_y}, text=text })
    return
}
