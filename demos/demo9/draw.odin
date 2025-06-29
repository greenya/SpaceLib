package demo9

import "core:strings"
import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"
import "spacelib:terse"
import rl "vendor:raylib"

draw_terse :: proc (t: ^terse.Terse, override_color := "", offset := Vec2 {}) {
    assert(t != nil)
    for word in t.words {
        // if word.in_group do continue

        rect := offset != {} ? core.rect_moved(word.rect, offset) : word.rect
        tint := override_color != "" ? app.res.colors[override_color].value : word.color
        tint = core.alpha(tint, t.opacity)
        if word.is_icon {
            has_prefix :: strings.has_prefix
            if has_prefix(word.text, "key/")        do draw_icon_key(word.text[4:], rect, t.opacity)
            // else if has_prefix(word.text, "card.")  do draw_icon_card(word.text[5:], rect, t.opacity)
            // else                                    do draw_sprite(word.text, rect, tint)
        } else if word.text != " " {
            pos := Vec2 { rect.x, rect.y }
            font := word.font
            font_rl := (cast (^rl.Font) font.font_ptr)^
            draw.text(word.text, pos, font_rl, font.height, font.rune_spacing, tint)
        }
    }

    if app.debug_drawing do draw.debug_terse(t)
}

draw_text_center :: proc (text: string, rect: Rect, font_name: string, color: Color) {
    font_tr := &app.res.fonts[font_name].font_tr
    draw.text_center(text, core.rect_center(rect), font_tr, color)
}

draw_icon_key :: proc (text: string, rect: Rect, opacity: f32) {
    bg_color := core.alpha(app.res.colors["pri"].value, opacity)
    draw.rect(rect, bg_color)
    tx_color := core.alpha(app.res.colors["bg0"].value, opacity)
    draw_text_center(text, rect, "text_5r", tx_color)
}

draw_color_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(app.res.colors[f.text], f.opacity)
    draw.rect(f.rect, color)
}

draw_menu_bar_action_button :: proc (f: ^ui.Frame) {
    offset := f.captured ? Vec2 {0,2} : {}
    draw_terse(f.terse, offset=offset)

    ln_color_name := f.entered ? "acc" : "pri"
    ln_color := core.alpha(app.res.colors[ln_color_name], f.opacity)

    ln_rect := core.rect_moved(f.rect, offset)
    draw.rect_lines(ln_rect, 1, ln_color)
}

draw_menu_bar_top_tab :: proc (f: ^ui.Frame) {
    if f.selected {
        bg_color := core.alpha(app.res.colors["acc"], f.opacity * .25)
        draw.rect(f.rect, bg_color) // todo: maybe draw gradient sprite

        br_color := core.alpha(app.res.colors["acc"], f.opacity)
        br_rect := core.rect_line_bottom(f.rect, 4)
        draw.rect(br_rect, br_color)

        br_left_rect := core.rect_line_left(f.rect, .5)
        draw.rect(br_left_rect, br_color)

        br_right_rect := core.rect_line_right(f.rect, .5)
        draw.rect(br_right_rect, br_color)

        draw_terse(f.terse, "bg0", {0,2})
    }

    tx_color := f.selected ? "acc" : "pri"
    draw_terse(f.terse, tx_color)
}

draw_menu_bar_top_tab_unspent_points :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(app.res.colors["pri"], f.opacity)
    draw.rect(f.rect, bg_color)
    br_color := core.brightness(bg_color, -.555)
    draw.rect_lines(f.rect, 2, br_color)
    draw_terse(f.terse)
}
