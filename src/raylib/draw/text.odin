package spacelib_raylib_draw

import "core:strings"
import rl "vendor:raylib"
import "../../terse"

@private
text_by_rl_font :: proc (str: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint: Color) {
    cstr := strings.clone_to_cstring(str, context.temp_allocator)
    tint_rl := rl.Color(tint)
    rl.DrawTextEx(font, cstr, pos, font_size, font_spacing, tint_rl)
}

@private
text_by_tr_font :: proc (str: string, pos: Vec2, font: ^terse.Font, tint: Color) {
    font_rl := (cast (^rl.Font) font.font_ptr)^
    text_by_rl_font(str, pos, font_rl, font.height, font.rune_spacing, tint)
}

text :: proc {
    text_by_tr_font,
    text_by_rl_font,
}

@private
text_center_by_rl_font :: proc (str: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint: Color) -> (actual_pos: Vec2) {
    cstr := strings.clone_to_cstring(str, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_spacing)
    actual_pos = pos - size/2
    text(str, actual_pos, font, font_size, font_spacing, tint)
    return
}

@private
text_center_by_tr_font :: proc (str: string, pos: Vec2, font: ^terse.Font, tint: Color) -> (actual_pos: Vec2) {
    font_rl := (cast (^rl.Font) font.font_ptr)^
    return text_center_by_rl_font(str, pos, font_rl, font.height, font.rune_spacing, tint)
}

text_center :: proc {
    text_center_by_tr_font,
    text_center_by_rl_font,
}

@private
text_right_by_rl_font :: proc (str: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint: Color) -> (actual_pos: Vec2) {
    cstr := strings.clone_to_cstring(str, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_spacing)
    actual_pos = pos - { size.x, 0 }
    text(str, actual_pos, font, font_size, font_spacing, tint)
    return
}

@private
text_right_by_tr_font :: proc (str: string, pos: Vec2, font: ^terse.Font, tint: Color) -> (actual_pos: Vec2) {
    font_rl := (cast (^rl.Font) font.font_ptr)^
    return text_right_by_rl_font(str, pos, font_rl, font.height, font.rune_spacing, tint)
}

text_right :: proc {
    text_right_by_tr_font,
    text_right_by_rl_font,
}

terse :: proc (t: ^terse.Terse, draw_icon_proc: proc (word: ^terse.Word) = nil) {
    for &word in t.words {
        if word.is_icon {
            if draw_icon_proc != nil do draw_icon_proc(&word)
            else                     do rect_lines(word.rect, 2, word.color)
        } else {
            text(word.text, { word.rect.x, word.rect.y }, word.font, word.color)
        }
    }
}
