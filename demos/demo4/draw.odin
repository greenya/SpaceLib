package demo4

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:ui"
import "spacelib:raylib/draw"
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

draw_terse :: proc (f: ^ui.Frame, override_color: ^Color = nil, offset := Vec2 {}) {
    if app.debug_drawing do draw.debug_terse(f.terse)

    for word in f.terse.words {
        // if word.in_group do continue

        rect := core.rect_moved(word.rect, offset)
        tint := override_color != nil ? override_color.val : word.color
        if word.is_icon {
            sprite_id := assets_sprite_id(word.text)
            draw_sprite(sprite_id, rect, tint)
        } else {
            pos := Vec2 { rect.x, rect.y }
            font := word.font
            font_rl := (cast (^rl.Font) font.font_ptr)^
            draw.text(word.text, pos, font_rl, font.height, font.rune_spacing, tint)
        }
    }
}

draw_ui_dim_rect :: proc (f: ^ui.Frame) {
    draw.rect(f.rect, {0,0,0,200})
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
        draw_terse(f, &colors[.c2], {+1,+1})
        draw_terse(f, &colors[.c4], {-1,-1})
        return
    }

    if f.selected {
        draw_sprite(.panel_4, f.rect, colors[.c5].val)
    } else {
        draw_sprite(.panel_9, f.rect, f.entered ? colors[.c4].val : colors[.c3].val)
    }

    text_color: Color = f.entered ? colors[.c7] : colors[.c6]

    if f.captured {
        draw_terse(f, &text_color)
    } else {
        draw_terse(f, &colors[.c2], {+1,+1})
        draw_terse(f, &text_color, {-1,-1})
    }
}

draw_ui_checkbox :: proc (f: ^ui.Frame) {
    offset := f.captured ? Vec2 {+2,+2} : Vec2 {}
    text_color := f.entered ? &colors[.c8] : &colors[.c6]
    draw_terse(f, text_color, offset)

    assert(len(f.terse.groups) == 1)
    assert(len(f.terse.groups[0].words) == 1)
    assert(f.terse.groups[0].name == "tick")

    tick_rect := core.rect_moved(f.terse.groups[0].words[0].rect, offset)
    if f.selected do draw_sprite(.icon_check, tick_rect, colors[.c6].val)
}

draw_ui_link :: proc (f: ^ui.Frame) {
    offset := f.captured ? Vec2 {+2,+2} : Vec2 {}

    if f.entered {
        border := core.rect_moved(core.rect_inflated(f.terse.rect, {8,4}), {2,0}+offset)
        draw.rect_lines(border, 3, colors[.c3].val)
    }

    text_color := f.entered ? &colors[.c8] : &colors[.c6]
    draw_terse(f, text_color, offset)
}

draw_ui_button_sprite :: proc (f: ^ui.Frame, sprite_id: Sprite_ID) {
    if .disabled in f.flags {
        draw_sprite(sprite_id, f.rect, colors[.c4].val)
    } else {
        if f.entered do draw_sprite(.panel_15, f.rect, colors[.c3].val)
        draw_sprite(sprite_id, f.rect, f.entered ? colors[.c6].val : colors[.c5].val)
    }
}

draw_ui_button_sprite_icon_up :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_up) }
draw_ui_button_sprite_icon_down :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_down) }
draw_ui_button_sprite_icon_stop :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_stop) }
