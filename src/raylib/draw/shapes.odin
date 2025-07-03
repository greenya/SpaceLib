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

rect_gradient_vertical :: #force_inline proc (rect: Rect, top, bottom: Color) {
    rect_gradient(rect, top, top, bottom, bottom)
}

rect_gradient_horizontal :: #force_inline proc (rect: Rect, left, right: Color) {
    rect_gradient(rect, left, right, left, right)
}

diamond :: #force_inline proc (rect: Rect, color: Color) {
    c := Vec2 { rect.x+rect.w/2, rect.y+rect.h/2 }
    rect_x2 := rect.x + rect.w
    rect_y2 := rect.y + rect.h
    triangle_fan({ c, {c.x,rect.y}, {rect.x,c.y}, {c.x,rect_y2}, {rect_x2,c.y}, {c.x,rect.y} }, color)
}

diamond_lines :: #force_inline proc (rect: Rect, thick: f32, color: Color) {
    c := Vec2 { rect.x+rect.w/2, rect.y+rect.h/2 }
    rect_x2 := rect.x + rect.w
    rect_y2 := rect.y + rect.h
    if thick < 1.001 {
        line({c.x,rect.y}, {rect.x,c.y}, thick, color)
        line({rect.x,c.y}, {c.x,rect_y2}, thick, color)
        line({c.x,rect_y2}, {rect_x2,c.y}, thick, color)
        line({rect_x2,c.y}, {c.x,rect.y}, thick, color)
    } else {
        rect_y1_i := rect.y + thick
        rect_y2_i := rect_y2 - thick
        rect_x1_i := rect.x + thick
        rect_x2_i := rect_x2 - thick
        triangle_strip({
            {c.x,rect_y1_i}, {c.x,rect.y},
            {rect_x1_i,c.y}, {rect.x,c.y},
            {c.x,rect_y2_i}, {c.x,rect_y2},
            {rect_x2_i,c.y}, {rect_x2,c.y},
            {c.x,rect_y1_i}, {c.x,rect.y},
        }, color)
    }
}

circle :: #force_inline proc (center: Vec2, radius: f32, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawCircleV(center, radius, color_rl)
}

ring :: #force_inline proc (center: Vec2, inner_radius, outer_radius, start_angle, end_angle: f32, segments: int, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawRing(center, inner_radius, outer_radius, start_angle, end_angle, i32(segments), color_rl)
}

// counter-clockwise order
triangle :: #force_inline proc (v1, v2, v3: Vec2, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawTriangle(v1, v2, v3, color_rl)
}

// counter-clockwise order; first point is the center
triangle_fan :: #force_inline proc (points: [] Vec2, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawTriangleFan(raw_data(points), i32(len(points)), color_rl)
}

// counter-clockwise order
triangle_strip :: #force_inline proc (points: [] Vec2, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawTriangleStrip(raw_data(points), i32(len(points)), color_rl)
}
