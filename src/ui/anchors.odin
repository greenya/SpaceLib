package spacelib_ui

Anchor :: struct {
    // Point of this frame. If not set, `.top_left` will be used.
    point: Anchor_Point,

    // Point of the `rel_frame`. If not set, same value as `point` will be used.
    rel_point: Anchor_Point,

    // The relative frame. If not set, `parent` frame will be used.
    rel_frame: ^Frame,

    // Offset for the resulting position.
    offset: Vec2,
}

Anchor_Point :: enum {
    none,
    mouse,
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

set_anchors :: proc (f: ^Frame, anchors: ..Anchor) {
    delete(f.anchors)
    f.anchors = make([] Anchor, len(anchors))
    for a, i in anchors {
        init := a
        assert(init.point != .mouse, "Mouse anchor can only be used as rel_point.")
        if init.point == .none      do init.point = .top_left
        if init.rel_point == .none  do init.rel_point = init.point
        f.anchors[i] = init
    }
}

clear_anchors :: proc (f: ^Frame) {
    delete(f.anchors)
    f.anchors = nil
}

@private
update_rect_with_anchors :: proc (f: ^Frame) {
    assert(f.rect_status != .ready)
    assert(f.rect_status != .updating_now, "Anchoring loop detected")
    f.rect_status = .updating_now

    f_size := f.size

    size_aspect_applied: bool
    if f.size_aspect != 0 {
        if      f_size.x>1 && f_size.y==0 { f_size.y=f_size.x/f.size_aspect; size_aspect_applied=true }
        else if f_size.y>1 && f_size.x==0 { f_size.x=f_size.y*f.size_aspect; size_aspect_applied=true }
    }

    result_dir := Rect_Dir { r=f_size.x, b=f_size.y }
    result_pin: Rect_Pin

    for anchor in f.anchors {
        assert(anchor.point != .none)
        assert(anchor.rel_point != .none)

        rel_frame := anchor.rel_frame != nil ? anchor.rel_frame : f.parent
        if rel_frame.rect_status != .ready do update_rect(rel_frame)

        rel := rel_frame.rect
        dir := result_dir
        dir_w, dir_h := dir.r-dir.l, dir.b-dir.t
        pin_anchors: Rect_Pin

        #partial switch anchor.point {
        case .mouse:
            panic("Mouse anchor can only be used as rel_point.")

        case .top_left:
            #partial switch anchor.rel_point {
            case .mouse         : dir.l=f.ui.mouse.pos.x; dir.t=f.ui.mouse.pos.y
            case .top_left      : dir.l=rel.x; dir.t=rel.y
            case .top           : dir.l=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.r = dir.l + dir_w
            dir.b = dir.t + dir_h
            pin_anchors.t = true
            pin_anchors.l = true

        case .top:
            #partial switch anchor.rel_point {
            case .mouse         : dir.l=f.ui.mouse.pos.x; dir.t=f.ui.mouse.pos.y
            case .top_left      : dir.l=rel.x; dir.t=rel.y
            case .top           : dir.l=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.l -= dir_w/2
            dir.r = dir.l + dir_w
            dir.b = dir.t + dir_h
            pin_anchors.t = true

        case .top_right:
            #partial switch anchor.rel_point {
            case .mouse         : dir.r=f.ui.mouse.pos.x; dir.t=f.ui.mouse.pos.y
            case .top_left      : dir.r=rel.x; dir.t=rel.y
            case .top           : dir.r=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.r=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.r=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.r=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.r=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.r=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.r=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.r=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.l = dir.r - dir_w
            dir.b = dir.t + dir_h
            pin_anchors.t = true
            pin_anchors.r = true

        case .left:
            #partial switch anchor.rel_point {
            case .mouse         : dir.l=f.ui.mouse.pos.x; dir.t=f.ui.mouse.pos.y
            case .top_left      : dir.l=rel.x; dir.t=rel.y
            case .top           : dir.l=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.r = dir.l + dir_w
            dir.t -= dir_h/2
            dir.b = dir.t + dir_h
            pin_anchors.l = true

        case .center:
            #partial switch anchor.rel_point {
            case .mouse         : dir.l=f.ui.mouse.pos.x; dir.t=f.ui.mouse.pos.y
            case .top_left      : dir.l=rel.x; dir.t=rel.y
            case .top           : dir.l=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.l=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.l -= dir_w/2
            dir.r = dir.l + dir_w
            dir.t -= dir_h/2
            dir.b = dir.t + dir_h

        case .right:
            #partial switch anchor.rel_point {
            case .mouse         : dir.r=f.ui.mouse.pos.x; dir.t=f.ui.mouse.pos.y
            case .top_left      : dir.r=rel.x; dir.t=rel.y
            case .top           : dir.r=rel.x+rel.w/2; dir.t=rel.y
            case .top_right     : dir.r=rel.x+rel.w; dir.t=rel.y
            case .left          : dir.r=rel.x; dir.t=rel.y+rel.h/2
            case .center        : dir.r=rel.x+rel.w/2; dir.t=rel.y+rel.h/2
            case .right         : dir.r=rel.x+rel.w; dir.t=rel.y+rel.h/2
            case .bottom_left   : dir.r=rel.x; dir.t=rel.y+rel.h
            case .bottom        : dir.r=rel.x+rel.w/2; dir.t=rel.y+rel.h
            case .bottom_right  : dir.r=rel.x+rel.w; dir.t=rel.y+rel.h
            }
            dir.l = dir.r - dir_w
            dir.t -= dir_h/2
            dir.b = dir.t + dir_h
            pin_anchors.r = true

        case .bottom_left:
            #partial switch anchor.rel_point {
            case .mouse         : dir.l=f.ui.mouse.pos.x; dir.b=f.ui.mouse.pos.y
            case .top_left      : dir.l=rel.x; dir.b=rel.y
            case .top           : dir.l=rel.x+rel.w/2; dir.b=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.b=rel.y
            case .left          : dir.l=rel.x; dir.b=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.b=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.b=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.b=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.b=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.b=rel.y+rel.h
            }
            dir.r = dir.l + dir_w
            dir.t = dir.b - dir_h
            pin_anchors.b = true
            pin_anchors.l = true

        case .bottom:
            #partial switch anchor.rel_point {
            case .mouse         : dir.l=f.ui.mouse.pos.x; dir.b=f.ui.mouse.pos.y
            case .top_left      : dir.l=rel.x; dir.b=rel.y
            case .top           : dir.l=rel.x+rel.w/2; dir.b=rel.y
            case .top_right     : dir.l=rel.x+rel.w; dir.b=rel.y
            case .left          : dir.l=rel.x; dir.b=rel.y+rel.h/2
            case .center        : dir.l=rel.x+rel.w/2; dir.b=rel.y+rel.h/2
            case .right         : dir.l=rel.x+rel.w; dir.b=rel.y+rel.h/2
            case .bottom_left   : dir.l=rel.x; dir.b=rel.y+rel.h
            case .bottom        : dir.l=rel.x+rel.w/2; dir.b=rel.y+rel.h
            case .bottom_right  : dir.l=rel.x+rel.w; dir.b=rel.y+rel.h
            }
            dir.l -= dir_w/2
            dir.r = dir.l + dir_w
            dir.t = dir.b - dir_h
            pin_anchors.b = true

        case .bottom_right:
            #partial switch anchor.rel_point {
            case .mouse         : dir.r=f.ui.mouse.pos.x; dir.b=f.ui.mouse.pos.y
            case .top_left      : dir.r=rel.x; dir.b=rel.y
            case .top           : dir.r=rel.x+rel.w/2; dir.b=rel.y
            case .top_right     : dir.r=rel.x+rel.w; dir.b=rel.y
            case .left          : dir.r=rel.x; dir.b=rel.y+rel.h/2
            case .center        : dir.r=rel.x+rel.w/2; dir.b=rel.y+rel.h/2
            case .right         : dir.r=rel.x+rel.w; dir.b=rel.y+rel.h/2
            case .bottom_left   : dir.r=rel.x; dir.b=rel.y+rel.h
            case .bottom        : dir.r=rel.x+rel.w/2; dir.b=rel.y+rel.h
            case .bottom_right  : dir.r=rel.x+rel.w; dir.b=rel.y+rel.h
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

    f.rect = {
        result_dir.l + f.offset.x,
        result_dir.t + f.offset.y,
        result_dir.r - result_dir.l,
        result_dir.b - result_dir.t,
    }

    // when we have anchors of two neighboring points, we cannot apply size_aspect until
    // we resolve the rect, which will include the distance we use; for example, when
    // top_left+top_right points anchored, we need width first to be able calculate height;
    // that is the reason why late size_aspect application exists (code below).

    if !size_aspect_applied && f.size_aspect != 0 {
        if      f.rect.w>1 && f.rect.h==0 do f.rect.h = f.rect.w/f.size_aspect
        else if f.rect.h>1 && f.rect.w==0 do f.rect.w = f.rect.h*f.size_aspect
    }

    f.rect_status = .ready
}

@private Rect_Dir :: struct { l, t, r, b: f32 }
@private Rect_Pin :: struct { l, t, r, b: bool }

@private
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
