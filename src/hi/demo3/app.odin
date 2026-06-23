package main

import "core:slice"

import "../../core"
import hi ".."
import k2 "../../../../karl2d"

App :: struct {
    panels: [dynamic] ^Panel,

    ui              : ^hi.Context,
    ui_panel_list   : ^hi.View,
}

app: App

app_init :: proc () {
    app = {}

    app.ui = hi.create_context({
        ref_font_height = 20,
        scroll_step = 40,
        on_scissor = proc (ctx: ^hi.Context, scissor: hi.Rect) {
            k2.set_scissor_rect(scissor != {} ? k2.Rect(scissor) : nil)
        },
        on_text_measure = proc (ctx: ^hi.Context, style: hi.Text_Style, type: hi.Text_Token_Type, text: string) -> [2] f32 {
            font_height := style.font_scale * ctx.screen_font_height
            return k2.measure_text(text, font_height)
        },
        on_text_custom_command = proc (ctx: ^hi.Context, style: ^hi.Text_Style, cmd, args: string) -> (size: [2]f32) {
            switch cmd {
            case "header":
                style.align = .center
                style.font_scale = 1.3
            case "muted":
                style.color = core.gray4
            case "icon":
                // TODO: seems ugly, maybe better if we return size_scale={1,1} so it is just like font_scale
                font_h := ctx.ref_font_height * style.font_scale
                size = font_h
            }
            return
        },
        on_draw_text = proc (v: ^hi.Visible_View) {
            it := hi.visible_text_iterate(v, filter={.word,.custom})
            for tok, tok_rect in hi.visible_text_next(&it) do #partial switch tok.type {
            case .word:
                font_height := it.style.font_scale * v.ctx.screen_font_height
                k2.draw_text(tok.text, {tok_rect.x,tok_rect.y}, font_height, it.style.color)
            case .custom:
                switch tok.text {
                case "icon":
                    switch tok.args { // os.File_Type.* value as string
                    case "Directory": k2.draw_rect_outline(k2.Rect(tok_rect), 2, it.style.color)
                    case            : k2.draw_rect(k2.Rect(tok_rect), it.style.color)
                    }
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

    app.ui_panel_list = hi.add_view(app.ui.root, {
        flags   = { .fill_x, .fill_y, .scissor, .wheel_scroll_layout },
        layout  = { dir=.row, gap=1 },
        on_draw = proc (v: ^hi.Visible_View) {
            rect := k2.Rect(hi.viewport_rect(v))
            k2.draw_rect(rect, core.gray1)
        },
    })
}

app_destroy :: proc () {
    for p in app.panels do panel_destroy(p)
    delete(app.panels)

    hi.destroy_context(app.ui)
}

app_add_panel :: proc (path: string) {
    new_panel := panel_create(app.ui_panel_list, path)
    append(&app.panels, new_panel)
    hi.solve_context(app.ui)
    hi.scroll_to_end(app.ui_panel_list)
}

app_destroy_all_panels_to_the_right :: proc (last_panel_to_keep: ^Panel) {
    last_i, ok := slice.linear_search(app.panels[:], last_panel_to_keep)
    assert(ok)
    for p, i in app.panels do if i > last_i do panel_destroy(p)
    resize(&app.panels, 1 + last_i)
}
