package spacelib_ui

import "core:math"
import "core:slice"
import "../core"

@private
update_rect_for_children_of_grid :: proc (f: ^Frame) {
    grid := layout_grid(f)
    assert(grid.wrap > 0)
    assert(grid.aspect_ratio > 0)

    rect: Rect

    switch grid.dir {
    case .right_down:
        rect.w = (f.rect.w - 2*grid.pad.x - f32(grid.wrap-1)*grid.gap.x) / f32(grid.wrap)
        rect.h = rect.w / grid.aspect_ratio
    }

    vis_children := get_layout_visible_children(f, context.temp_allocator)

    for child, i in vis_children {
        i_div, i_mod := math.divmod(i, grid.wrap)

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
