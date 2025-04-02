package spacelib_raylib

import "core:strings"
import rl "vendor:raylib"
import sl ".."

debug_draw_frame :: proc (f: ^sl.Frame) {
    rect := transmute (rl.Rectangle) f.rect
    color := get_debug_color(f)

    if rect.width > 0 && rect.height > 0 {
        rl.DrawRectangleLinesEx(rect, 1, color)
        if f.solid do rl.DrawRectangleRec({ rect.x+rect.width-20, rect.y, 20, 20 }, color)
    } else if rect.width > 0 {
        rl.DrawLineEx({ rect.x, rect.y }, { rect.x + rect.width, rect.y }, 3, color)
        rl.DrawLineEx({ rect.x, rect.y-6 }, { rect.x, rect.y+5 }, 3, color)
        rl.DrawLineEx({ rect.x+rect.width, rect.y-6 }, { rect.x+rect.width, rect.y + 5 }, 3, color)
    } else if rect.height > 0 {
        rl.DrawLineEx({ rect.x, rect.y }, { rect.x, rect.y+rect.height }, 3, color)
        rl.DrawLineEx({ rect.x-6, rect.y }, { rect.x+5, rect.y }, 3, color)
        rl.DrawLineEx({ rect.x-6, rect.y+rect.height }, { rect.x+5, rect.y+rect.height }, 3, color)
    } else {
        rl.DrawLineEx({ rect.x-5, rect.y+1 }, { rect.x+6, rect.y+1 }, 3, color)
        rl.DrawLineEx({ rect.x+1, rect.y-6 }, { rect.x+1, rect.y+6 }, 3, color)
    }

    if f.parent == nil {
        cx, cy := rect.x + rect.width/2, rect.y + rect.height/2
        rl.DrawRectangleLinesEx(rect, 1, rl.ColorAlpha(color, .1))
        for d in -2..=+2 {
            df := f32(d) * 200
            rl.DrawLineEx({ cx+df, rect.y }, { cx+df, rect.y+rect.height }, 1, color)
            rl.DrawLineEx({ rect.x, cy+df }, { rect.x+rect.width, cy+df }, 1, color)
        }
    }

    if f.name != "" {
        cstr := strings.clone_to_cstring(f.name, context.temp_allocator)
        rl.DrawText(cstr, i32(rect.x) + 4, i32(rect.y) + 2, 10, color)
    }
}

debug_draw_frame_anchors :: proc (f: ^sl.Frame) {
    thick :: 1
    size :: 6
    color := get_debug_color(f)

    for a in f.anchors {
        pos := get_anchor_point_pos(a.point, f.rect)
        rel_frame := a.rel_frame != nil ? a.rel_frame : f.parent
        rel_pos := get_anchor_point_pos(a.rel_point, rel_frame.rect)

        if abs(pos.x-rel_pos.x) > 0.1 || abs(pos.y-rel_pos.y) > 0.1 {
            rl.DrawLineEx(rel_pos, pos, thick, color)
            rl.DrawLineEx(rel_pos + {-size/2,-size/2}, rel_pos + {size/2,size/2}, thick, color)
            rl.DrawLineEx(rel_pos + {size/2,-size/2}, rel_pos + {-size/2,size/2}, thick, color)
        }

        rl.DrawLineEx(pos + {-size,-size}, pos + {size,size}, thick, color)
        rl.DrawLineEx(pos + {size,-size}, pos + {-size,size}, thick, color)
    }
}

@(private)
get_debug_color :: proc (f: ^sl.Frame) -> rl.Color {
    return f.parent == nil ? rl.GRAY : f.pressed ? rl.RED : f.hovered ? rl.YELLOW : rl.LIGHTGRAY
}

@(private)
get_anchor_point_pos :: proc (point: sl.Anchor_Point, using rect: sl.Rect) -> sl.Vec2 {
    #partial switch point {
    case .top_left      : return { x, y }
    case .top           : return { x+w/2, y }
    case .top_right     : return { x+w, y }
    case .left          : return { x, y+h/2 }
    case .center        : return { x+w/2, y+h/2 }
    case .right         : return { x+w, y+h/2 }
    case .bottom_left   : return { x, y+h }
    case .bottom        : return { x+w/2, y+h }
    case .bottom_right  : return { x+w, y+h }
    case                : return {}
    }
}

draw_text :: proc (text: string, pos: sl.Vec2, font: rl.Font, font_size, font_spacing: f32, tint := rl.WHITE) {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    rl.DrawTextEx(font, cstr, pos, font_size, font_spacing, tint)
}

draw_text_centered :: proc (text: string, pos: sl.Vec2, font: rl.Font, font_size, font_spacing: f32, tint := rl.WHITE) -> (actual_pos: sl.Vec2) {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_spacing)
    actual_pos = pos - size/2
    draw_text(text, actual_pos, font, font_size, font_spacing, tint)
    return
}

draw_text_righted :: proc (text: string, pos: sl.Vec2, font: rl.Font, font_size, font_spacing: f32, tint := rl.WHITE) -> (actual_pos: sl.Vec2) {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_size/10)
    actual_pos = pos - { size.x, 0 }
    draw_text(text, actual_pos, font, font_size, font_spacing, tint)
    return
}

draw_text_boxed :: proc (text: string, rect: sl.Rect, font: rl.Font, font_size, font_spacing: f32, tint := rl.WHITE) -> (text_rect: sl.Rect) {
    space_size := sl.Vec2 { font_size/2, font_size }

    rect := transmute (rl.Rectangle) rect
    pos := sl.Vec2 { rect.x, rect.y }
    rect_right := rect.x + rect.width
    rect_bottom := rect.y + rect.height

    loop: for p in strings.split(text, "\n", context.temp_allocator) {
        for s in strings.split(p, " ", context.temp_allocator) {
            cs := strings.clone_to_cstring(s, context.temp_allocator)
            size := rl.MeasureTextEx(font, cs, font_size, font_spacing)

            if pos.x + size.x > rect_right {
                pos.x = rect.x
                pos.y += space_size.y
                if pos.y > rect_bottom do break loop
            }

            rl.DrawTextEx(font, cs, pos, font_size, font_spacing, tint)
            pos.x += size.x + space_size.x
        }

        pos.x = rect.x
        pos.y += space_size.y
        if pos.y > rect_bottom do break
    }

    return { rect.x, rect.y, rect.width, pos.y - rect.y }
}
