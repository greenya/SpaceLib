package spacelib_raylib_draw

import "core:fmt"
import rl "vendor:raylib"
import "../../core"
import "../../terse"
import "../../ui"
import "../res"

@private Vec2 :: core.Vec2
@private Rect :: core.Rect
@private Color :: core.Color

Debug_Frame_Filter :: enum {
    scissor,
    anchors,
    layout,
    terse,
}

debug_frame :: proc (f: ^ui.Frame, filter := ~bit_set [Debug_Frame_Filter] {}) {
    assert(f != nil)

    color := _debug_frame_color(f)

    if f.parent == nil {
        cx, cy := f.rect.x + f.rect.w/2, f.rect.y + f.rect.h/2
        clr := core.alpha(color, .1)
        rect_lines(f.rect, 4, clr)
        for d in -2..=+2 {
            df := f32(d) * 200
            line({ cx+df, f.rect.y }, { cx+df, f.rect.y+f.rect.h }, 4, clr)
            line({ f.rect.x, cy+df }, { f.rect.x+f.rect.w, cy+df }, 4, clr)
        }
    } else {
        if f.rect.w > 0 && f.rect.h > 0 {
            rect_lines(f.rect, 1, color)
            if ui.passing(f) do rect({ f.rect.x+f.rect.w-10, f.rect.y, 10, 10 }, core.alpha(color, .2))
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
    }

    if .scissor in filter                   do debug_frame_scissor(f)
    if .anchors in filter                   do debug_frame_anchors(f)
    if .layout in filter                    do debug_frame_layout(f)
    if .terse in filter && f.terse != nil   do debug_terse(f.terse)

    if f.name != "" do _debug_text(f.name, { f.rect.x+4, f.rect.y+2 }, color)

    if f.order != 0 {
        text := fmt.tprintf("[order:%v]", f.order)
        pos := Vec2 { f.rect.x+4, f.rect.y+2 + (f.name!=""?10:0) }
        _debug_text(text, pos, color)
    }

    if f.entered {
        c := core.rect_center(f.rect)
        line({ c.x-9, c.y }, { c.x+8, c.y }, 1, color)
        line({ c.x, c.y-9 }, { c.x, c.y+8 }, 1, color)

        text := fmt.tprintf("%.0fx%.0f", f.rect.w, f.rect.h)
        pos := Vec2 { f.rect.x+f.rect.w-4, f.rect.y+2 }
        _debug_text_right(text, pos, color)
    }
}

debug_frame_tree :: proc (f: ^ui.Frame) {
    debug_frame(f)
    for child in f.children do debug_frame_tree(child)
}

debug_frame_scissor :: proc (f: ^ui.Frame) {
    assert(f != nil)
    if .scissor in f.flags {
        rect_lines(core.rect_inflated(f.rect, 4), 4, core.aqua)
    }
}

debug_frame_anchors :: proc (f: ^ui.Frame) {
    assert(f != nil)

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

debug_frame_layout :: proc (f: ^ui.Frame) {
    assert(f != nil)

    step :: 10
    size :: 20
    thick :: 2
    color := core.alpha(_debug_frame_color(f), .222)

    switch l in f.layout {
    case ui.Flow:
        switch l.dir {
        case .left:
            rect_x2 := f.rect.x + f.rect.w
            for y := f.rect.y; y <= f.rect.y+f.rect.h; y += step {
                line({ rect_x2, y }, { rect_x2+size, y }, thick, color)
            }
        case .right:
            for y := f.rect.y; y <= f.rect.y+f.rect.h; y += step {
                line({ f.rect.x, y }, { f.rect.x-size, y }, thick, color)
            }
        case .right_center:
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
        case .down_center:
            rect_cy := f.rect.y + f.rect.h/2
            for x := f.rect.x; x <= f.rect.x+f.rect.w; x += step {
                line({ x, rect_cy-size }, { x, rect_cy+size }, thick, color)
            }
        }
        if l.scroll.step > 0 do switch l.dir {
        case .left, .right, .right_center:
            bar := core.rect_bar_top(f.rect, 8)
            bar = core.rect_inflated(bar, {-8,0})
            bar.y += 4
            rect(bar, color)
        case .up, .down, .down_center:
            bar := core.rect_bar_left(f.rect, 8)
            bar = core.rect_inflated(bar, {0,-8})
            bar.x += 4
            rect(bar, color)
        }
    case ui.Grid:
        mark := Rect {0,0,8,8}
        for i in 0..<2 do for j in 0..<2 {
            mark.x = f.rect.x + 10*f32(i) - 20
            mark.y = f.rect.y + 10*f32(j)
            rect(mark, color)
        }
    }
}

debug_terse :: proc (t: ^terse.Terse) {
    assert(t != nil)

    rect_lines(t.rect_input, 4, {255,128,64,80})
    rect_lines(t.rect, 1, {255,0,0,160})
    rect(t.rect, {255,0,0,20})

    for line in t.lines do rect_lines(line.rect, 1, {255,255,128,80})
    for word in t.words do rect_lines(word.rect, 1, {255,255,0,40})

    group_color         :: core.magenta
    group_name_color    :: core.black

    for group in t.groups do for i_rect, i in terse.group_rects(group, context.temp_allocator) {
        rect_lines(i_rect, 3, group_color)
        if i == 0 {
            font := rl.GetFontDefault()
            size := rl.MeasureTextEx(font, fmt.ctprint(group.name), 10, 2)
            rect({ i_rect.x, i_rect.y-size.y, size.x+2, size.y }, group_color)
            _debug_text(group.name, { i_rect.x+2, i_rect.y-size.y }, group_name_color)
        }
    }
}

debug_res_texture :: proc (rs: ^res.Res, name: string, pos: Vec2, scale := f32(1)) {
    assert(name in rs.textures)

    tex := rs.textures[name]
    rct := Rect { pos.x, pos.y, f32(tex.width)*scale, f32(tex.height)*scale }
    rl.DrawTextureEx(tex.texture_rl, pos, 0, scale, rl.WHITE)

    br_color := core.Color {255,255,0,255}
    label_color := core.Color {0,0,0,255}
    label := fmt.tprintf("%s: %ix%i // mipmaps: %i", name, tex.width, tex.height, tex.mipmaps)

    rect_lines(rct, 1, br_color)
    rect(core.rect_moved(core.rect_bar_top(rct, 14), {0,-14}), br_color)
    text(label, pos+{4,-11}, rl.GetFontDefault(), 10, 1, label_color)
}

@private
_debug_text :: proc (str: string, pos: Vec2, tint: Color) {
    font := rl.GetFontDefault()
    text(str, pos, font, 10, 1, tint)
}

@private
_debug_text_right :: proc (str: string, pos: Vec2, tint: Color) {
    font := rl.GetFontDefault()
    text_aligned(str, pos, {1,0}, font, 10, 1, tint)
}

@private
_debug_frame_color :: proc (f: ^ui.Frame) -> Color {
    gray        :: Color(rl.GRAY)
    red         :: Color(rl.RED)
    yellow      :: Color(rl.YELLOW)
    light_gray  :: Color(rl.LIGHTGRAY)
    return f.parent == nil ? gray : f.captured ? red : f.entered ? yellow : light_gray
}

@private
_debug_anchor_point_pos :: proc (point: ui.Anchor_Point, using rect: Rect) -> Vec2 {
    #partial switch point {
    case .mouse         : return rl.GetMousePosition()
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
