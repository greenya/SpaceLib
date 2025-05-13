package spacelib_raylib_draw

import "core:fmt"
import rl "vendor:raylib"
import "../../core"
import "../../terse"
import "../../ui"

@(private) Vec2 :: core.Vec2
@(private) Rect :: core.Rect
@(private) Color :: core.Color

debug_frame :: proc (f: ^ui.Frame) {
    color := _debug_frame_color(f)

    if f.rect.w > 0 && f.rect.h > 0 {
        rect_lines(f.rect, 1, color)
        if .pass in f.flags do rect({ f.rect.x+f.rect.w-10, f.rect.y, 10, 10 }, core.alpha(color, .2))
    } else if f.rect.w > 0 {
        line({ f.rect.x, f.rect.y }, { f.rect.x + f.rect.w, f.rect.y }, 3, color)
        line({ f.rect.x, f.rect.y-6 }, { f.rect.x, f.rect.y+5 }, 3, color)
        line({ f.rect.x+f.rect.w, f.rect.y-6 }, { f.rect.x+f.rect.w, f.rect.y + 5 }, 3, color)
    } else if f.rect.h > 0 {
        line({ f.rect.x, f.rect.y }, { f.rect.x, f.rect.y+f.rect.h }, 3, color)
        line({ f.rect.x-6, f.rect.y }, { f.rect.x+5, f.rect.y }, 3, color)
        line({ f.rect.x-6, f.rect.y+f.rect.h }, { f.rect.x+5, f.rect.y+f.rect.h }, 3, color)
    } else {
        line({ f.rect.x-5, f.rect.y+1 }, { f.rect.x+6, f.rect.y+1 }, 3, color)
        line({ f.rect.x+1, f.rect.y-6 }, { f.rect.x+1, f.rect.y+6 }, 3, color)
    }

    if f.parent == nil {
        cx, cy := f.rect.x + f.rect.w/2, f.rect.y + f.rect.h/2
        rect_lines(f.rect, 1, core.alpha(color, .1))
        for d in -2..=+2 {
            df := f32(d) * 200
            line({ cx+df, f.rect.y }, { cx+df, f.rect.y+f.rect.h }, 1, color)
            line({ f.rect.x, cy+df }, { f.rect.x+f.rect.w, cy+df }, 1, color)
        }
    }

    if f.text != "" {
        pos := Vec2 { f.rect.x+4, f.rect.y+2 }
        _debug_text(f.text, pos, color)
    }

    if f.order != 0 {
        text := fmt.tprintf("[order:%v]", f.order)
        pos := Vec2 { f.rect.x+4, f.rect.y+2+10 }
        _debug_text(text, pos, color)
    }

    if f.hovered {
        text := fmt.tprintf("%v x %v", f.rect.w, f.rect.h)
        pos := Vec2 { f.rect.x+f.rect.w-4, f.rect.y+2 }
        _debug_text_right(text, pos, color)
    }
}

debug_frame_layout :: proc (f: ^ui.Frame) {
    step :: 10
    size :: 20
    thick :: 2
    color := core.alpha(_debug_frame_color(f), .222)

    #partial switch f.layout.dir {
    case .left:
        rect_x2 := f.rect.x + f.rect.w
        for y := f.rect.y; y <= f.rect.y+f.rect.h; y += step {
            line({ rect_x2, y }, { rect_x2+size, y }, thick, color)
        }
    case .right:
        for y := f.rect.y; y <= f.rect.y+f.rect.h; y += step {
            line({ f.rect.x, y }, { f.rect.x-size, y }, thick, color)
        }
    case .left_and_right:
        rect_cx := f.rect.x + f.rect.w/2
        for y := f.rect.y; y <= f.rect.y+f.rect.h; y += step {
            line({ rect_cx-size, y }, { rect_cx+size, y }, thick, color)
        }
    case .up:
        rect_y2 := f.rect.y + f.rect.h
        for x := f.rect.x; x <= f.rect.x+f.rect.w; x += step {
            line({ x, rect_y2 }, { x, rect_y2+size }, thick, color)
        }
    case .down:
        for x := f.rect.x; x <= f.rect.x+f.rect.w; x += step {
            line({ x, f.rect.y }, { x, f.rect.y-size }, thick, color)
        }
    case .up_and_down:
        rect_cy := f.rect.y + f.rect.h/2
        for x := f.rect.x; x <= f.rect.x+f.rect.w; x += step {
            line({ x, rect_cy-size }, { x, rect_cy+size }, thick, color)
        }
    }
}

debug_frame_anchors :: proc (f: ^ui.Frame) {
    thick :: 3
    size :: 6
    color := core.alpha(_debug_frame_color(f), .333)

    for a in f.anchors {
        pos := _debug_anchor_point_pos(a.point, f.rect)
        rel_frame := a.rel_frame != nil ? a.rel_frame : f.parent
        rel_pos := _debug_anchor_point_pos(a.rel_point, rel_frame.rect)

        if abs(pos.x-rel_pos.x) > 0.1 || abs(pos.y-rel_pos.y) > 0.1 {
            line(rel_pos, pos, thick, color)
            line(rel_pos + {-size/2,-size/2}, rel_pos + {size/2,size/2}, thick, color)
            line(rel_pos + {size/2,-size/2}, rel_pos + {-size/2,size/2}, thick, color)
        }

        line(pos + {-size,-size}, pos + {size,size}, thick, color)
        line(pos + {size,-size}, pos + {-size,size}, thick, color)
    }
}

debug_terse_text :: proc (t: ^terse.Text) {
    rect_lines(t.rect, 1, {255,0,0,160})
    rect(t.rect, {255,0,0,20})

    for line in t.lines {
        rect_lines(line.rect, 1, {255,255,128,80})
        for word in line.words {
            rect_lines(word.rect, 1, {255,255,0,40})
        }
    }

    groups_color := Color {255,0,255,200}
    for group in t.groups do for line_rect, i in group.line_rects {
        rect_lines(line_rect, 3, groups_color)
        if i == 0 {
            font := rl.GetFontDefault()
            cstr := fmt.ctprint(group.name)
            size := rl.MeasureTextEx(font, cstr, 10, 2)
            rect({ line_rect.x, line_rect.y-size.y, size.x+2, size.y }, groups_color)
            _debug_text(group.name, { line_rect.x+2, line_rect.y-size.y }, {0,0,0,255})
        }
    }
}

@(private)
_debug_text :: proc (str: string, pos: Vec2, tint: Color) {
    font := rl.GetFontDefault()
    text(str, pos, font, 10, 1, tint)
}

@(private)
_debug_text_right :: proc (str: string, pos: Vec2, tint: Color) {
    font := rl.GetFontDefault()
    text_right(str, pos, font, 10, 1, tint)
}

@(private)
_debug_frame_color :: proc (f: ^ui.Frame) -> Color {
    gray        :: Color(rl.GRAY)
    red         :: Color(rl.RED)
    yellow      :: Color(rl.YELLOW)
    light_gray  :: Color(rl.LIGHTGRAY)
    return f.parent == nil ? gray : f.captured ? red : f.hovered ? yellow : light_gray
}

@(private)
_debug_anchor_point_pos :: proc (point: ui.Anchor_Point, using rect: Rect) -> Vec2 {
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
