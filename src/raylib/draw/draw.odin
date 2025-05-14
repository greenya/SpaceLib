package spacelib_raylib_draw

import "core:strings"
import rl "vendor:raylib"
import "../../terse"

line :: #force_inline proc (start, end: Vec2, thick: f32, color: Color) {
    color_rl := cast (rl.Color) color
    rl.DrawLineEx(start, end, thick, color_rl)
}

rect :: #force_inline proc (rect: Rect, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := cast (rl.Color) color
    rl.DrawRectangleRec(rect_rl, color_rl)
}

rect_lines :: #force_inline proc (rect: Rect, thick: f32, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := cast (rl.Color) color
    rl.DrawRectangleLinesEx(rect_rl, thick, color_rl)
}

text :: proc (str: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint: Color) {
    cstr := strings.clone_to_cstring(str, context.temp_allocator)
    tint_rl := cast (rl.Color) tint
    rl.DrawTextEx(font, cstr, pos, font_size, font_spacing, tint_rl)
}

text_center :: proc (str: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint: Color) -> (actual_pos: Vec2) {
    cstr := strings.clone_to_cstring(str, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_spacing)
    actual_pos = pos - size/2
    text(str, actual_pos, font, font_size, font_spacing, tint)
    return
}

text_right :: proc (str: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint: Color) -> (actual_pos: Vec2) {
    cstr := strings.clone_to_cstring(str, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_spacing)
    actual_pos = pos - { size.x, 0 }
    text(str, actual_pos, font, font_size, font_spacing, tint)
    return
}

terse :: proc (t: ^terse.Terse) {
    for word in t.words {
        if word.is_icon {
            rect_lines(word.rect, 2, word.color)
        } else {
            pos := Vec2 { word.rect.x, word.rect.y }
            font := word.font
            font_rl := (cast (^rl.Font) font.font_ptr)^
            text(word.text, pos, font_rl, font.height, font.rune_spacing, word.color)
        }
    }
}
