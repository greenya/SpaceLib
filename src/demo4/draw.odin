package demo4

import rl "vendor:raylib"
import sl "../spacelib"
import sl_rl "../spacelib/raylib"

draw_rect :: proc (rect: sl.Rect, tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleRec(rect_rl, tint)
}

draw_text_centered :: proc (text: string, pos: sl.Vec2, font_id: Font_ID, tint := rl.WHITE) {
    font := &font_assets[font_id]
    sl_rl.draw_text_centered(text, pos, font.font, font.size, font.spacing, tint)
}

draw_sprite :: proc (id: Sprite_ID, dest_rect: sl.Rect, tint := rl.WHITE) {
    sprite := &sprite_assets[id]
    if sprite.npatch != {} {
        texture := &texture_assets[sprite.texture_id]
        dest_rect_rl := transmute (rl.Rectangle) dest_rect
        rl.DrawTextureNPatch(texture.texture, sprite.npatch, dest_rect_rl, {}, 0, tint)
    } else {
        panic("Not implemented yet.")
    }
}

draw_ui_dim_rect :: proc (f: ^sl.Frame) {
    draw_rect(f.rect, {0,0,0,192})
}

draw_ui_panel :: proc (f: ^sl.Frame) {
    draw_sprite(.panel_0, f.rect, colors.two)
}

draw_ui_button :: proc (f: ^sl.Frame) {
    center := sl.rect_center(f.rect)
    color := f.hovered ? colors.six : colors.five
    text := f.name

    draw_sprite(.panel_9, f.rect, f.hovered ? colors.four : colors.three)

    if f.pressed {
        draw_text_centered(text, center, .anaheim_bold_32, color)
    } else {
        draw_text_centered(text, center + {1,1}, .anaheim_bold_32, colors.one)
        draw_text_centered(text, center - {1,1}, .anaheim_bold_32, color)
    }
}
