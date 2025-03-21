package spacelib_raylib

import "core:strings"
import rl "vendor:raylib"
import sl "../spacelib"

debug_draw_frame :: proc (f: ^sl.Frame) {
    rect := transmute(rl.Rectangle) f.rect
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

    if f.text != "" {
        cstr := strings.clone_to_cstring(f.text, context.temp_allocator)
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
