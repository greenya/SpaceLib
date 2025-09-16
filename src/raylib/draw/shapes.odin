package spacelib_raylib_draw

import "core:math"
import rl "vendor:raylib"

line :: proc (start, end: Vec2, thick: f32, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawLineEx(start, end, thick, color_rl)
}

rect :: proc (rect: Rect, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := rl.Color(color)
    rl.DrawRectangleRec(rect_rl, color_rl)
}

rect_rot :: proc (rect: Rect, origin_uv: Vec2, rot_rad: f32, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    origin := Vec2 { origin_uv.x * rect.w, origin_uv.y * rect.h }
    color_rl := rl.Color(color)
    rot_deg := -math.to_degrees(rot_rad)
    rl.DrawRectanglePro(rect_rl, origin, rot_deg, color_rl)
}

rect_lines :: proc (rect: Rect, thick: f32, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := rl.Color(color)
    rl.DrawRectangleLinesEx(rect_rl, thick, color_rl)
}

rect_rounded :: proc (rect: Rect, roundness_ratio: f32, segments: int, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := rl.Color(color)
    rl.DrawRectangleRounded(rect_rl, roundness_ratio, i32(segments), color_rl)
}

rect_rounded_lines :: proc (rect: Rect, roundness_ratio: f32, segments: int, thick: f32, color: Color) {
    rect_rl := transmute (rl.Rectangle) rect
    color_rl := rl.Color(color)
    rl.DrawRectangleRoundedLinesEx(rect_rl, roundness_ratio, i32(segments), thick, color_rl)
}

rect_gradient :: proc (rect: Rect, top_left, top_right, bottom_left, bottom_right: Color) {
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

rect_gradient_vertical :: proc (rect: Rect, top, bottom: Color) {
    rect_gradient(rect, top, top, bottom, bottom)
}

rect_gradient_horizontal :: proc (rect: Rect, left, right: Color) {
    rect_gradient(rect, left, right, left, right)
}

diamond :: proc (rect: Rect, color: Color) {
    c := Vec2 { rect.x+rect.w/2, rect.y+rect.h/2 }
    rect_x2 := rect.x + rect.w
    rect_y2 := rect.y + rect.h
    triangle_fan({ c, {c.x,rect.y}, {rect.x,c.y}, {c.x,rect_y2}, {rect_x2,c.y}, {c.x,rect.y} }, color)
}

diamond_lines :: proc (rect: Rect, thick: f32, color: Color) {
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

circle :: proc (center: Vec2, radius: f32, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawCircleV(center, radius, color_rl)
}

circle_gradient :: proc (center: Vec2, radius: f32, inner_color, outer_color: Color) {
    inner_color_rl := rl.Color(inner_color)
    outer_color_rl := rl.Color(outer_color)
    rl.DrawCircleGradient(i32(center.x), i32(center.y), radius, inner_color_rl, outer_color_rl)
}

ring :: proc (center: Vec2, inner_radius, outer_radius, start_rad, end_rad: f32, segments: int, color: Color) {
    start_deg := -math.to_degrees(start_rad)
    end_deg := -math.to_degrees(end_rad)
    color_rl := rl.Color(color)
    rl.DrawRing(center, inner_radius, outer_radius, start_deg, end_deg, i32(segments), color_rl)
}

// counter-clockwise order
triangle :: proc (v1, v2, v3: Vec2, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawTriangle(v1, v2, v3, color_rl)
}

// counter-clockwise order; first point is the center
triangle_fan :: proc (points: [] Vec2, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawTriangleFan(raw_data(points), i32(len(points)), color_rl)
}

// counter-clockwise order
triangle_strip :: proc (points: [] Vec2, color: Color) {
    color_rl := rl.Color(color)
    rl.DrawTriangleStrip(raw_data(points), i32(len(points)), color_rl)
}
