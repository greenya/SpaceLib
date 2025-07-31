package spacelib_ui

import "core:math"
import "core:slice"
import "../core"

// Arranges `children` in a grid where each cell has the same size.
// The grid fills in the primary direction, with up to `wrap` children per row or column.
// Additional children cause the grid to grow in the secondary direction.
// Scroll is not directly supported, but you can place `Grid` inside `Flow` with a scroll.
Grid :: struct {
    // Placement direction of the children. A pair of primary and secondary directions.
    // Grid grows in primary direction up to `wrap` items, and indefinitely in the secondary direction.
    dir: Grid_Direction,

    // Size of each child.
    // If not set, it will be decided from `wrap`, `ratio` and width of the frame.
    // Can be partially set, e.g. width or height only.
    size: Vec2,

    // Amount of children per primary direction.
    // If not set, it will be decided from `size` (must be set) and width of the frame.
    wrap: int,

    // Aspect ratio of a child.
    // Used only when width or height is left for calculation.
    // For example: size={100,0}, ratio=.7; or wrap=5, ratio=1.2.
    // Square (`1`) is assumed when this value is not set (`0`).
    ratio: f32,

    // Spacing between adjacent children.
    gap: Vec2,

    // Padding around the outermost children in order: `[0] left`, `[1] right`, `[2] top`, `[3] bottom`.
    pad: [4] f32,

    // The grid frame will update its `size` after arranging its children.
    // Width and height can be marked for auto sizing separately.
    auto_size: bit_set [Grid_Auto_Size],
}

Grid_Direction :: enum {
    right_down,
    left_down,
    // right_up,
    // left_up,
    // down_right,
    // down_left,
    // up_right,
    // up_left,
}

Grid_Auto_Size :: enum {
    width,
    height,
}

layout_grid :: #force_inline proc (f: ^Frame) -> ^Grid {
    #partial switch &l in f.layout {
    case Grid: return &l
    }
    return nil
}

@private
update_rect_for_children_of_grid :: proc (f: ^Frame) {
    grid := layout_grid(f)
    assert(grid != nil)

    wrap := grid.wrap
    size := grid.size

    if wrap > 0 {
        if size == {} {
            ratio := grid.ratio > 0 ? grid.ratio : 1
            size.x = (f.rect.w - grid.pad[L] - grid.pad[R] - f32(wrap-1)*grid.gap.x) / f32(wrap)
            size.y = size.x / ratio
        }
    } else if wrap == 0 {
        ratio := grid.ratio > 0 ? grid.ratio : 1
        switch {
        case size.x  > 0 && size.y == 0: size.y = size.x / ratio
        case size.x == 0 && size.y  > 0: size.x = size.y * ratio
        case size.x == 0 && size.y == 0: panic("Grid.size (width and/or height) must be set when Grid.wrap==0")
        }
        if is_layout_dir_vertical(f) {
            w := f.rect.w - grid.pad[L] - grid.pad[R]
            wrap = int(math.floor(w+grid.gap.x) / (size.x+grid.gap.x))
        }
    } else {
        panic("Grid.wrap cannot be negative.")
    }

    if wrap < 1 do wrap = 1

    rect := Rect {0,0,size.x,size.y}
    f_rect_x2 := f.rect.x+f.rect.w
    // f_rect_y2 := f.rect.y+f.rect.h

    vis_children := layout_visible_children(f, context.temp_allocator)

    for child, i in vis_children {
        i_div, i_mod := math.divmod(i, wrap)

        switch grid.dir {
        case .right_down:
            rect.x = f.rect.x+grid.pad[L] + f32(i_mod)*rect.w + f32(i_mod)*grid.gap.x
        case .left_down:
            rect.x = f_rect_x2-grid.pad[R] - f32(i_mod+1)*rect.w - f32(i_mod)*grid.gap.x
        }

        switch grid.dir {
        case .right_down, .left_down:
            rect.y = f.rect.y+grid.pad[T] + f32(i_div)*rect.h + f32(i_div)*grid.gap.y
        }

        child.rect = core.rect_moved(rect, child.offset)
        child.rect_status = .ready
    }

    if grid.auto_size != {} {
        if len(vis_children) > 0 {
            fc := vis_children[0]
            lc := slice.last(vis_children[:])
            lc_div0 := vis_children[min( wrap, len(vis_children) )-1]

            switch grid.dir {
            case .right_down:
                if .width in grid.auto_size do f.size.x = lc_div0.rect.x+lc_div0.rect.w - fc.rect.x + grid.pad[L]+grid.pad[R]
            case .left_down:
                if .width in grid.auto_size do f.size.x = fc.rect.x+fc.rect.w - lc_div0.rect.x + grid.pad[L]+grid.pad[R]
            }

            switch grid.dir {
            case .right_down, .left_down:
                if .height in grid.auto_size do f.size.y = lc.rect.y+lc.rect.h - fc.rect.y + grid.pad[T]+grid.pad[B]
            }
        } else {
            if .width in grid.auto_size     do f.size.x = 0
            if .height in grid.auto_size    do f.size.y = 0
        }
    }
}
