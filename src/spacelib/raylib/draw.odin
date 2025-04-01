package spacelib_raylib

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import sl ".."

debug_draw_frame :: proc (f: ^sl.Frame) {
    rect := transmute (rl.Rectangle) f.rect
    color := f.parent == nil ? rl.GRAY : rl.WHITE

    if rect.width > 0 && rect.height > 0 {
        rl.DrawRectangleRec(rect, rl.ColorAlpha(color, f.solid ? .4 : .1))
        rl.DrawRectangleLinesEx(rect, 1, color)
        if f.pressed do rl.DrawRectangleLinesEx(rect, 6, rl.RED)
        if f.hovered do rl.DrawRectangleLinesEx(rect, 2, rl.YELLOW)
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
        rl.DrawLineEx({ cx, rect.y }, { cx, rect.y+rect.height }, 1, color)
        rl.DrawLineEx({ rect.x, cy }, { rect.x+rect.width, cy }, 1, color)
    }

    if f.name != "" {
        cstr := strings.clone_to_cstring(f.name, context.temp_allocator)
        rl.DrawText(cstr, i32(rect.x) + 4, i32(rect.y) + 2, 10, color)
    }
}

debug_draw_frame_anchors :: proc (f: ^sl.Frame) {
    thick :: 2
    size :: 8
    color := rl.WHITE

    for a in f.anchors {
        pos := get_anchor_point_pos(a.point, f.rect)
        rl.DrawLineEx(pos + {-size,-size}, pos + {size,size}, thick, color)
        rl.DrawLineEx(pos + {size,-size}, pos + {-size,size}, thick, color)
    }
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
    rl.DrawTextEx(font, fmt.ctprint(text), pos, font_size, font_spacing, tint)
}

draw_text_centered :: proc (text: string, pos: sl.Vec2, font: rl.Font, font_size, font_spacing: f32, tint := rl.WHITE) -> (actual_pos: sl.Vec2) {
    size := rl.MeasureTextEx(font, fmt.ctprint(text), font_size, font_spacing)
    actual_pos = pos - size/2
    draw_text(text, actual_pos, font, font_size, font_spacing, tint)
    return
}

draw_text_righted :: proc (text: string, pos: sl.Vec2, font: rl.Font, font_size, font_spacing: f32, tint := rl.WHITE) -> (actual_pos: sl.Vec2) {
    size := rl.MeasureTextEx(font, fmt.ctprint(text), font_size, font_size/10)
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
