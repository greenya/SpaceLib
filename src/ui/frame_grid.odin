package spacelib_ui

import "core:math"
import "core:slice"
import "../core"

Grid :: struct {
    dir                 : Grid_Direction,   // Layout direction of the children. A pair of primary and secondary directions. Grid grows in the secondary direction.
    size                : Vec2,             // Size of each child.
    wrap                : int,              // Amount of children per primary direction. If set, `size` is ignored.
    wrap_aspect_ratio   : f32,              // Aspect ratio of a child. Used only with `wrap>0`. Square (`1`) is assumed when this value is not set (`0`).
    gap                 : Vec2,             // Spacing between adjacent children.
    pad                 : Vec2,             // Padding around the outermost children.
    auto_size           : bool,             // The grid frame will update its `size` after arranging its children.
}

Grid_Direction :: enum {
    right_down,
    // TODO: support other Grid directions
    // down_right,
    // left_down,
    // down_left,
    // right_up,
    // up_right,
    // left_up,
    // up_left,
}

layout_grid :: #force_inline proc (f: ^Frame) -> ^Grid {
    #partial switch &l in f.layout {
    case Grid: return &l
    }
    panic("Layout is not Grid")
}

@private
update_rect_for_children_of_grid :: proc (f: ^Frame) {
    grid := layout_grid(f)

    wrap: int
    rect: Rect

    if grid.wrap > 0 {
        wrap = grid.wrap
        aspect_ratio := grid.wrap_aspect_ratio > 0 ? grid.wrap_aspect_ratio : 1

        switch grid.dir {
        case .right_down:
            rect.w = (f.rect.w - 2*grid.pad.x - f32(wrap-1)*grid.gap.x) / f32(wrap)
            rect.h = rect.w / aspect_ratio
        }
    } else {
        assert(grid.size.x > 0 && grid.size.y > 0)
        rect.w = grid.size.x
        rect.h = grid.size.y

        switch grid.dir {
        case .right_down:
            w := f.rect.w - 2*grid.pad.x
            wrap = int(math.floor(w+grid.gap.x) / (rect.w+grid.gap.x))
        }
    }

    if wrap < 1 do wrap = 1

    vis_children := get_layout_visible_children(f, context.temp_allocator)

    for child, i in vis_children {
        i_div, i_mod := math.divmod(i, wrap)

        switch grid.dir {
        case .right_down:
            rect.x = f.rect.x+grid.pad.x + f32(i_mod)*rect.w + f32(i_mod)*grid.gap.x
            rect.y = f.rect.y+grid.pad.y + f32(i_div)*rect.h + f32(i_div)*grid.gap.y
        }

        child.rect = core.rect_moved(rect, child.offset)
        child.rect_dirty = false
    }

    if grid.auto_size {
        if len(vis_children) > 0 {
            fc := vis_children[0]
            lc := slice.last(vis_children[:])

            switch grid.dir {
            case .right_down:
                f.size.y = lc.rect.y+lc.rect.h - fc.rect.y + 2*grid.pad.y
            }
        } else {
            if is_layout_dir_vertical(f)    do f.size.y = 0
            else                            do f.size.x = 0
        }
    }
}
