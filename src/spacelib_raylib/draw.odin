package spacelib_raylib

import "core:strings"
import rl "vendor:raylib"
import sl "../spacelib"

debug_draw_frame :: proc (f: ^sl.Frame) {
    rect := transmute(rl.Rectangle) f.rect
    color := f.parent == nil ? rl.GRAY : f.pressed ? rl.RED : f.hovered ? rl.YELLOW : rl.WHITE
    thick := f.parent == nil ? f32(10) : f.pressed ? f32(4) : f.hovered ? f32(2) : f32(1)
    with_center := f.parent == nil

    if rect.width > 0 && rect.height > 0 {
        rl.DrawRectangleRec(rect, rl.ColorAlpha(color, .1))
        rl.DrawRectangleLinesEx(rect, thick, color)
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

    if with_center {
        cx, cy := rect.x + rect.width/2, rect.y + rect.height/2
        rl.DrawRectangleLinesEx(rect, thick, rl.ColorAlpha(color, .1))
        rl.DrawLineEx({ cx, rect.y }, { cx, rect.y+rect.height }, thick, color)
        rl.DrawLineEx({ rect.x, cy }, { rect.x+rect.width, cy }, thick, color)
    }

    if f.text != "" {
        cstr := strings.clone_to_cstring(f.text, context.temp_allocator)
        rl.DrawText(cstr, i32(rect.x) + 4, i32(rect.y) + 2, 10, color)
    }
}
