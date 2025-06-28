package demo9

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
            // has_prefix :: strings.has_prefix
            // if has_prefix(word.text, "key.")        do draw_icon_key(word.text[4:], rect, t.opacity)
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

draw_color_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(app.res.colors[f.text], f.opacity)
    draw.rect(f.rect, color)
}

draw_menu_bar_top_tab :: proc (f: ^ui.Frame) {
    // draw.rect(f.rect, app.res.colors["acc"])

    draw_terse(f.terse)
}
