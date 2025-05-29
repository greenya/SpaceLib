package demo8

import "core:math"
import "core:slice"
import "spacelib:core"
import "spacelib:ui"

App_Menu :: struct {
}

app_menu_create :: proc () {
    app.menu = new(App_Menu)

    app_menu_add_bar_top(app.ui.root)
    app_menu_add_bar_bottom(app.ui.root)
    app_menu_add_page_character(app.ui.root)
}

app_menu_destroy :: proc () {
    free(app.menu)
    app.menu = nil
}

app_menu_add_bar_top :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="bar_top", size={0,64}, order=1, draw=draw_black_rect },
        { point=.top_left },
        { point=.top_right },
    )

    tabs := ui.add_frame(root,
        { name="tabs", layout={ dir=.left_and_right, size={160,0} } },
        { point=.top_left },
        { point=.bottom_right },
    )

    for text in ([] string { "FRAGMENTS", "ARCHETYPE", "CHARACTER", "TRAITS", "INVENTORY" }) {
        ui.add_frame(tabs, { text=text, flags={.radio}, draw=draw_menu_item })
    }

    ui.add_frame(root,
        { name="nav_left", text="<font=text_20,icon=key_Q:1.5>", flags={.terse,.terse_width,.terse_height} },
        { point=.right, rel_point=.left, rel_frame=tabs.children[0], offset={-8,0} },
    )

    ui.add_frame(root,
        { name="nav_right", text="<font=text_20,icon=key_E:1.5>", flags={.terse,.terse_width,.terse_height} },
        { point=.left, rel_point=.right, rel_frame=slice.last(tabs.children[:]), offset={8,0} },
    )

    ui.add_frame(root,
        { name="scrap_count", text="<right,font=text_24,color=bw_95>4,076  <icon=cubes:1.3>", flags={.terse,.terse_width,.terse_height} },
        { point=.right, offset={-64,0} },
    )

    ui.click(tabs.children[2]) // preselect default tab (ugly way)
}

app_menu_add_bar_bottom :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="bar_bottom", size={0,64}, order=1, draw=draw_black_rect },
        { point=.bottom_left },
        { point=.bottom_right },
    )

    ui.add_frame(root,
        { name="toggle_stats", text="<left,font=text_20,color=bw_6c><icon=key_R:1.5>  Stats | Loadouts", flags={.terse,.terse_width,.terse_height} },
        { point=.left, offset={64,0} },
    )

    ui.add_frame(root,
        { name="nav_back", text="<right,font=text_20,color=bw_6c><icon=key_Esc:2.2:1.5>  Back", flags={.terse,.terse_width,.terse_height} },
        { point=.right, offset={-64,0} },
    )
}

app_menu_add_page_character :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_character" },
        { point=.top_left, rel_point=.bottom_left, rel_frame=ui.get(parent, "bar_top") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=ui.get(parent, "bar_bottom") },
    )

    radius :: 460

    ring := ui.add_frame(root,
        { name="ring", size=2*radius, flags={.pass}, draw=draw_art_ring },
        { point=.center },
    )

    // left side of the ring

    primary := ui.add_frame(ring,
        { name="primary", text="wolf-howl", size=120, draw=draw_slot_round },
        { point=.center, offset=core.vec_on_circle(radius, -math.τ/4 -.75) },
    )

    ui.add_frame(root,
        { name="skill", text="paw-print", size=80, order=-1, draw=draw_slot_box },
        { point=.right, rel_point=.left, rel_frame=primary, offset={20,0} },
    )

    ui.add_frame(primary,
        { name="level", text="10", size=32, draw=draw_slot_round_level },
        { point=.center, rel_point=.left },
    )

    for i in 0..<5 {
        ui.add_frame(ring,
            { name="slot_gear", text="cracked-helm", size=80, draw=draw_slot_box },
            { point=.center, offset=core.vec_on_circle(radius, -math.τ/4 -1.2 -.2*f32(i)) },
        )
    }

    // right side of the ring

    secondary := ui.add_frame(ring,
        { name="secondary", text="witch-flight", size=120, draw=draw_slot_round },
        { point=.center, offset=core.vec_on_circle(radius, -math.τ/4 +.75) },
    )

    ui.add_frame(root,
        { name="skill", text="haunting", size=80, order=-1, draw=draw_slot_box },
        { point=.left, rel_point=.right, rel_frame=secondary, offset={-20,0} },
    )

    ui.add_frame(secondary,
        { name="level", text="8", size=32, draw=draw_slot_round_level },
        { point=.center, rel_point=.right },
    )

    for i in 0..<5 {
        ui.add_frame(ring,
            { name="slot_acc", text="skull-ring", size=80, draw=draw_slot_box },
            { point=.center, offset=core.vec_on_circle(radius, -math.τ/4 +1.2 +.2*f32(i)) },
        )
    }

    // bottom side of the ring

    weapon_bar := ui.add_frame(ring,
        { layout={ dir=.left_and_right, size={240,80}, gap=16, align=.center } },
        { point=.left, rel_point=.center, offset=core.vec_on_circle(radius, math.τ/4 +.75) },
        { point=.right, rel_point=.center, offset=core.vec_on_circle(radius, math.τ/4 -.75) },
    )

    for _ in 0..<3 {
        ui.add_frame(weapon_bar, { name="slot_weapon", text="wood-axe", draw=draw_slot_box_wide })
    }
}
