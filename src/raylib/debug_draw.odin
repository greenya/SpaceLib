package spacelib_raylib

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import "../ui"

debug_draw_frame :: proc (f: ^ui.Frame) {
    rect := transmute (rl.Rectangle) f.rect
    color := get_debug_color(f)

    if rect.width > 0 && rect.height > 0 {
        rl.DrawRectangleLinesEx(rect, 1, color)
        if f.pass do rl.DrawRectangleRec({ rect.x+rect.width-10, rect.y, 10, 10 }, rl.ColorAlpha(color, .2))
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

    if f.text != "" {
        cstr := strings.clone_to_cstring(f.text, context.temp_allocator)
        rl.DrawText(cstr, i32(rect.x) + 4, i32(rect.y) + 2, 10, color)
    }

    if f.order != 0 {
        cstr := fmt.ctprintf("[order:%v]", f.order)
        rl.DrawText(cstr, i32(rect.x) + 4, i32(rect.y) + 2 + 10, 10, color)
    }

    if f.hovered {
        cstr := fmt.ctprintf("%v x %v", f.rect.w, f.rect.h)
        cstr_w := rl.MeasureText(cstr, 10)
        rl.DrawText(cstr, i32(rect.x + rect.width) - cstr_w - 4, i32(rect.y) + 2, 10, color)
    }
}

debug_draw_frame_layout :: proc (f: ^ui.Frame) {
    step :: 10
    size :: 20
    thick :: 2
    color := rl.ColorAlpha(get_debug_color(f), .222)

    #partial switch f.layout.dir {
    case .left:
        rect_x2 := f.rect.x + f.rect.w
        for y := f.rect.y; y <= f.rect.y+f.rect.h; y += step {
            rl.DrawLineEx({ rect_x2, y }, { rect_x2+size, y }, thick, color)
        }
    case .right:
        for y := f.rect.y; y <= f.rect.y+f.rect.h; y += step {
            rl.DrawLineEx({ f.rect.x, y }, { f.rect.x-size, y }, thick, color)
        }
    case .left_and_right:
        rect_cx := f.rect.x + f.rect.w/2
        for y := f.rect.y; y <= f.rect.y+f.rect.h; y += step {
            rl.DrawLineEx({ rect_cx-size, y }, { rect_cx+size, y }, thick, color)
        }
    case .up:
        rect_y2 := f.rect.y + f.rect.h
        for x := f.rect.x; x <= f.rect.x+f.rect.w; x += step {
            rl.DrawLineEx({ x, rect_y2 }, { x, rect_y2+size }, thick, color)
        }
    case .down:
        for x := f.rect.x; x <= f.rect.x+f.rect.w; x += step {
            rl.DrawLineEx({ x, f.rect.y }, { x, f.rect.y-size }, thick, color)
        }
    case .up_and_down:
        rect_cy := f.rect.y + f.rect.h/2
        for x := f.rect.x; x <= f.rect.x+f.rect.w; x += step {
            rl.DrawLineEx({ x, rect_cy-size }, { x, rect_cy+size }, thick, color)
        }
    }
}

debug_draw_frame_anchors :: proc (f: ^ui.Frame) {
    thick :: 3
    size :: 6
    color := rl.ColorAlpha(get_debug_color(f), .333)

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
get_debug_color :: proc (f: ^ui.Frame) -> rl.Color {
    return f.parent == nil ? rl.GRAY : f.captured ? rl.RED : f.hovered ? rl.YELLOW : rl.LIGHTGRAY
}

@(private)
get_anchor_point_pos :: proc (point: ui.Anchor_Point, using rect: Rect) -> Vec2 {
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
