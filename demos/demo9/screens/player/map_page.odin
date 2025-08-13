#+private
package player

import "core:fmt"
import "core:math/ease"

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"

import "../../partials"

map_page: struct {
    root                 : ^ui.Frame,

    filter_button        : ^ui.Frame,
    legend_button        : ^ui.Frame,
    recenter_button      : ^ui.Frame,

    area                : ^ui.Frame,
    area_land           : [333] struct { center: Vec2, size: Vec2 },
    area_offset         : Vec2,

    info_panel          : ^ui.Frame,
    legend_panel        : ^ui.Frame,
    legend_panel_opened : bool,
}

add_map_page :: proc () {
    _, map_page.root = partials.add_screen_tab_and_page(&screen, "map", "MAP")

    map_page.filter_button = partials.add_screen_pyramid_button(&screen,
        "map_filter", text="<icon=key_tiny/F:.7> FILTER", icon="visibility")
    ui.set_order(map_page.filter_button, -2)

    map_page.legend_button = partials.add_screen_pyramid_button(&screen,
        name="map_legend", text="<icon=key_tiny/L:.7> LEGEND", icon="view_cozy")
    ui.set_order(map_page.legend_button, -1)
    map_page.legend_button.click = proc (f: ^ui.Frame) {
        map_page.legend_panel_opened ~= true
        if map_page.legend_panel_opened {
            ui.animate(map_page.legend_panel, anim_map_legend_panel_appear, .333)
        } else {
            ui.animate(map_page.legend_panel, anim_map_legend_panel_disappear, .333)
        }
    }

    map_page.recenter_button = partials.add_screen_key_button(&screen, "recenter", "<icon=key/R> Re-center")
    map_page.recenter_button.click = proc (f: ^ui.Frame) {
        map_page.area_offset = 0
    }

    map_page.root.show = proc (f: ^ui.Frame) {
        partials.move_screen_pyramid_buttons(&screen, .left)
        ui.show(map_page.filter_button)
        ui.show(map_page.legend_button)
        ui.show(map_page.recenter_button)
    }

    map_page.root.hide = proc (f: ^ui.Frame) {
        partials.move_screen_pyramid_buttons(&screen, .center)
        ui.hide(map_page.filter_button)
        ui.hide(map_page.legend_button)
        ui.hide(map_page.recenter_button)
    }

    add_map_area()
    add_map_info_panel()
    add_map_legend_panel()

    // ui.print_frame_tree(map_page.root)
}

add_map_area :: proc () {
    map_page.area = ui.add_frame(map_page.root, {
        name="area",
        flags={.capture},
        draw=draw_map_area,
        drag=proc (f: ^ui.Frame, info: ui.Drag_Info) {
            map_page.area_offset += info.delta
        },
    },
        { point=.top_left },
        { point=.bottom_right },
    )

    for &d in map_page.area_land {
        d = {
            center  = core.random_vec_in_rect({-2000,-2000,4000,4000}),
            size    = core.random_vec_in_rect({0,0,400,400}) + 100,
        }
    }
}

draw_map_area :: proc (f: ^ui.Frame) {
    color := Color {200,160,120,255}

    draw.rect(f.rect, core.brightness(color, -.6))
    offset := core.rect_center(f.rect) + map_page.area_offset

    for d, i in map_page.area_land {
        rect := core.rect_from_center(d.center, d.size)
        rect = core.rect_moved(rect, offset)
        draw.rect(rect, core.brightness(color, +.2 -.2*f32(i%4)))
    }
}

add_map_info_panel :: proc () {
    map_page.info_panel = ui.add_frame(map_page.root, {
        flags={.pass},
        name="info_panel",
        size={420,0},
        layout=ui.Flow{ dir=.down, pad=8, gap=4, auto_size={.height} },
        draw=partials.draw_info_panel_rect,
    },
        { point=.top_left, offset={60,20} },
    )

    add_map_info_panel_map_area(map_page.info_panel)
    add_map_info_panel_landscape(map_page.info_panel)
    add_map_info_panel_resource_density(map_page.info_panel)
    add_map_info_panel_collectables(map_page.info_panel)
}

add_map_info_panel_map_area :: proc (parent: ^ui.Frame) {
    partials.add_panel_header(parent, "MAP AREA", icon="distance")

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

    partials.add_progress_bar(details, title="AREA COMPLETION", progress_ratio=.97)
}

add_map_info_panel_landscape :: proc (parent: ^ui.Frame) {
    partials.add_panel_header(parent, "LANDSCAPE", icon="landscape")

    details := add_map_info_panel_grid(parent)
    for i in ([?] struct { icon, text: string } {
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
    partials.add_panel_header(parent, "RESOURCE DENSITY", icon="lens_blur")

    for rank in ([?] struct { icon: string, list: [] string } {
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
            if i == 0 do ui.add_frame(row, {
                name="rank",
                text=rank.icon,
                size_ratio=.8,
                draw=partials.draw_icon_diamond_fill_primary,
            })
            ui.add_frame(row, {
                name="res",
                text=icon,
                draw=partials.draw_icon_primary_with_shadow,
            })
        }
    }
}

add_map_info_panel_collectables :: proc (parent: ^ui.Frame) {
    partials.add_panel_header(parent, "COLLECTABLES", icon="package_2")

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
    ui.add_frame(parent, {
        name="cell",
        flags={.terse},
        text=fmt.tprintf("<left,font=text_4l,color=primary_d2,icon=%s:1.1><tab=40,color=primary_l4>%s", icon, text),
        draw=partials.draw_text_drop_shadow,
    })
}

add_map_legend_panel :: proc () {
    pad :: 40

    map_page.legend_panel = ui.add_frame(map_page.root, {
        name="legend_panel",
        flags={.hidden},
        size={640,0},
        text="#000b",
        draw=partials.draw_color_rect,
    },
        { point=.top_right },
        { point=.bottom_right },
    )

    title := ui.add_frame(map_page.legend_panel, {
        name="title",
        text="<pad=6:0,font=text_4r,color=bg1>LEGEND",
        flags={.terse,.terse_height},
        draw=partials.draw_hexagon_rect_fill_hangout_self_rect,
    },
        {point=.top_left,offset={pad,pad}},
        {point=.top_right,offset={-pad,pad}},
    )

    list := ui.add_frame(map_page.legend_panel, {
        name="list",
        flags={.scissor},
        layout=ui.Flow{ dir=.down, gap=10, scroll={step=20} },
    },
        {point=.top_left,rel_point=.bottom_left,rel_frame=title,offset={0,20}},
        {point=.bottom_right,offset={-pad,-pad}},
    )

    partials.add_scrollbar(list)

    cols := ui.add_frame(list, {
        name="cols",
        layout=ui.Flow{ dir=.right, auto_size={.height} },
    })

    col_row_gap :: 16
    col_width_ratio :: .48
    assert(col_width_ratio < .5)

    col_left := ui.add_frame(cols, {
        name="col_left",
        size_ratio={col_width_ratio,0},
        layout=ui.Flow{ dir=.down, pad=1, gap=col_row_gap, auto_size={.height} },
    })

    ui.add_frame(cols, { name="gap", size={0,1}, size_ratio={1-2*col_width_ratio,0} })

    col_right := ui.add_frame(cols, {
        name="col_right",
        size_ratio={col_width_ratio,0},
        layout=ui.Flow{ dir=.down, pad=1, gap=col_row_gap, auto_size={.height} },
    })

    Target  :: struct { col: ^ui.Frame }
    Header  :: struct { text: string }
    Item    :: struct { text, icon: string }

    target_col: ^ui.Frame

    for row in ([?] union { Target, Header, Item } {
        // --------------------------------------------------------------------
        Target  { col=col_left },
        // --------------------------------------------------------------------
        Header  { text="PLAYER" },
            Item    { text="Player"                 , icon="chess_pawn" },
            Item    { text="Party Leader"           , icon="chess_pawn" },
            Item    { text="Party Member"           , icon="chess_pawn" },
        Header  { text="DEATH AND RESPAWN" },
            Item    { text="Death Location"         , icon="skull" },
            Item    { text="Defeat Location"        , icon="skull" },
            Item    { text="Default Respawn"        , icon="distance" },
            Item    { text="Respawn Beacon"         , icon="distance" },
        Header  { text="VEHICLES" },
            Item    { text="Sand Bike"              , icon="snowmobile" },
            Item    { text="Sand Buggy"             , icon="directions_car" },
            Item    { text="Spice Harvester"        , icon="directions_car" },
            Item    { text="Ornithopter"            , icon="helicopter" },
            Item    { text="Carrier Ornithopter"    , icon="helicopter" },
        Header  { text="HAZARD" },
            Item    { text="Sandworm Breach"        , icon="mode_fan" },
            Item    { text="Quicksand"              , icon="mist" },
            Item    { text="Drumsand"               , icon="mist" },
            Item    { text="Radiation"              , icon="heat" },
            Item    { text="Fire"                   , icon="heat" },
            Item    { text="Poison"                 , icon="heat" },
            Item    { text="Sandstorm"              , icon="air" },
        Header  { text="NPCS" },
            Item    { text="Vendor"                 , icon="shopping_cart" },
            Item    { text="Tax Collector"          , icon="money_bag" },
            Item    { text="Swordmaster Trainer"    , icon="mindfulness" },
            Item    { text="Trooper Trainer"        , icon="mindfulness" },
            Item    { text="Mentat Trainer"         , icon="mindfulness" },
            Item    { text="Bene Gesserit Trainer"  , icon="mindfulness" },
            Item    { text="Planetologist Trainer"  , icon="mindfulness" },
            Item    { text="Contract"               , icon="stylus_fountain_pen" },
            Item    { text="House Representative"   , icon="shield_person" },
        // --------------------------------------------------------------------
        Target  { col=col_right },
        // --------------------------------------------------------------------
        Header  { text="BASE" },
            Item    { text="Home Base"              , icon="home" },
            Item    { text="Authorized Base"        , icon="home" },
        Header  { text="RESOURCES" },
            Item    { text="Brittle Bush"           , icon="spa" },
            Item    { text="Primrose Field"         , icon="water_drop" },
            Item    { text="Fuel Cell"              , icon="deployed_code" },
            Item    { text="Salvaged Metal"         , icon="hive" },
            Item    { text="Granite Stone"          , icon="cookie" },
            Item    { text="Copper Ore"             , icon="cookie" },
            Item    { text="Iron Ore"               , icon="cookie" },
            Item    { text="Carbon Ore"             , icon="cookie" },
            Item    { text="Erythrite Crystal"      , icon="diamond" },
            Item    { text="Aluminum Ore"           , icon="cookie" },
            Item    { text="Basalt Stone"           , icon="cookie" },
            Item    { text="Jasmium Crystal"        , icon="diamond" },
            Item    { text="Titanium Ore"           , icon="cookie" },
            Item    { text="Stravidium Mass"        , icon="stacks" },
            Item    { text="Spice Field"            , icon="salinity" },
            Item    { text="Flour Sand"             , icon="salinity" },
        Header  { text="LOCATION" },
            Item    { text="Cave"                   , icon="distance" },
            Item    { text="Shipwreck"              , icon="distance" },
            Item    { text="Imperial Testing Station",icon="distance" },
            Item    { text="Trading Post"           , icon="distance" },
            Item    { text="Enemy Camp"             , icon="distance" },
            Item    { text="Enemy Outpost"          , icon="distance" },
            Item    { text="Atreides Fortress"      , icon="account_balance" },
            Item    { text="Harkonnen Fortress"     , icon="account_balance" },
            Item    { text="Control Point"          , icon="distance" },
            Item    { text="Mining Facility"        , icon="distance" },
            Item    { text="Landmark"               , icon="distance" },
        Header  { text="OTHER" },
            Item    { text="Lifeform"               , icon="chess_pawn" },
            Item    { text="Thumper"                , icon="priority_high" },
    }) {
        switch v in row {
        case Target:
            target_col = v.col
        case Header:
            ui.add_frame(target_col, {
                name="header",
                flags={.terse,.terse_height},
                text=fmt.tprintf("<left,pad=22:0,font=text_4l,color=primary_d2>%s", v.text),
                draw=partials.draw_hexagon_rect,
            })
        case Item:
            ui.add_frame(target_col, {
                name="item",
                flags={.terse,.terse_height},
                text=fmt.tprintf("<wrap,left,pad=18:0,font=text_4l,color=primary_d2,icon=%s:1.2><tab=50>%s", v.icon, v.text),
                draw=partials.draw_text_drop_shadow,
            })
        }
    }
}

anim_map_legend_move_distance_x :: 200

anim_map_legend_panel_appear :: proc (f: ^ui.Frame) {
    offset_x :: anim_map_legend_move_distance_x
    switch f.anim.ratio {
    case 0:
        f.offset.x = offset_x
        ui.set_opacity(f, 0)
        ui.show(f)
    case:
        ratio := ease.cubic_out(f.anim.ratio)
        f.offset.x = offset_x * (1-ratio)
        ui.set_opacity(f, ratio)
    case 1:
        f.offset.x = 0
        ui.set_opacity(f, 1)
    }
}

anim_map_legend_panel_disappear :: proc (f: ^ui.Frame) {
    offset_x :: anim_map_legend_move_distance_x
    switch f.anim.ratio {
    case:
        ratio := ease.cubic_out(f.anim.ratio)
        f.offset.x = offset_x * ratio
        ui.set_opacity(f, 1-ratio)
    case 1:
        f.offset.x = 0
        ui.set_opacity(f, 0)
        ui.hide(f)
    }
}
