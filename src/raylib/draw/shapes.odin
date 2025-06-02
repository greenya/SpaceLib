package spacelib_raylib_draw

import rl "vendor:raylib"

line :: #force_inline proc (start, end: Vec2, thick: f32, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawLineEx(start, end, thick, color_rl)
}

rect :: #force_inline proc (rect: Rect, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := rl.Color(color)
    rl.DrawRectangleRec(rect_rl, color_rl)
}

rect_lines :: #force_inline proc (rect: Rect, thick: f32, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := rl.Color(color)
    rl.DrawRectangleLinesEx(rect_rl, thick, color_rl)
}

circle :: #force_inline proc (center: Vec2, radius: f32, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawCircleV(center, radius, color_rl)
}

ring :: #force_inline proc (center: Vec2, inner_radius, outer_radius, start_angle, end_angle: f32, segments: int, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawRing(center, inner_radius, outer_radius, start_angle, end_angle, i32(segments), color_rl)
}
