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

rect_rounded :: #force_inline proc (rect: Rect, roundness_ratio: f32, segments: int, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := rl.Color(color)
    rl.DrawRectangleRounded(rect_rl, roundness_ratio, i32(segments), color_rl)
}

rect_rounded_lines :: #force_inline proc (rect: Rect, roundness_ratio: f32, segments: int, thick: f32, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := rl.Color(color)
    rl.DrawRectangleRoundedLinesEx(rect_rl, roundness_ratio, i32(segments), thick, color_rl)
}

rect_gradient :: #force_inline proc (rect: Rect, top_left, top_right, bottom_left, bottom_right: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    top_left_rl := rl.Color(top_left)
    top_right_rl := rl.Color(top_right)
    bottom_left_rl := rl.Color(bottom_left)
    bottom_right_rl := rl.Color(bottom_right)
    // we change order of two last arguments because of error in Raylib, which got fixed
    // at https://github.com/raysan5/raylib/commit/19ae6f2c2d5b7789490fcee549337f3fd804359b
    // FIXME: this line needs update after Odin gets next Raylib update
    rl.DrawRectangleGradientEx(rect_rl, top_left_rl, bottom_left_rl, bottom_right_rl, top_right_rl)
}

circle :: #force_inline proc (center: Vec2, radius: f32, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawCircleV(center, radius, color_rl)
}

ring :: #force_inline proc (center: Vec2, inner_radius, outer_radius, start_angle, end_angle: f32, segments: int, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawRing(center, inner_radius, outer_radius, start_angle, end_angle, i32(segments), color_rl)
}

triangle_fan :: #force_inline proc (points: [] Vec2, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawTriangleFan(raw_data(points), i32(len(points)), color_rl)
}
