package demo4

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:terse"
import "spacelib:ui"
import rl_sl "spacelib:raylib"
_ :: fmt

draw_rect :: proc (rect: Rect, tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleRec(rect_rl, tint)
}

draw_rect_lines :: proc (rect: Rect, thick := f32(1.0), tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleLinesEx(rect_rl, thick, tint)
}

draw_text_terse :: proc (text: ^terse.Text, override_color: ^Color = nil, offset := Vec2 {}) {
    debug := app.debug_drawing

    if debug {
        draw_rect_lines(text.rect, 1, {255,0,0,160})
        draw_rect(text.rect, {255,0,0,20})
    }

    for line in text.lines {
        if debug do draw_rect_lines(line.rect, 1, {255,255,128,80})
        for word in line.words {
            rect := core.rect_moved(word.rect, offset)
            tint := override_color != nil ? override_color.val : word.color
            if debug do draw_rect_lines(rect, 1, {255,255,0,40})
            if word.is_icon {
                sprite_id := assets_sprite_id(word.text)
                draw_sprite(sprite_id, rect, cast (rl.Color) tint)
            } else {
                pos := Vec2 { rect.x, rect.y }
                font := word.font
                font_rl := (cast (^rl.Font) font.font_ptr)^
                rl_sl.draw_text(word.text, pos, font_rl, font.height, font.letter_spacing, cast (rl.Color) tint)
            }
        }
    }
}

draw_sprite :: proc (id: Sprite_ID, rect: Rect, tint := rl.WHITE) {
    sprite := &sprites[id]
    texture := &textures[sprite.texture_id]
    rect_rl := transmute (rl.Rectangle) rect

    switch info in sprite.info {
    case rl.Rectangle   : rl.DrawTexturePro(texture.texture, info, rect_rl, {}, 0, tint)
    case rl.NPatchInfo  : rl.DrawTextureNPatch(texture.texture, info, rect_rl, {}, 0, tint)
    }
}

draw_ui_dim_rect :: proc (f: ^ui.Frame) {
    draw_rect(f.rect, {0,0,0,200})
}

draw_ui_border :: proc (f: ^ui.Frame) {
    draw_sprite(.border_17, f.rect, colors[.c3].val.rgba)
}

draw_ui_panel :: proc (f: ^ui.Frame) {
    draw_sprite(.panel_0, f.rect, colors[.c2].val.rgba)
}

draw_ui_button :: proc (f: ^ui.Frame) {
    if ui.disabled(f) {
        draw_sprite(.panel_9, f.rect, colors[.c3].val.rgba)
        draw_text_terse(f.text_terse, &colors[.c2], {+1,+1})
        draw_text_terse(f.text_terse, &colors[.c4], {-1,-1})
        return
    }

    if f.selected {
        draw_sprite(.panel_4, f.rect, colors[.c5].val.rgba)
    } else {
        draw_sprite(.panel_9, f.rect, f.hovered ? colors[.c4].val.rgba : colors[.c3].val.rgba)
    }

    text_color: Color = f.hovered ? colors[.c7] : colors[.c6]

    if f.captured {
        draw_text_terse(f.text_terse, &text_color)
    } else {
        draw_text_terse(f.text_terse, &colors[.c2], {+1,+1})
        draw_text_terse(f.text_terse, &text_color, {-1,-1})
    }
}

draw_ui_checkbox :: proc (f: ^ui.Frame) {
    offset := f.captured ? Vec2 {+2,+2} : Vec2 {}
    text_color := f.hovered ? &colors[.c8] : &colors[.c6]
    draw_text_terse(f.text_terse, text_color, offset)

    check_size := f.text_terse.lines[0].rect.h
    check_rect := Rect { f.text_terse.rect.x, f.text_terse.rect.y, check_size, check_size }
    check_rect = core.rect_moved(check_rect, offset)
    check_border_thick := check_size/10
    draw_rect_lines(core.rect_inflated(check_rect, {-4,-4}), check_border_thick, colors[.c3].val.rgba)

    if f.selected do draw_sprite(.icon_check, check_rect, colors[.c6].val.rgba)
}

draw_ui_link :: proc (f: ^ui.Frame) {
    offset := f.captured ? Vec2 {+2,+2} : Vec2 {}

    if f.hovered {
        border := core.rect_moved(core.rect_inflated(f.text_terse.rect, {8,4}), {2,0}+offset)
        draw_rect_lines(border, 3, colors[.c3].val.rgba)
    }

    text_color := f.hovered ? &colors[.c8] : &colors[.c6]
    draw_text_terse(f.text_terse, text_color, offset)
}

draw_ui_button_sprite :: proc (f: ^ui.Frame, sprite_id: Sprite_ID) {
    if f.hovered do draw_sprite(.panel_15, f.rect, colors[.c3].val.rgba)
    draw_sprite(sprite_id, f.rect, f.hovered ? colors[.c6].val.rgba : colors[.c5].val.rgba)
}

draw_ui_button_sprite_icon_up :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_up) }
draw_ui_button_sprite_icon_down :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_down) }
draw_ui_button_sprite_icon_stop :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_stop) }
