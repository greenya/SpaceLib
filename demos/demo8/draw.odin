package demo8

import "core:fmt"
import "core:strings"
import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"
import "spacelib:terse"
import rl "vendor:raylib"

draw_sprite :: proc (name: string, rect: Rect, tint: Color) {
    fmt.assertf(name in app.res.sprites, "Unknown sprite: \"%s\"", name)
    sprite := app.res.sprites[name]
    texture := app.res.textures[sprite.texture]
    rect_rl := transmute (rl.Rectangle) rect
    tint_rl := rl.Color(tint)

    switch info in sprite.info {
    case rl.Rectangle:  rl.DrawTexturePro(texture.texture_rl, info, rect_rl, {}, 0, tint_rl)
    case rl.NPatchInfo: rl.DrawTextureNPatch(texture.texture_rl, info, rect_rl, {}, 0, tint_rl)
    }
}

draw_text_center :: proc (text: string, rect: Rect, font_name: string, color_name: string) {
    tx_font := &app.res.fonts[font_name].font_tr
    tx_color := app.res.colors[color_name].value
    draw.text_center(text, core.rect_center(rect), tx_font, tx_color)
}

draw_icon_key :: proc (text: string, rect: Rect) {
    bg_color := app.res.colors["bw_1a"].value
    draw.rect(rect, bg_color)
    draw_text_center(text, rect, "text_24", "bw_6c")
}

draw_terse :: proc (t: ^terse.Terse, override_color := "", offset := Vec2 {}) {
    for word in t.words {
        // if word.in_group do continue

        rect := offset != {} ? core.rect_moved(word.rect, offset) : word.rect
        tint := override_color != "" ? app.res.colors[override_color].value : word.color
        if word.is_icon {
            if strings.has_prefix(word.text, "key_") {
                draw_icon_key(word.text[4:], rect)
            } else {
                draw_sprite(word.text, rect, tint)
            }
        } else {
            pos := Vec2 { rect.x, rect.y }
            font := word.font
            font_rl := (cast (^rl.Font) font.font_ptr)^
            draw.text(word.text, pos, font_rl, font.height, font.rune_spacing, tint)
        }
    }

    if app.debug_drawing do draw.debug_terse(t)
}

draw_black_rect :: proc (f: ^ui.Frame) {
    draw.rect(f.rect, app.res.colors["bw_00"])
}

draw_menu_item :: proc (f: ^ui.Frame) {
    draw_text_center(f.text, f.rect, "text_20", f.selected ? "bw_da" : "bw_59")
    if f.selected {
        draw.rect(core.rect_line_bottom(f.rect, 4), app.res.colors["bw_1a"].value)
    }
}

draw_art_ring :: proc (f: ^ui.Frame) {
    color := core.alpha(app.res.colors["bw_40"].value, .2)
    center := core.rect_center(f.rect)
    radius := f.rect.h/2
    draw.ring(center, radius, radius+8, 0, 360, 64, color)
}

draw_slot_ring :: proc (f: ^ui.Frame) {
    bg_color := app.res.colors["bw_11"].value
    br_color := app.res.colors["bw_40"].value
    center := core.rect_center(f.rect)
    radius := f.rect.h/2
    draw.circle(center, radius, bg_color)
    draw.ring(center, radius, radius+2, 0, 360, 32, br_color)
}

draw_slot_round :: proc (f: ^ui.Frame) {
    draw_slot_ring(f)
    sp_color := app.res.colors["bw_bc"].value
    draw_sprite(f.text, f.rect, sp_color)
}

draw_slot_round_level :: proc (f: ^ui.Frame) {
    draw_slot_ring(f)
    draw_text_center(f.text, f.rect, "text_24", "bw_da")
}

draw_slot_rect :: proc (f: ^ui.Frame) {
    bg_color := app.res.colors["bw_11"].value
    br_color := app.res.colors["bw_40"].value
    draw.rect(f.rect, bg_color)
    draw.rect_lines(f.rect, 2, br_color)
}

draw_slot_box :: proc (f: ^ui.Frame) {
    draw_slot_rect(f)
    if f.text != "" {
        sp_color := app.res.colors["bw_bc"].value
        draw_sprite(f.text, core.rect_inflated(f.rect, -8), sp_color)
    }
}

draw_slot_box_wide :: proc (f: ^ui.Frame) {
    draw_slot_rect(f)
    if f.text != "" {
        sp_color := app.res.colors["bw_bc"].value
        rect := f.rect
        rect.w = rect.h
        draw_sprite(f.text, core.rect_inflated(rect, -8), sp_color)
    }
}
