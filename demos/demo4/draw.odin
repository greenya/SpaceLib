package demo4

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:terse"
import "spacelib:ui"
import rl_sl "spacelib:raylib"
_ :: fmt

draw_sprite :: proc (id: Sprite_ID, rect: Rect, tint: core.Color) {
    sprite := &sprites[id]
    texture := &textures[sprite.texture_id]
    rect_rl := transmute (rl.Rectangle) rect
    tint_rl := cast (rl.Color) tint

    switch info in sprite.info {
    case rl.Rectangle   : rl.DrawTexturePro(texture.texture_rl, info, rect_rl, {}, 0, tint_rl)
    case rl.NPatchInfo  : rl.DrawTextureNPatch(texture.texture_rl, info, rect_rl, {}, 0, tint_rl)
    }
}

draw_text_terse :: proc (text: ^terse.Text, override_color: ^Color = nil, offset := Vec2 {}) {
    if app.debug_drawing do rl_sl.debug_draw_terse_text(text)

    for line in text.lines {
        for word in line.words {
            rect := core.rect_moved(word.rect, offset)
            tint := override_color != nil ? override_color.val : word.color
            if word.is_icon {
                sprite_id := assets_sprite_id(word.text)
                draw_sprite(sprite_id, rect, tint)
            } else {
                pos := Vec2 { rect.x, rect.y }
                font := word.font
                font_rl := (cast (^rl.Font) font.font_ptr)^
                rl_sl.draw_text(word.text, pos, font_rl, font.height, font.letter_spacing, tint)
            }
        }
    }
}

draw_ui_dim_rect :: proc (f: ^ui.Frame) {
    rl_sl.draw_rect(f.rect, {0,0,0,200})
}

draw_ui_border_17 :: proc (f: ^ui.Frame) {
    draw_sprite(.border_17, f.rect, colors[.c3].val)
}

draw_ui_border_15 :: proc (f: ^ui.Frame) {
    draw_sprite(.border_15, f.rect, colors[.c4].val)
}

draw_ui_panel :: proc (f: ^ui.Frame) {
    draw_sprite(.panel_0, f.rect, colors[.c2].val)
}

draw_ui_button :: proc (f: ^ui.Frame) {
    if ui.disabled(f) {
        draw_sprite(.panel_9, f.rect, colors[.c3].val)
        draw_text_terse(f.text_terse, &colors[.c2], {+1,+1})
        draw_text_terse(f.text_terse, &colors[.c4], {-1,-1})
        return
    }

    if f.selected {
        draw_sprite(.panel_4, f.rect, colors[.c5].val)
    } else {
        draw_sprite(.panel_9, f.rect, f.hovered ? colors[.c4].val : colors[.c3].val)
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

    assert(f.text_terse.groups[0].name == "tick")
    tick_rect := core.rect_moved(f.text_terse.groups[0].line_rects[0], offset)

    if f.selected do draw_sprite(.icon_check, tick_rect, colors[.c6].val)
}

draw_ui_link :: proc (f: ^ui.Frame) {
    offset := f.captured ? Vec2 {+2,+2} : Vec2 {}

    if f.hovered {
        border := core.rect_moved(core.rect_inflated(f.text_terse.rect, {8,4}), {2,0}+offset)
        rl_sl.draw_rect_lines(border, 3, colors[.c3].val)
    }

    text_color := f.hovered ? &colors[.c8] : &colors[.c6]
    draw_text_terse(f.text_terse, text_color, offset)
}

draw_ui_button_sprite :: proc (f: ^ui.Frame, sprite_id: Sprite_ID) {
    if f.hovered do draw_sprite(.panel_15, f.rect, colors[.c3].val)
    draw_sprite(sprite_id, f.rect, f.hovered ? colors[.c6].val : colors[.c5].val)
}

draw_ui_button_sprite_icon_up :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_up) }
draw_ui_button_sprite_icon_down :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_down) }
draw_ui_button_sprite_icon_stop :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_stop) }
