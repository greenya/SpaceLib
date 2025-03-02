package spacelib

import rl "vendor:raylib"

Frame :: struct {
    parent          : ^Frame,
    children        : [dynamic] ^Frame,
    is_shown        : bool,
    size            : Vec2,
    anchors         : [2] Anchor,
    abs_rect_enabled: bool,
    abs_rect        : Rect,
    var             : union { Text /*, Texture, Button */ }
}

Anchor :: struct {
    point       : Anchor_Point,
    rel_point   : Anchor_Point,
    rel_frame   : ^Frame,
    offset      : Vec2,
}

Anchor_Point :: enum {
    none,
    top_left,
    top,
    top_right,
    left,
    center,
    right,
    bottom_left,
    bottom,
    bottom_right,
}

add_frame :: proc (parent: ^Frame = nil, is_shown := true, size := Vec2 {}) -> ^Frame {
    frame := new(Frame)
    frame^ = { parent=parent, is_shown=is_shown, size=size }
    if parent != nil do append(&parent.children, frame)
    return frame
}

set_parent :: proc (f: ^Frame, parent: ^Frame) {
    f.parent = parent
}

set_shown :: proc (f: ^Frame, is_shown := true) {
    f.is_shown = is_shown
}

set_size :: proc (f: ^Frame, size: Vec2) {
    f.size = size
}

set_abs_rect :: proc (f: ^Frame, rect := Rect {}, disable := false) {
    if disable {
        f.abs_rect_enabled = false
    } else {
        f.abs_rect_enabled = true
        f.abs_rect = rect
    }
}

set_anchor :: proc (f: ^Frame, point: Anchor_Point, rel_point := Anchor_Point.none, rel_frame: ^Frame = nil, offset := Vec2 {}) {
    rel_point := rel_point
    if rel_point == .none do rel_point = point

    for &a in f.anchors {
        if a.point == .none {
            a.point = point
            a.rel_point = rel_point
            a.rel_frame = rel_frame
            a.offset = offset
            return
        }
    }

    panic("Anchor count overflow")
}

clear_anchors :: proc (f: ^Frame) {
    for &a in f.anchors do a.point = .none
}

get_rect :: proc (f: ^Frame) -> Rect {
    if f.abs_rect_enabled do return f.abs_rect

    result_dir := Rect_Dir { r=f.size.x, b=f.size.y }
    result_pin := Rect_Pin {}

    for anchor in f.anchors {
        if anchor.point == .none do break

        rel := get_rect(anchor.rel_frame != nil ? anchor.rel_frame : f.parent)
        dir := result_dir
        dir_w, dir_h := dir.r-dir.l, dir.b-dir.t
        pin_anchors := Rect_Pin {}

        #partial switch anchor.point {
        case .top_left:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.t=rel.y;
            case .top           : dir.l=rel.x+rel.width/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.width; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.height/2
            case .center        : dir.l=rel.x+rel.width/2; dir.t=rel.y+rel.height/2
            case .right         : dir.l=rel.x+rel.width; dir.t=rel.y+rel.height/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.height
            case .bottom        : dir.l=rel.x+rel.width/2; dir.t=rel.y+rel.height
            case .bottom_right  : dir.l=rel.x+rel.width; dir.t=rel.y+rel.height
            }
            dir.r = dir.l + dir_w
            dir.b = dir.t + dir_h
            pin_anchors.t = true
            pin_anchors.l = true

        case .top:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.t=rel.y;
            case .top           : dir.l=rel.x+rel.width/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.width; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.height/2
            case .center        : dir.l=rel.x+rel.width/2; dir.t=rel.y+rel.height/2
            case .right         : dir.l=rel.x+rel.width; dir.t=rel.y+rel.height/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.height
            case .bottom        : dir.l=rel.x+rel.width/2; dir.t=rel.y+rel.height
            case .bottom_right  : dir.l=rel.x+rel.width; dir.t=rel.y+rel.height
            }
            dir.l -= dir_w/2
            dir.r = dir.l + dir_w
            dir.b = dir.t + dir_h
            pin_anchors.t = true

        case .top_right:
            #partial switch anchor.rel_point {
            case .top_left      : dir.r=rel.x; dir.t=rel.y;
            case .top           : dir.r=rel.x+rel.width/2; dir.t=rel.y
            case .top_right     : dir.r=rel.x+rel.width; dir.t=rel.y
            case .left          : dir.r=rel.x; dir.t=rel.y+rel.height/2
            case .center        : dir.r=rel.x+rel.width/2; dir.t=rel.y+rel.height/2
            case .right         : dir.r=rel.x+rel.width; dir.t=rel.y+rel.height/2
            case .bottom_left   : dir.r=rel.x; dir.t=rel.y+rel.height
            case .bottom        : dir.r=rel.x+rel.width/2; dir.t=rel.y+rel.height
            case .bottom_right  : dir.r=rel.x+rel.width; dir.t=rel.y+rel.height
            }
            dir.l = dir.r - dir_w
            dir.b = dir.t + dir_h
            pin_anchors.t = true
            pin_anchors.r = true

        case .left:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.t=rel.y;
            case .top           : dir.l=rel.x+rel.width/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.width; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.height/2
            case .center        : dir.l=rel.x+rel.width/2; dir.t=rel.y+rel.height/2
            case .right         : dir.l=rel.x+rel.width; dir.t=rel.y+rel.height/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.height
            case .bottom        : dir.l=rel.x+rel.width/2; dir.t=rel.y+rel.height
            case .bottom_right  : dir.l=rel.x+rel.width; dir.t=rel.y+rel.height
            }
            dir.r = dir.l + dir_w
            dir.t -= dir_h/2
            dir.b = dir.t + dir_h
            pin_anchors.l = true

        case .center:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.t=rel.y;
            case .top           : dir.l=rel.x+rel.width/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.width; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.height/2
            case .center        : dir.l=rel.x+rel.width/2; dir.t=rel.y+rel.height/2
            case .right         : dir.l=rel.x+rel.width; dir.t=rel.y+rel.height/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.height
            case .bottom        : dir.l=rel.x+rel.width/2; dir.t=rel.y+rel.height
            case .bottom_right  : dir.l=rel.x+rel.width; dir.t=rel.y+rel.height
            }
            dir.l -= dir_w/2
            dir.r = dir.l + dir_w
            dir.t -= dir_h/2
            dir.b = dir.t + dir_h

        case .right:
            #partial switch anchor.rel_point {
            case .top_left      : dir.r=rel.x; dir.t=rel.y;
            case .top           : dir.r=rel.x+rel.width/2; dir.t=rel.y
            case .top_right     : dir.r=rel.x+rel.width; dir.t=rel.y
            case .left          : dir.r=rel.x; dir.t=rel.y+rel.height/2
            case .center        : dir.r=rel.x+rel.width/2; dir.t=rel.y+rel.height/2
            case .right         : dir.r=rel.x+rel.width; dir.t=rel.y+rel.height/2
            case .bottom_left   : dir.r=rel.x; dir.t=rel.y+rel.height
            case .bottom        : dir.r=rel.x+rel.width/2; dir.t=rel.y+rel.height
            case .bottom_right  : dir.r=rel.x+rel.width; dir.t=rel.y+rel.height
            }
            dir.l = dir.r - dir_w
            dir.t -= dir_h/2
            dir.b = dir.t + dir_h
            pin_anchors.r = true

        case .bottom_left:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.b=rel.y;
            case .top           : dir.l=rel.x+rel.width/2; dir.b=rel.y
            case .top_right     : dir.l=rel.x+rel.width; dir.b=rel.y
            case .left          : dir.l=rel.x; dir.b=rel.y+rel.height/2
            case .center        : dir.l=rel.x+rel.width/2; dir.b=rel.y+rel.height/2
            case .right         : dir.l=rel.x+rel.width; dir.b=rel.y+rel.height/2
            case .bottom_left   : dir.l=rel.x; dir.b=rel.y+rel.height
            case .bottom        : dir.l=rel.x+rel.width/2; dir.b=rel.y+rel.height
            case .bottom_right  : dir.l=rel.x+rel.width; dir.b=rel.y+rel.height
            }
            dir.r = dir.l + dir_w
            dir.t = dir.b - dir_h
            pin_anchors.b = true
            pin_anchors.l = true

        case .bottom:
            #partial switch anchor.rel_point {
            case .top_left      : dir.l=rel.x; dir.b=rel.y;
            case .top           : dir.l=rel.x+rel.width/2; dir.b=rel.y
            case .top_right     : dir.l=rel.x+rel.width; dir.b=rel.y
            case .left          : dir.l=rel.x; dir.b=rel.y+rel.height/2
            case .center        : dir.l=rel.x+rel.width/2; dir.b=rel.y+rel.height/2
            case .right         : dir.l=rel.x+rel.width; dir.b=rel.y+rel.height/2
            case .bottom_left   : dir.l=rel.x; dir.b=rel.y+rel.height
            case .bottom        : dir.l=rel.x+rel.width/2; dir.b=rel.y+rel.height
            case .bottom_right  : dir.l=rel.x+rel.width; dir.b=rel.y+rel.height
            }
            dir.l -= dir_w/2
            dir.r = dir.l + dir_w
            dir.t = dir.b - dir_h
            pin_anchors.b = true

        case .bottom_right:
            #partial switch anchor.rel_point {
            case .top_left      : dir.r=rel.x; dir.b=rel.y;
            case .top           : dir.r=rel.x+rel.width/2; dir.b=rel.y
            case .top_right     : dir.r=rel.x+rel.width; dir.b=rel.y
            case .left          : dir.r=rel.x; dir.b=rel.y+rel.height/2
            case .center        : dir.r=rel.x+rel.width/2; dir.b=rel.y+rel.height/2
            case .right         : dir.r=rel.x+rel.width; dir.b=rel.y+rel.height/2
            case .bottom_left   : dir.r=rel.x; dir.b=rel.y+rel.height
            case .bottom        : dir.r=rel.x+rel.width/2; dir.b=rel.y+rel.height
            case .bottom_right  : dir.r=rel.x+rel.width; dir.b=rel.y+rel.height
            }
            dir.l = dir.r - dir_w
            dir.t = dir.b - dir_h
            pin_anchors.b = true
            pin_anchors.r = true
        }

        dir.l += anchor.offset.x
        dir.r += anchor.offset.x
        dir.t += anchor.offset.y
        dir.b += anchor.offset.y
        transform_rect_dir(&result_dir, &result_pin, dir, pin_anchors)
    }

    return {
        x       = result_dir.l,
        y       = result_dir.t,
        width   = result_dir.r - result_dir.l,
        height  = result_dir.b - result_dir.t,
    }
}

draw_frame :: proc (f: ^Frame, ui: ^UI) {
    if !f.is_shown do return
    if ui.is_debug do draw_frame_debug(f)

    switch v in f.var {
    case Text:
        draw_text(f)
    }

    for child in f.children do draw_frame(child, ui)
}

draw_frame_debug :: proc (f: ^Frame) {
    rect := get_rect(f)
    if rect.width > 0 {
        rl.DrawRectangleRec(rect, { 255, 255, 255, 40 })
        rl.DrawRectangleLinesEx(rect, 1, { 255, 255, 255, 80 })
    } else {
        rl.DrawLineEx({ rect.x - 6, rect.y }, { rect.x + 5, rect.y }, 3, { 255, 255, 255, 160 })
        rl.DrawLineEx({ rect.x, rect.y - 6 }, { rect.x, rect.y + 5 }, 3, { 255, 255, 255, 160 })
    }
}

destroy_frame :: proc (f: ^Frame) {
    for child in f.children do destroy_frame(child)
    delete(f.children)
    free(f)
}

@(private="file") Rect_Dir :: struct { l, t, r, b: f32 }
@(private="file") Rect_Pin :: struct { l, t, r, b: bool }

@(private="file")
transform_rect_dir :: proc (dir: ^Rect_Dir, pin: ^Rect_Pin, dir_next: Rect_Dir, pin_anchors: Rect_Pin) {
    if !pin.l do dir.l = dir_next.l
    if !pin.t do dir.t = dir_next.t
    if !pin.r do dir.r = dir_next.r
    if !pin.b do dir.b = dir_next.b

    if pin_anchors.l do pin.l = true
    if pin_anchors.t do pin.t = true
    if pin_anchors.r do pin.r = true
    if pin_anchors.b do pin.b = true
}
