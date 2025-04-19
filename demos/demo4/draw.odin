package demo4

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:ui"
import sl_rl "spacelib:raylib"

draw_rect :: proc (rect: ui.Rect, tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleRec(rect_rl, tint)
}

draw_rect_lines :: proc (rect: ui.Rect, thick := f32(1.0), tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleLinesEx(rect_rl, thick, tint)
}

draw_text :: proc (text: string, rect: ui.Rect, font_id: Font_ID, align: ui.Text_Alignment, tint := rl.WHITE) -> ui.Rect {
    font := &font_assets[font_id]

    measured_text := ui.measure_text_rect(text, rect, &font.font_sl, align, context.temp_allocator)

    if game.debug_drawing do draw_rect_lines(rect, tint={255,0,255,120})
    if game.debug_drawing do draw_rect(measured_text.rect, {255,0,0,40})

    for line in measured_text.lines {
        for word in line.words {
            if game.debug_drawing do draw_rect(word.rect, {0,255,255,80})
            sl_rl.draw_text(word.text, {word.rect.x,word.rect.y}, font.font_rl, font.height, font.letter_spacing, tint)
        }
    }

    return measured_text.rect
}

draw_sprite :: proc (id: Sprite_ID, rect: ui.Rect, tint := rl.WHITE) {
    sprite := &sprite_assets[id]
    texture := &texture_assets[sprite.texture_id]
    rect_rl := transmute (rl.Rectangle) rect

    switch info in sprite.info {
    case rl.Rectangle:  rl.DrawTexturePro(texture.texture, info, rect_rl, {}, 0, tint)
    case rl.NPatchInfo: rl.DrawTextureNPatch(texture.texture, info, rect_rl, {}, 0, tint)
    }
}

draw_ui_dim_rect :: proc (f: ^ui.Frame) {
    draw_rect(f.rect, {0,0,0,200})
}

draw_ui_border :: proc (f: ^ui.Frame) {
    draw_sprite(.border_17, f.rect, colors.three)
}

draw_ui_panel :: proc (f: ^ui.Frame) {
    draw_sprite(.panel_0, f.rect, colors.two)
}

draw_ui_button :: proc (f: ^ui.Frame) {
    if ui.disabled(f) {
        draw_sprite(.panel_9, f.rect, colors.three)
        draw_text(f.text, ui.rect_moved(f.rect, {+1,+1}), .anaheim_bold_32, {.center,.center}, colors.two)
        draw_text(f.text, ui.rect_moved(f.rect, {-1,-1}), .anaheim_bold_32, {.center,.center}, colors.four)
        return
    }

    if f.selected {
        draw_sprite(.panel_4, f.rect, colors.five)
    } else {
        draw_sprite(.panel_9, f.rect, f.hovered ? colors.four : colors.three)
    }

    text_color := f.hovered ? colors.seven : colors.six

    if f.captured {
        draw_text(f.text, f.rect, .anaheim_bold_32, {.center,.center}, text_color)
    } else {
        draw_text(f.text, ui.rect_moved(f.rect, {+1,+1}), .anaheim_bold_32, {.center,.center}, colors.two)
        draw_text(f.text, ui.rect_moved(f.rect, {-1,-1}), .anaheim_bold_32, {.center,.center}, text_color)
    }
}

draw_ui_checkbox :: proc (f: ^ui.Frame) {
    text := fmt.tprintf("%s: [ %s ]", f.text, f.selected ? "Yes" : "No")
    text_rect := draw_text(text, f.rect, .anaheim_bold_32, {.center,.center}, f.hovered ? colors.eight : colors.six)
    f.size.y = text_rect.h
}

draw_ui_link :: proc (f: ^ui.Frame) {
    text_rect := draw_text(f.text, f.rect, .anaheim_bold_32, {.center,.center}, f.hovered ? colors.eight : colors.six)

    line := text_rect
    line.y += line.h - 2
    line.h = 2
    draw_rect(line, colors.four)

    if f.hovered {
        icon_l := text_rect
        icon_l.x -= icon_l.w
        draw_text("~> ", icon_l, .anaheim_bold_32, {.center,.right}, colors.four)
        icon_r := text_rect
        icon_r.x += icon_r.w
        draw_text(" <~", icon_r, .anaheim_bold_32, {.center,.left}, colors.four)
    }

    f.size.y = text_rect.h
}

draw_ui_button_sprite :: proc (f: ^ui.Frame, sprite_id: Sprite_ID) {
    if f.hovered do draw_sprite(.panel_15, f.rect, colors.three)
    draw_sprite(sprite_id, f.rect, f.hovered ? colors.six : colors.five)
}

draw_ui_button_sprite_icon_up :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_up) }
draw_ui_button_sprite_icon_down :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_down) }
draw_ui_button_sprite_icon_stop :: proc (f: ^ui.Frame) { draw_ui_button_sprite(f, .icon_stop) }
