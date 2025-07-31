#+private
package player

// import "core:fmt"
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
    area_land       : [333] struct { center: Vec2, size: Vec2 },
    area_offset     : Vec2,

    info_panel      : ^ui.Frame,
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

    add_map_area()
    add_map_info_panel()

    ui.print_frame_tree(map_.root)
}

add_map_area :: proc () {
    map_ := &screen.map_

    map_.area = ui.add_frame(map_.root, {
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

    for &d in map_.area_land {
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
    offset := core.rect_center(f.rect) + map_.area_offset

    for d, i in map_.area_land {
        rect := core.rect_from_center(d.center, d.size)
        rect = core.rect_moved(rect, offset)
        draw.rect(rect, core.brightness(color, +.2 -.2*f32(i%4)))
    }
}

add_map_info_panel :: proc () {
    map_ := &screen.map_

    panel := ui.add_frame(map_.root, {
        flags={.pass},
        name="info_panel",
        size={420,0},
        layout=ui.Flow{ dir=.down, pad=8, gap=4, auto_size={.height} },
        draw=partials.draw_info_panel_rect,
    },
        { point=.top_left, offset={60,20} },
    )

    add_map_info_panel_map_area(panel)
    add_map_info_panel_landscape(panel)
    add_map_info_panel_resource_density(panel)
    add_map_info_panel_collectables(panel)
}

add_map_info_panel_map_area :: proc (parent: ^ui.Frame) {
    partials.add_panel_section_header(parent, "MAP AREA", icon="distance")

    details := ui.add_frame(parent, {
        name="details",
        layout=ui.Flow{ dir=.down, pad={10,10,5,10}, auto_size={.height} },
    })

    ui.add_frame(details, {
        name="area_name",
        flags={.terse,.terse_height},
        text="Eastern Vermillius Gap",
        text_format="<left,font=text_4m,color=primary_l4>%s",
        draw=partials.draw_text_drop_shadow,
    })

    partials.add_panel_progress_bar(details, title="AREA COMPLETION", progress_ratio=.97)
}

add_map_info_panel_landscape :: proc (parent: ^ui.Frame) {
    partials.add_panel_section_header(parent, "LANDSCAPE", icon="landscape")

    details := add_map_info_panel_grid(parent)
    for i in ([] struct { icon, text: string } {
        { icon="flag_circle", text="2/2" },
        { icon="flag_circle", text="2/2" },
        { icon="flag_circle", text="1/1" },
        { icon="flag_circle", text="5/5" },
        { icon="flag_circle", text="20/21" },
        { icon="flag_circle", text="1/1" },
    }) {
        add_map_info_panel_cell_with_icon_and_text(details, i.icon, i.text)
    }
}

add_map_info_panel_resource_density :: proc (parent: ^ui.Frame) {
    partials.add_panel_section_header(parent, "RESOURCE DENSITY", icon="lens_blur")

    for rank in ([] struct { icon: string, list: [] string } {
        { icon="stat_3", list={ "cannabis", "spa", "hive", "database", "water_drop" } },
        { icon="stat_2", list={ "diamond", "deployed_code" } },
        { icon="stat_1", list={ "coronavirus" } },
    }) {
        row := ui.add_frame(parent, {
            name="row",
            layout=ui.Flow{ dir=.right, size=32, pad={7,0,0,0}, gap=12, align=.center, auto_size={.height} },
        })

        ui.add_frame(row, {
            name="line",
            size={0,12},
            text="#0004",
            draw=partials.draw_gradient_fade_right_rect,
        },
            {point=.left},
            {point=.right},
        )

        for icon, i in rank.list {
            if i == 0 do ui.add_frame(row, { text=rank.icon, size_ratio=.8, draw=partials.draw_icon_diamond_fill_primary })
            ui.add_frame(row, { text=icon, draw=partials.draw_icon_primary_with_shadow })
        }
    }
}

add_map_info_panel_collectables :: proc (parent: ^ui.Frame) {
    partials.add_panel_section_header(parent, "COLLECTABLES", icon="package_2")

    details := add_map_info_panel_grid(parent)
    add_map_info_panel_cell_with_icon_and_text(details, "cookie", "6/6")
}

add_map_info_panel_grid :: proc (parent: ^ui.Frame) -> ^ui.Frame {
    return ui.add_frame(parent, {
        name="details",
        layout=ui.Grid{ dir=.right_down, wrap=4, pad=4, gap=2, aspect=3, auto_size={.height} },
    })
}

add_map_info_panel_cell_with_icon_and_text :: proc (parent: ^ui.Frame, icon, text: string) {
    cell := ui.add_frame(parent, { name="cell", layout=ui.Flow{ dir=.right } })
    ui.add_frame(cell, { name="icon", size_aspect=1, text=icon, draw=partials.draw_icon_primary_with_shadow })
    ui.add_frame(cell, {
        name="text",
        flags={.terse,.terse_width},
        text=text,
        text_format="<left,pad=10:0,font=text_4l,color=primary_l4>%s",
        draw=partials.draw_text_drop_shadow,
    })
}
