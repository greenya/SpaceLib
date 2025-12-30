package spacelib_ui

import "core:slice"
import "../core"

// Arranges `children` in the single row or column.
// Child frames can have different sizes.
// Supports scroll.
Flow :: struct {
    // Layout direction of the children.
    // Direction with `_center` suffix will align items to the center of the direction.
    dir: Flow_Direction,

    // Default size for a child. Width and height are processed separately.
    // Width/height is considered "not set" if it is zero.
    // The priority goes: `child.size > flow.size > parent.size`.
    // For example: child.size={100,0}, flow.size={0,50} -> resulting child size will be {100,50}.
    //
    // Flow supports child's `size_aspect` and `size_min`.
    // For example, you can have a flow with vertical direction and a child with only size_aspect=5
    // and size_min={0,100}, this will make it to take whole width of the flow, height will be width/5
    // as long as the value is greater than 100.
    //
    // Flow supports child's `size_ratio`, Width and height are processed separately.
    // For example: size_ratio={.5,0} -> resulting child width will be 50% of the parent width,
    // and 100% of the parent height (in case nothing else is set).
    size: Vec2,

    // Children alignment in orthogonal direction to the `dir`.
    align: Flow_Alignment,

    // Scroll state. Set `scroll.step` to enable scroll processing.
    // `scroll.offset*` values will be updated automatically.
    // Setting `auto_size` to same direction will effectively disable scrolling conditions, unless you
    // use `size_max`, which will enable scroll at some maximum point.
    scroll: Layout_Scroll,

    // Spacing between adjacent children.
    gap: f32,

    // Padding around the outermost children in order: `[0] left`, `[1] right`, `[2] top`, `[3] bottom`.
    pad: [4] f32,

    // The flow frame will update its `size` after arranging its children.
    // Width and height can be marked for auto sizing separately.
    auto_size: bit_set [Layout_Auto_Size],
}

Flow_Direction :: enum {
    left,
    right,
    right_center,
    up,
    down,
    down_center,
}

Flow_Alignment :: enum {
    start,
    center,
    end,
}

layout_flow :: #force_inline proc (f: ^Frame) -> ^Flow {
    #partial switch &l in f.layout {
    case Flow: return &l
    }
    return nil
}

@private
update_rect_for_children_of_flow :: proc (f: ^Frame) {
    flow := layout_flow(f)
    assert(flow != nil)

    prev_rect: Rect
    has_prev_rect: bool

    vis_children := layout_visible_children(f, context.temp_allocator)
    is_dir_vertical := is_layout_dir_vertical(f)

    f_rect_w_avail := f.rect.w - flow.pad[L] - flow.pad[R]
    f_rect_h_avail := f.rect.h - flow.pad[T] - flow.pad[B]

    if len(vis_children) > 1 {
        if is_dir_vertical  do f_rect_h_avail -= flow.gap * f32(len(vis_children)-1)
        else                do f_rect_w_avail -= flow.gap * f32(len(vis_children)-1)
    }

    for child in vis_children {
        rect := Rect {
            x = 0,
            y = 0,
            w = child.size.x != 0\
                ? child.size.x\
                : flow.size.x != 0\
                    ? flow.size.x\
                    : f_rect_w_avail,
            h = child.size.y != 0\
                ? child.size.y\
                : flow.size.y != 0\
                    ? flow.size.y\
                    : f_rect_h_avail,
        }

        if rect.w < 0 do rect.w = 0
        if rect.h < 0 do rect.h = 0

        if child.size_aspect != 0 {
            if is_dir_vertical  do rect.h = rect.w/child.size_aspect
            else                do rect.w = rect.h*child.size_aspect
        }

        if child.size_ratio.x > 0 do rect.w *= child.size_ratio.x
        if child.size_ratio.y > 0 do rect.h *= child.size_ratio.y

        if child.size_min.x > 0 do rect.w = max(rect.w, child.size_min.x)
        if child.size_min.y > 0 do rect.h = max(rect.h, child.size_min.y)

        switch flow.dir {
        case .left:
            rect.x = has_prev_rect ? prev_rect.x-rect.w-flow.gap : f.rect.x+f.rect.w-rect.w-flow.pad[R]
            rect.y = f.rect.y + flow.pad[T]
        case .right, .right_center:
            rect.x = has_prev_rect ? prev_rect.x+prev_rect.w+flow.gap : f.rect.x+flow.pad[L]
            rect.y = f.rect.y + flow.pad[T]
        case .up:
            rect.x = f.rect.x + flow.pad[L]
            rect.y = has_prev_rect ? prev_rect.y-rect.h-flow.gap : f.rect.y+f.rect.h-rect.h-flow.pad[B]
        case .down, .down_center:
            rect.x = f.rect.x + flow.pad[L]
            rect.y = has_prev_rect ? prev_rect.y+prev_rect.h+flow.gap : f.rect.y+flow.pad[T]
        }

        prev_rect = rect
        has_prev_rect = true

        switch flow.dir {
        case .left, .right, .right_center:
            switch flow.align {
            case .start : // already aligned
            case .center: rect.y += (f.rect.h-rect.h)/2 - (flow.pad[T]+flow.pad[B])/2
            case .end   : rect.y +=  f.rect.h-rect.h    - (flow.pad[T]+flow.pad[B])
            }
        case .up, .down, .down_center:
            switch flow.align {
            case .start : // already aligned
            case .center: rect.x += (f.rect.w-rect.w)/2 - (flow.pad[L]+flow.pad[R])/2
            case .end   : rect.x +=  f.rect.w-rect.w    - (flow.pad[L]+flow.pad[R])
            }
        }

        child.rect = core.rect_moved(rect, child.offset)
        child.rect_status = .ready
    }

    if len(vis_children) > 0 {
        fc := vis_children[0]
        lc := slice.last(vis_children[:])

        #partial switch flow.dir {
        case .right_center:
            fc_x1               := fc.rect.x
            lc_x2               := lc.rect.x + lc.rect.w
            children_center_x   := (fc_x1 + lc_x2) / 2
            frame_center_x      := f.rect.x + f.rect.w/2
            dx                  := frame_center_x - children_center_x
            for child in vis_children do child.rect.x += dx
        case .down_center:
            fc_y1               := fc.rect.y
            lc_y2               := lc.rect.y + lc.rect.h
            children_center_y   := (fc_y1 + lc_y2) / 2
            frame_center_y      := f.rect.y + f.rect.h/2
            dy                  := frame_center_y - children_center_y
            for child in vis_children do child.rect.y += dy
        }
    }

    full_content_size, dir_content_size, dir_rect_size := flow_content_size(f, vis_children)

    if flow.auto_size != {} {
        if .width in flow.auto_size {
            f.size.x = full_content_size.x
            if f.size_max.x > 0 && f.size.x > f.size_max.x do f.size.x = f.size_max.x
            // FIX FOR infinite grow issue: when one flow with no children is a child of another flow
            if f.size.x == 0 && len(vis_children) == 0 do f.size.x = .1
        }
        if .height in flow.auto_size {
            f.size.y = full_content_size.y
            if f.size_max.y > 0 && f.size.y > f.size_max.y do f.size.y = f.size_max.y
            // fixes same issue as above (see f.size.x logic)
            if f.size.y == 0 && len(vis_children) == 0 do f.size.y = .1
        }
    }

    scroll := layout_scroll(f)
    if scroll != nil {
        scroll.offset_min = min(0, dir_content_size[0])
        scroll.offset_max = max(0, dir_content_size[1] - dir_rect_size)

        if scroll.offset_max - scroll.offset_min < 0.001 {
            scroll.offset_min = 0
            scroll.offset_max = 0
        }

        #partial switch flow.dir {
        case .left, .up:
            scroll.offset_min = -scroll.offset_max
            scroll.offset_max = 0
        case .right_center, .down_center:
            scroll.offset_max /= 2
            scroll.offset_min = -scroll.offset_max
        }

        scroll.offset = clamp(scroll.offset, scroll.offset_min, scroll.offset_max)

        if is_dir_vertical  do for child in vis_children do child.rect.y -= scroll.offset
        else                do for child in vis_children do child.rect.x -= scroll.offset
    }
}

@private
flow_content_size :: proc (f: ^Frame, vis_children: [] ^Frame) -> (full_content_size: Vec2, dir_content_size: Vec2, dir_rect_size: f32) {
    flow := layout_flow(f)
    is_dir_vertical := is_layout_dir_vertical(f)
    dir_rect_size = is_dir_vertical ? f.rect.h : f.rect.w

    if len(vis_children) == 0 do return

    full_rect := vis_children[0].rect
    for child in vis_children[1:] do core.rect_grow(&full_rect, child.rect)
    full_content_size = {
        full_rect.w + flow.pad[L] + flow.pad[R],
        full_rect.h + flow.pad[T] + flow.pad[B],
    }

    fc := vis_children[0]
    lc := slice.last(vis_children[:])

    if is_layout_dir_vertical(f) {
        min_y1: f32
        max_y2: f32

        #partial switch flow.dir {
        case .up: // children grow up
            min_y1 = lc.rect.y
            max_y2 = fc.rect.y + fc.rect.h
        case .down, .down_center: // children grow down
            min_y1 = fc.rect.y
            max_y2 = lc.rect.y + lc.rect.h
        }

        dir_content_size[0] = min_y1 - f.rect.y - flow.pad[T]
        dir_content_size[1] = max_y2 - f.rect.y + flow.pad[B]
    } else {
        min_x1: f32
        max_x2: f32

        #partial switch flow.dir {
        case .left: // children grow left
            min_x1 = lc.rect.x
            max_x2 = fc.rect.x + fc.rect.w
        case .right, .right_center: // children grow right
            min_x1 = fc.rect.x
            max_x2 = lc.rect.x + lc.rect.w
        }

        dir_content_size[0] = min_x1 - f.rect.x - flow.pad[L]
        dir_content_size[1] = max_x2 - f.rect.x + flow.pad[R]
    }

    dir_content_size = { 0, dir_content_size[1]-dir_content_size[0] }

    return
}
