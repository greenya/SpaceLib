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

        on_text_measure = proc (style: hi.Text_Style, type: hi.Text_Token_Type, text: string) -> [2] f32 {
            font_height := hi.text_style_font_height(style)
            return k2.measure_text(text, font_height)
        },

        on_text_custom_token = proc (v: ^hi.View, style: ^hi.Text_Style, cmd, args: string, out_space: ^hi.Text_Custom_Token_Space) {
            switch cmd {
            case "s": // font scale; support only named scalers; empty value resets scale (same as "medium")
                switch args {
                case "tiny"         : style.font_scale = 0.6
                case "small"        : style.font_scale = 0.8
                case "medium", ""   : style.font_scale = 1.0
                case "large"        : style.font_scale = 1.3
                case "huge"         : style.font_scale = 1.6
                }

            case "c": // color; support named and hex values; empty value resets color
                switch args {
                case "muted"    : style.color = core.gray4
                case "error"    : style.color = { 220, 60, 100, 255 }
                case ""         : style.color = core.white
                case            : style.color = core.color_from_hex(args)
                }

            case "i": // icon
                if out_space != nil {
                    out_space.scale = .9
                    out_space.baseline_ratio = .85
                }

            case "perm_bits":
                if out_space != nil {
                    out_space.scale = .8 * { _perm_bits_width_scale(), 1 }
                    out_space.baseline_ratio = 1
                }
            }
        },

        on_draw_text = proc (v: ^hi.Visible_View) {
            it := hi.visible_text_iterate(v)
            for tok, tok_rect in hi.visible_text_next(&it) do #partial switch tok.type {
            case .word:
                font_height_screen := hi.text_style_font_height_screen(it.style)
                k2.draw_text(tok.text, {tok_rect.x,tok_rect.y}, font_height_screen, it.style.color)
            case .custom:
                switch tok.text {
                case "i":
                    switch tok.args { // os.File_Type.* value as string
                    case "Directory": k2.draw_rect_outline(k2.Rect(tok_rect), 2, it.style.color)
                    case "Symlink"  : k2.draw_circle(core.rect_center(tok_rect), tok_rect.w/2, it.style.color, 4)
                    case            : k2.draw_rect(k2.Rect(tok_rect), it.style.color)
                    }
                case "perm_bits":
                    panel := cast (^Panel) v.user_ptr
                    file_view := hi.child_by_any_flags(panel.ui_file_list, { .selected })
                    assert(file_view != nil)
                    file := &panel.files[file_view.user_idx]
                    _perm_bits_draw(file.mode, k2.Rect(tok_rect))
                }
            }
        },

        debug_draw_filter = { .stats, .text },
        debug_draw_line = proc (from, to: [2] f32, thick: f32, color: [4] u8) {
            k2.draw_line(from, to, thick, color)
        },
        debug_draw_text = proc (text: string, pos: [2] f32, color: [4] u8) {
            k2.draw_text(text, pos, 20, color)
        },
    })

    app.ui_panel_list = hi.add_view(app.ui.root, {
        flags   = { .fill_x, .fill_y, .scissor, .wheel_scroll_layout },
        layout  = { dir=.row, gap=10 },
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
