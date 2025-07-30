#+private
package player

import "core:fmt"

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"

import "../../partials"

Map_Page :: struct {
    root            : ^ui.Frame,

    filter_button   : ^ui.Frame,
    legend_button   : ^ui.Frame,

    area            : ^ui.Frame,
    area_offset     : Vec2,
    area_scale      : f32,
    area_details    : [100] struct { center: Vec2, size: Vec2, color: Color },
}

add_map_page :: proc () {
    map_ := &screen.map_
    _, map_.root = partials.add_screen_tab_and_page(&screen, "map", "MAP")

    map_.filter_button = partials.add_screen_pyramid_button(&screen, "map_filter", "<icon=key_tiny/F:.7> FILTER", icon="visibility")
    ui.set_order(map_.filter_button, -2)

    map_.legend_button = partials.add_screen_pyramid_button(&screen, "map_legend", "<icon=key_tiny/L:.7> LEGEND", icon="view_cozy")
    ui.set_order(map_.legend_button, -1)

    map_.root.show = proc (f: ^ui.Frame) {
        partials.move_screen_pyramid_buttons(&screen, .left)
        ui.show(screen.map_.filter_button)
        ui.show(screen.map_.legend_button)
    }

    map_.root.hide = proc (f: ^ui.Frame) {
        partials.move_screen_pyramid_buttons(&screen, .center)
        ui.hide(screen.map_.filter_button)
        ui.hide(screen.map_.legend_button)
    }

    add_map_area(map_.root)

    ui.print_frame_tree(map_.root)
}

add_map_area :: proc (parent: ^ui.Frame) {
    map_ := &screen.map_

    map_.area = ui.add_frame(parent, {
        name="area",
        flags={.capture},
        text="#567",
        size={0,200},
        size_aspect=1.6,
        draw=draw_map_area,
        drag=proc (f: ^ui.Frame, local_captured_pos, abs_mouse_pos: Vec2) {
            fmt.println(f.name, local_captured_pos, abs_mouse_pos)
        },
    },
        { point=.top_left },
        { point=.bottom_right },
    )

    map_.area_scale = 1

    // generate some map placeholder
    for &d in map_.area_details {
        d = { center={500,300}, size={400,200}, color={100,200,240,255} }
    }
}

draw_map_area :: proc (f: ^ui.Frame) {
    map_ := &screen.map_

    for d in map_.area_details {
        rect := core.rect_from_center(d.center, d.size)
        draw.rect(rect, d.color)
    }
}
