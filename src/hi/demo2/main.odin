package main

import "core:fmt"
import "../../core"
import "../../core/tracking_allocator"
import hi ".."
import k2 "../../../../karl2d"

Files := #load_directory("..")

App :: struct {
    ui: ^hi.Context,
    container: ^hi.View,
    token_buffers: map [^hi.View] [dynamic] hi.Text_Token,
}

app: App

main :: proc () {
    context.allocator = tracking_allocator.init(verbosity=.minimal)
    defer {
        tracking_allocator.print()
        tracking_allocator.destroy()
    }

    k2.init(1280, 720, "demo2", { window_mode=.Windowed_Resizable })

    app.ui = hi.create_context({
        ref_font_height = 24,
        scroll_step = 60,
        on_scissor = proc (ctx: ^hi.Context, scissor: hi.Rect) {
            k2.set_scissor_rect(scissor != {} ? k2.Rect(scissor) : nil)
        },
        on_text_measure = proc (style: hi.Text_Style, type: hi.Text_Token_Type, text: string) -> [2] f32 {
            font_height := hi.text_style_font_height(style)
            return k2.measure_text(text, font_height)
        },
        on_text_wordy = proc (v: ^hi.View) -> ^[dynamic] hi.Text_Token {
            if v not_in app.token_buffers do app.token_buffers[v] = make([dynamic] hi.Text_Token)
            return &app.token_buffers[v]
        },
        on_draw_text = proc (v: ^hi.Visible_View) {
            it := hi.visible_text_iterate(v, filter={.word})
            for tok, tok_rect in hi.visible_text_next(&it) {
                font_height_screen := hi.text_style_font_height_screen(it.style)
                k2.draw_text(tok.text, {tok_rect.x,tok_rect.y}, font_height_screen, it.style.color)
            }
        },
        debug_draw_filter = { .perf, .stats, .text },
        debug_draw_line = proc (from, to: [2] f32, thick: f32, color: [4] u8) {
            k2.draw_line(from, to, thick, color)
        },
        debug_draw_text = proc (text: string, pos: [2] f32, color: [4] u8) {
            k2.draw_text(text, pos, 20, color)
        },
    })

    defer {
        fmt.println("Token buffers")
        for v, b in app.token_buffers {
            fmt.printfln("* len=%i, cap=%i, size=%m", len(b), cap(b), cap(b)*size_of(hi.Text_Token))
            delete(b)
        }
        delete(app.token_buffers)
    }

    app.ui.root.padding = 80
    app.ui.root.on_event = proc (v: ^hi.View, e: hi.Event) -> (consumed: bool) {
        if e.type == .wheeled do return hi.wheel_one(app.container)
        return
    }

    app.container = hi.add_view(app.ui.root, {
        flags   = { .fill_x, .fill_y, .scissor, .wheel_scroll_layout },
        layout  = { dir=.column, gap=20 },
        on_draw = draw_container_view,
    })

    for file, i in Files {
        hi.add_view(app.container, { text=file.name, flags={.text,.fill_x}, padding={0,20,0,20}, on_draw=draw_header_view })
        hi.add_view(app.container, { text=string(file.data), flags={.text,.text_raw,.text_wordy,.fill_x} })
    }

    for main_update() {
        main_draw()
        free_all(context.temp_allocator)
    }

    hi.destroy_context(app.ui)
    k2.shutdown()
}

main_update :: proc () -> (keep_running: bool) {
    keep_running = k2.update() && !k2.key_went_down(.Escape)

    dt := k2.get_frame_time()
    screen_size := k2.get_screen_size()
    wheel_delta := k2.get_mouse_wheel_delta()
    mouse_input := hi.Mouse_Input {
        lmb_down = k2.mouse_button_is_held(.Left),
        screen_pos = k2.get_mouse_position(),
        wheel_delta = wheel_delta,
    }

    if k2.key_went_down(.Tab) {
        debug := .debug not_in app.ui.root.flags
        hi.set_debug(app.ui.root, debug)
    }

    app.ui.ref_size = screen_size
    hi.update_context(app.ui, screen_size, mouse_input, dt)

    return
}

main_draw :: proc () {
    k2.clear(core.gray1)
    hi.draw_context(app.ui)
    k2.present()
}

draw_container_view :: proc (v: ^hi.Visible_View) {
    rect := k2.Rect(v.solved_rect)
    k2.draw_rect(rect, core.gray2)

    v_border :: 16
    v_rect := core.rect_inflated(hi.viewport_rect(v), v_border)
    k2.draw_rect_outline(k2.Rect(v_rect), v_border, core.gray6)
}

draw_header_view :: proc (v: ^hi.Visible_View) {
    rect := k2.Rect(v.solved_rect)
    k2.draw_rect(rect, core.gray4)
    v.ctx.on_draw_text(v)
}
