package main

import "core:fmt"
import "core:strconv"
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
    fmt.println("Visible_View size  :", size_of(hi.Visible_View))
    fmt.println("Text_Token size    :", size_of(hi.Text_Token))
    fmt.println("-------------------------------------------")

    k2.init(1280, 720, "demo1", { window_mode=.Windowed_Resizable })

    ctx = hi.create_context({
        ref_size = {320,180},
        ref_font_height = 12,
        align_center = true,
        aspect_ratio_matching = -1,
        on_event = proc (ctx: ^hi.Context, event: hi.Context_Event) {
            fmt.println("context event:", event)
        },
        on_scissor = proc (ctx: ^hi.Context, scissor: hi.Rect) {
            k2.set_scissor_rect(
                scissor != {}\
                ? k2.Rect(hi.ref_rect_to_screen(ctx, scissor))\
                : nil,
            )
        },
        on_text_measure = proc (style: hi.Text_Style, type: hi.Text_Token_Type, text: string) -> (size: [2] f32) {
            font_height := hi.text_style_font_height(style)
            size = k2.measure_text(text, font_height)
            // fmt.printfln("measure |%16s| %v %v", text == "\n" ? "\\n" : text, size, type)
            return
        },
        on_text_custom_command = proc (v: ^hi.View, style: ^hi.Text_Style, cmd, args: string) -> (size_scale: [2] f32) {
            switch cmd {
            case "f": style.font = args
            case "s": style.font_scale, _ = strconv.parse_f32(args)
            case "c": style.color = core.color_from_hex(args)
            case "i": size_scale = 1
            }
            return
        },
        on_draw_text = proc (v: ^hi.Visible_View) {
            it := hi.visible_text_iterate(v)
            // fmt.println("-----------", it.in_scissor_only)
            for tok, tok_rect in hi.visible_text_next(&it) {
                #partial switch tok.type {
                case .word:
                    pos_s := hi.ref_pos_to_screen(v.ctx, {tok_rect.x,tok_rect.y})
                    font_height_screen := hi.text_style_font_height_screen(it.style)
                    k2.draw_text(tok.text, pos_s, font_height_screen, it.style.color)
                    // fmt.println("::::", tok.text)
                case .custom:
                    rect_s := hi.ref_rect_to_screen(v.ctx, tok_rect)
                    k2.draw_rect_outline(k2.Rect(rect_s), 8, it.style.color)
                }
            }
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
        title = "|s=1.5||i=icon771| Exit Game?",
        content = "|c=#fff|All unsaved |c=#f00|progress will be lost|c=#fff|.\n\n|center|Proceed?\n|right|Some extra right-aligned text that is clipped by the scissor.",
        button1 = "Yes",
        button2 = "No",
        button3 = "Maybe",
        with_header_close_button = true,
    )

    hi.set_debug(ctx.root, true)

    hi.solve_context(ctx)
    hi.print_view_tree(ctx.root)
    hi.print_visible_views(ctx)

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

draw_view :: proc (v: ^hi.Visible_View) {
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
        on_event= proc (v: ^hi.View, e: hi.Event) -> bool {
            fmt.println(v.name, e)
            return true
        },
    })

    header := hi.add_view(root, { name="header", flags={.fill_x,.fit_y}, padding={10,0,0,0}, layout={dir=.row,align=.center,gap=10} })
    hi.add_view(header, { name="title", flags={.fill_x,.text}, text=title })
    if with_header_close_button {
        add_icon_button(header, name="button_close", icon="close")
    }

    content_ := hi.add_view(root, { name="content", flags={.fill_x,.scissor,.wheel_scroll_x}, size={0,80}, padding=10 })
    hi.add_view(content_, { name="text", flags={.text}, size={80,0}, padding=3, text=content })
    clip := hi.add_view(content_, { name="clip_in_content", flags={.scissor}, size={100,40}, place={anchor={1,.5},pivot=.5} })
    hi.add_view(clip, { name="box_in_clip", size={50,30}, place={anchor={.5,1},pivot=.5}, on_draw=draw_view })
    hi.add_view(content_, { name="box_in_content", size={50,30}, place={anchor={1,.25},pivot=.5}, on_draw=draw_view })

    options_menu := hi.add_view(content_, { name="options_menu", flags={.fit_x,.fit_y}, place={anchor=.5}, padding=4, layout={dir=.column}, strata=.overlay, level=10, on_draw=draw_view })
    options_bar := hi.add_view(options_menu, { name="bar", flags={.fit_x,.fit_y}, layout={dir=.row,align=.center,gap=2} })
    hi.add_view(options_bar, { text="Actions:", flags={.text,.text_fit_x} })
    add_icon_button(options_bar, name="button51", icon="51")
    add_icon_button(options_bar, name="button52", icon="52")
    hi.add_view(options_bar, { text="Status: OK", flags={.text,.text_fit_x} })
    hi.add_view(options_menu, { name="option1", text="Option #111|tab=65|501", flags={.fill_x,.text} })
    hi.add_view(options_menu, { name="option2", text="Option #22|tab=65|502", flags={.fill_x,.text} })
    hi.add_view(options_menu, { name="option3", text="Option #3|tab=65|503", flags={.fill_x,.text} })
    hi.add_view(options_menu, { name="option4", text="Option #4|tab=65|504", flags={.fill_x,.text} })

    button2_view: ^hi.View
    footer := hi.add_view(root, { name="footer", flags={.scissor,.fill_x,.fit_y}, padding=5, layout={dir=.row,justify=.center,align=.center,gap=10} })
    if button1 != "" do add_text_button(footer, name="button1", text=button1)
    if button2 != "" do button2_view = add_text_button(footer, name="button2", text=button2)
    if button3 != "" do add_text_button(footer, name="button3", text=button3)

    hint := hi.add_view(footer, { name="hint", flags={.ratio_y}, size={80,1}, padding=5, layout={dir=.row,gap=5}, place={anchor={1,0},offset={5,0}}, strata=.overlay, on_draw=draw_view, opacity=.8 })
    hi.add_view(hint, { name="icon", size=15 })
    hi.add_view(hint, { name="desc", flags={.text,.fill_x}, text="Hello World!" })

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
    root.on_event = proc (v: ^hi.View, e: hi.Event) -> (consumed: bool) {
        fmt.println(v.name, e)
        return
    }
    hi.add_view(root, { name="label", flags={.text,.fill_x}, text=text })
    return
}
