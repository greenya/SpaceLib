#+private
package interface

// import "core:fmt"
import "core:slice"

import "spacelib:ui"

add_dev_split_mode_layer :: proc () {
    assert(dev.layer != nil, "dev layer must be added at this point")

    dev.layer_split = ui.add_frame(ui_.root, {
        name    = "dev_split_mode",
        flags   = {.hidden,.pass_self},
        order   = dev.layer.order,
    }, { point=.top_left }, { point=.bottom_right })

    aside := ui.add_frame(dev.layer_split,
        { name="aside", size={dev_window_min_size.x,0} },
        { point=.top_right },
        { point=.bottom_right },
    )

    ui.add_frame(dev.layer_split,
        { name="body", flags={.scissor} },
        { point=.top_left },
        { point=.bottom_right, rel_point=.bottom_left, rel_frame=aside },
    )
}

enable_dev_split_mode :: proc () {
    body := ui.get(dev.layer_split, "body")
    // we temp copy only because we are about to iterate over children and set_parent() modifies children array
    for layer in slice.clone_to_dynamic(ui_.root.children[:], context.temp_allocator) {
        if layer == dev.layer_split do continue
        ui.set_parent(layer, body)
    }

    aside := ui.get(dev.layer_split, "aside")
    dev.window_rect_saved = dev.window.rect
    ui.set_parent(dev.window, aside)
    ui.set_anchors(dev.window, { point=.top_left }, { point=.bottom_right })

    ui.show(dev.layer_split)
}

disable_dev_split_mode :: proc () {
    body := ui.get(dev.layer_split, "body")
    for layer in slice.clone_to_dynamic(body.children[:], context.temp_allocator) {
        ui.set_parent(layer, ui_.root)
    }

    ui.set_parent(dev.window, dev.layer)
    ui.clear_anchors(dev.window)
    dev.window.rect = dev.window_rect_saved

    ui.hide(dev.layer_split)
}
