#+private
package player

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"

import "../../partials"

Map_Page :: struct {
    root            : ^ui.Frame,

    filter_button   : ^ui.Frame,
    legend_button   : ^ui.Frame,
    recenter_button : ^ui.Frame,

    area            : ^ui.Frame,
    area_details    : [400] struct { center: Vec2, size: Vec2 },
    area_offset     : Vec2,
}

add_map_page :: proc () {
    map_ := &screen.map_
    _, map_.root = partials.add_screen_tab_and_page(&screen, "map", "MAP")

    map_.filter_button = partials.add_screen_pyramid_button(&screen, "map_filter", "<icon=key_tiny/F:.7> FILTER", icon="visibility")
    ui.set_order(map_.filter_button, -2)

    map_.legend_button = partials.add_screen_pyramid_button(&screen, "map_legend", "<icon=key_tiny/L:.7> LEGEND", icon="view_cozy")
    ui.set_order(map_.legend_button, -1)

    map_.recenter_button = partials.add_screen_key_button(&screen, "recenter", "<icon=key/R> Re-center")
    map_.recenter_button.click = proc (f: ^ui.Frame) {
        screen.map_.area_offset = 0
    }

    map_.root.show = proc (f: ^ui.Frame) {
        partials.move_screen_pyramid_buttons(&screen, .left)
        ui.show(screen.map_.filter_button)
        ui.show(screen.map_.legend_button)
        ui.show(screen.map_.recenter_button)
    }

    map_.root.hide = proc (f: ^ui.Frame) {
        partials.move_screen_pyramid_buttons(&screen, .center)
        ui.hide(screen.map_.filter_button)
        ui.hide(screen.map_.legend_button)
        ui.hide(screen.map_.recenter_button)
    }

    add_map_area(map_.root)

    ui.print_frame_tree(map_.root)
}

add_map_area :: proc (parent: ^ui.Frame) {
    map_ := &screen.map_

    map_.area = ui.add_frame(parent, {
        name="area",
        flags={.capture},
        draw=draw_map_area,
        drag=proc (f: ^ui.Frame, info: ui.Drag_Info) {
            screen.map_.area_offset += info.delta
        },
    },
        { point=.top_left },
        { point=.bottom_right },
    )

    for &d in map_.area_details {
        d = {
            center  = core.random_vec_in_rect({-2000,-2000,4000,4000}),
            size    = core.random_vec_in_rect({0,0,400,400}) + 100,
        }
    }
}

draw_map_area :: proc (f: ^ui.Frame) {
    map_ := &screen.map_
    color := Color {200,160,120,255}

    draw.rect(f.rect, core.brightness(color, -.6))

    for d, i in map_.area_details {
        rect := core.rect_from_center(d.center, d.size)
        rect = core.rect_moved(rect, map_.area_offset)
        draw.rect(rect, core.brightness(color, +.2 -.2*f32(i%4)))
    }
}
