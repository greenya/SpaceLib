package spacelib_raylib

import "core:strings"
import rl "vendor:raylib"

draw_text :: proc (text: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint := rl.WHITE) {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    rl.DrawTextEx(font, cstr, pos, font_size, font_spacing, tint)
}

draw_text_center :: proc (text: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint := rl.WHITE) -> (actual_pos: Vec2) {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_spacing)
    actual_pos = pos - size/2
    draw_text(text, actual_pos, font, font_size, font_spacing, tint)
    return
}

draw_text_right :: proc (text: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint := rl.WHITE) -> (actual_pos: Vec2) {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_size/10)
    actual_pos = pos - { size.x, 0 }
    draw_text(text, actual_pos, font, font_size, font_spacing, tint)
    return
}
