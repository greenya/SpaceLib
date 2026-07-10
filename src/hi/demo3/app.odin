package main

import "core:os"
import "core:slice"
import "core:strconv"

import "../../core"
import hi ".."
import k2 "../../../../karl2d"

APP_DEFAULT_FONT_HEIGHT :: 20
APP_DEFAULT_PANEL_WIDTH :: 300

App :: struct {
    panels  : [dynamic] ^Panel,
    popup   : ^Popup,

    ui              : ^hi.Context,
    ui_panel_list   : ^hi.View,
}

app: App

app_init :: proc () {
    app = {}

    app.ui = hi.create_context({
        ref_font_height = APP_DEFAULT_FONT_HEIGHT,
        scroll_step = 2 * APP_DEFAULT_FONT_HEIGHT,

        on_scissor = proc (ctx: ^hi.Context, scissor: hi.Rect) {
            k2.set_scissor_rect(scissor != {} ? k2.Rect(scissor) : nil)
        },

        on_text_measure = proc (style: hi.Text_Style, type: hi.Text_Token_Type, text: string) -> [2] f32 {
            font_height := hi.text_style_font_height(style)
            return k2.measure_text(text, font_height)
        },

        on_text_custom_token = proc (v: ^hi.View, style: ^hi.Text_Style, name, args: string, out_hint: ^hi.Text_Custom_Token_Hint) {
            switch name {
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
            case "b": // baseline; modifies font scale; empty value resets baseline and font scale
                      // note: doesn't track current font scale, and assumes medium font size
                switch args {
                case "super"    : style.font_scale = 0.6; style.font_baseline_ratio = 1.3
                case "index"    : style.font_scale = 0.6; style.font_baseline_ratio = 0.6
                case ""         : style.font_scale = 1.0; style.font_baseline_ratio = hi.Text_Style_Default.font_baseline_ratio
                }
            case "i": // icon
                if out_hint != nil {
                    out_hint.scale = .9
                    out_hint.baseline_ratio = .85
                }
            case "file_mode":
                if out_hint != nil {
                    out_hint.scale = .8 * { _file_mode_width_scale(), 1 }
                }
            case "divider":
                if out_hint != nil {
                    out_hint.scale = { 1, .5 }
                    out_hint.scale_full_line = true
                }
            case "counter":
                if out_hint != nil {
                    assert(v == app.popup.ui_page_demo && args == "value")
                    out_hint.intext_view = app.popup.ui_page_demo_counter
                }
            case "button":
                if out_hint != nil {
                    assert(v == app.popup.ui_page_demo)
                    out_hint.intext_view = hi.child_by_name(v, args)
                }
            }
        },

        on_text_wordy = proc (v: ^hi.View) -> (buf: ^[dynamic] hi.Text_Token) {
            if v == app.popup.ui_page_text do return &app.popup.buf_tokens
            return
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
                case "file_mode":
                    mode, ok := strconv.parse_int(tok.args, base=16)
                    assert(ok)
                    _file_mode_draw(transmute (os.Permissions) u32(mode), k2.Rect(tok_rect), it.style.color)
                case "divider":
                    k2.draw_rect(k2.Rect(tok_rect), it.style.color)
                }
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

    app.ui_panel_list = hi.add_view(app.ui.root, {
        flags   = { .ratio_x, .ratio_y, .scissor, .wheel_scroll_layout },
        size    = 1,
        layout  = { dir=.row, gap=10 },
        on_draw = proc (v: ^hi.Visible_View) {
            rect := k2.Rect(v.solved_rect)
            k2.draw_rect(rect, core.gray1)
        },
    })

    app.popup = popup_create(app.ui_panel_list)
}

app_destroy :: proc () {
    for p in app.panels do panel_destroy(p)
    delete(app.panels)
    popup_destroy(app.popup)
    hi.destroy_context(app.ui)
}

app_add_panel :: proc (path: string) {
    new_panel := panel_create(app.ui_panel_list, path)
    append(&app.panels, new_panel)
    app_apply_panels_width()
    hi.set_debug(new_panel.ui_root, .debug in app.ui.root.flags) // propagate current debug state
    hi.solve_context(app.ui)
    hi.scroll_to_end(app.ui_panel_list)
}

app_destroy_all_panels_to_the_right :: proc (last_panel_to_keep: ^Panel) {
    last_i, ok := slice.linear_search(app.panels[:], last_panel_to_keep)
    assert(ok)
    for p, i in app.panels do if i > last_i do panel_destroy(p)
    resize(&app.panels, 1 + last_i)
}

app_apply_panels_width :: proc (width := f32(0)) {
    assert(len(app.panels) > 0)
    p0_v := app.panels[0].ui_root

    // Apply new width to 1st panel if value provided
    if width > 0 {
        p0_v.size.x = width
        if width <= 1 do p0_v.flags += { .ratio_x }
        else          do p0_v.flags -= { .ratio_x }
    }

    // Apply current width of 1st panel to all other panels
    for i := 1; i < len(app.panels); i += 1 {
        pN_v := app.panels[i].ui_root
        pN_v.size.x = p0_v.size.x
        pN_v.flags = (pN_v.flags - { .ratio_x }) | (p0_v.flags & { .ratio_x })
    }

    hi.queue_solve_context(app.ui)
}

app_open_popup_for_file :: proc (file: ^os.File_Info) {
    popup_open(app.popup, file)
}
