package spacelib_ui

import "core:slice"
import "../core"

Flow :: struct {
    dir         : Flow_Direction,
    align       : Flow_Alignment,
    scroll      : Layout_Scroll,
    size        : Vec2,
    gap         : f32,
    pad         : Vec2,
    auto_size   : Flow_Auto_Size,
}

Flow_Direction :: enum {
    left,
    left_and_right,
    right,
    up,
    up_and_down,
    down,
}

Flow_Alignment :: enum {
    start,
    center,
    end,
}

Flow_Auto_Size :: enum {
    none,
    full,
    dir,
}

layout_flow :: #force_inline proc (f: ^Frame) -> ^Flow {
    #partial switch &l in f.layout {
    case Flow: return &l
    }
    panic("Layout is not Flow")
}

@private
update_rect_for_children_of_flow :: proc (f: ^Frame) {
    prev_rect: Rect
    has_prev_rect: bool

    vis_children := get_layout_visible_children(f, context.temp_allocator)
    is_dir_vertical := is_layout_dir_vertical(f)
    flow := layout_flow(f)

    for child in vis_children {
        rect := Rect {
            x = 0,
            y = 0,
            w = child.size.x != 0\
                ? child.size.x\
                : flow.size.x != 0\
                    ? flow.size.x\
                    : f.rect.w - 2*flow.pad.x,
            h = child.size.y != 0\
                ? child.size.y\
                : flow.size.y != 0\
                    ? flow.size.y\
                    : f.rect.h - 2*flow.pad.y,
        }

        if rect.w < 0 do rect.w = 0
        if rect.h < 0 do rect.h = 0

        if child.size_aspect != 0 {
            if is_dir_vertical  do rect.h = rect.w/child.size_aspect
            else                do rect.w = rect.h*child.size_aspect
        }

        switch flow.dir {
        case .left:
            rect.x = has_prev_rect ? prev_rect.x-rect.w-flow.gap : f.rect.x+f.rect.w-rect.w-flow.pad.x
            rect.y = f.rect.y + flow.pad.y
        case .left_and_right, .right:
            rect.x = has_prev_rect ? prev_rect.x+prev_rect.w+flow.gap : f.rect.x+flow.pad.x
            rect.y = f.rect.y + flow.pad.y
        case .up:
            rect.x = f.rect.x + flow.pad.x
            rect.y = has_prev_rect ? prev_rect.y-rect.h-flow.gap : f.rect.y+f.rect.h-rect.h-flow.pad.y
        case .up_and_down, .down:
            rect.x = f.rect.x + flow.pad.x
            rect.y = has_prev_rect ? prev_rect.y+prev_rect.h+flow.gap : f.rect.y+flow.pad.y
        }

        prev_rect = rect
        has_prev_rect = true

        switch flow.dir {
        case .left, .left_and_right, .right:
            switch flow.align {
            case .start : // already aligned
            case .center: rect.y += (f.rect.h-rect.h)/2   - flow.pad.y
            case .end   : rect.y +=  f.rect.h-rect.h    - 2*flow.pad.y
            }
        case .up, .up_and_down, .down:
            switch flow.align {
            case .start : // already aligned
            case .center: rect.x += (f.rect.w-rect.w)/2   - flow.pad.x
            case .end   : rect.x +=  f.rect.w-rect.w    - 2*flow.pad.x
            }
        }

        child.rect = core.rect_moved(rect, child.offset)
        child.rect_dirty = false
    }

    if len(vis_children) > 0 {
        fc := vis_children[0]
        lc := slice.last(vis_children[:])

        #partial switch flow.dir {
        case .left_and_right:
            fc_x1               := fc.rect.x
            lc_x2               := lc.rect.x + lc.rect.w
            children_center_x   := (fc_x1 + lc_x2) / 2
            frame_center_x      := f.rect.x + f.rect.w/2
            dx                  := frame_center_x - children_center_x
            for child in vis_children do child.rect.x += dx
        case .up_and_down:
            fc_y1               := fc.rect.y
            lc_y2               := lc.rect.y + lc.rect.h
            children_center_y   := (fc_y1 + lc_y2) / 2
            frame_center_y      := f.rect.y + f.rect.h/2
            dy                  := frame_center_y - children_center_y
            for child in vis_children do child.rect.y += dy
        }
    }

    full_content_size, dir_content_size, dir_rect_size := get_flow_content_size(f, vis_children)

    if flow.auto_size == .full {
        f.size = full_content_size
    } else if flow.auto_size == .dir {
        if is_dir_vertical  do f.size.y = dir_content_size[1]
        else                do f.size.x = dir_content_size[1]
    } else {
        scroll := layout_scroll(f)
        if scroll != nil {
            scroll.offset_min = min(0, dir_content_size[0])
            scroll.offset_max = max(0, dir_content_size[1] - dir_rect_size)

            #partial switch flow.dir {
            case .left, .up:
                scroll.offset_min = -scroll.offset_max
                scroll.offset_max = 0
            case .left_and_right, .up_and_down:
                scroll.offset_max /= 2
                scroll.offset_min = -scroll.offset_max
            }

            scroll.offset = clamp(scroll.offset, scroll.offset_min, scroll.offset_max)

            if is_dir_vertical  do for child in vis_children do child.rect.y -= scroll.offset
            else                do for child in vis_children do child.rect.x -= scroll.offset
        }
    }
}

@private
get_flow_content_size :: proc (f: ^Frame, vis_children: [] ^Frame) -> (full_content_size: Vec2, dir_content_size: Vec2, dir_rect_size: f32) {
    flow := layout_flow(f)
    is_dir_vertical := is_layout_dir_vertical(f)
    dir_rect_size = is_dir_vertical ? f.rect.h : f.rect.w

    if len(vis_children) == 0 do return

    full_rect := vis_children[0].rect
    for child in vis_children[1:] do core.rect_add_rect(&full_rect, child.rect)
    full_content_size = 2*flow.pad + { full_rect.w, full_rect.h }

    fc := vis_children[0]
    lc := slice.last(vis_children[:])

    if is_layout_dir_vertical(f) {
        min_y1: f32
        max_y2: f32

        #partial switch flow.dir {
        case .up: // children grow up
            min_y1 = lc.rect.y
            max_y2 = fc.rect.y + fc.rect.h
        case .down, .up_and_down: // children grow down
            min_y1 = fc.rect.y
            max_y2 = lc.rect.y + lc.rect.h
        }

        dir_content_size[0] = min_y1 - f.rect.y - flow.pad.y
        dir_content_size[1] = max_y2 - f.rect.y + flow.pad.y
    } else {
        min_x1: f32
        max_x2: f32

        #partial switch flow.dir {
        case .left: // children grow left
            min_x1 = lc.rect.x
            max_x2 = fc.rect.x + fc.rect.w
        case .right, .left_and_right: // children grow right
            min_x1 = fc.rect.x
            max_x2 = lc.rect.x + lc.rect.w
        }

        dir_content_size[0] = min_x1 - f.rect.x - flow.pad.x
        dir_content_size[1] = max_x2 - f.rect.x + flow.pad.x
    }

    dir_content_size = { 0, dir_content_size[1]-dir_content_size[0] }

    return
}
