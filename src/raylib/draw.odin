package spacelib_raylib

import "core:strings"
import rl "vendor:raylib"

draw_line :: #force_inline proc (start, end: Vec2, thick: f32, color: Color) {
    color_rl := cast (rl.Color) color
    rl.DrawLineEx(start, end, thick, color_rl)
}

draw_rect :: #force_inline proc (rect: Rect, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := cast (rl.Color) color
    rl.DrawRectangleRec(rect_rl, color_rl)
}

draw_rect_lines :: #force_inline proc (rect: Rect, thick: f32, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := cast (rl.Color) color
    rl.DrawRectangleLinesEx(rect_rl, thick, color_rl)
}

draw_text :: proc (text: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint: Color) {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    tint_rl := cast (rl.Color) tint
    rl.DrawTextEx(font, cstr, pos, font_size, font_spacing, tint_rl)
}

draw_text_center :: proc (text: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint: Color) -> (actual_pos: Vec2) {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_spacing)
    actual_pos = pos - size/2
    draw_text(text, actual_pos, font, font_size, font_spacing, tint)
    return
}

draw_text_right :: proc (text: string, pos: Vec2, font: rl.Font, font_size, font_spacing: f32, tint: Color) -> (actual_pos: Vec2) {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_spacing)
    actual_pos = pos - { size.x, 0 }
    draw_text(text, actual_pos, font, font_size, font_spacing, tint)
    return
}
