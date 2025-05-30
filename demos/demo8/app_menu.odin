package demo8

import "core:math"
import "core:slice"
import "spacelib:core"
import "spacelib:ui"

App_Menu :: struct {
}

app_menu_create :: proc () {
    app.menu = new(App_Menu)

    root := ui.add_frame(app.ui.root,
        { name="menu" },
        { point=.top_left },
        { point=.bottom_right },
    )

    app_menu_add_bar_top(root)
    app_menu_add_bar_bottom(root)

    pages := ui.add_frame(root,
        { name="pages" },
        { point=.top_left, rel_point=.bottom_left, rel_frame=app.ui->get("bar_top") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=app.ui->get("bar_bottom") },
    )

    app_menu_add_page_fragments(pages)
    app_menu_add_page_archetype(pages)
    app_menu_add_page_character(pages)
    app_menu_add_page_traits(pages)
    app_menu_add_page_inventory(pages)

    for child in pages.children do ui.hide(child)

    app.ui->click("menu/bar_top/tab_character") // preselect some tab
}

app_menu_destroy :: proc () {
    free(app.menu)
    app.menu = nil
}

app_menu_add_bar_top :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="bar_top", text="bw_00", size={0,64}, order=1, draw=draw_color_rect },
        { point=.top_left },
        { point=.top_right },
    )

    tabs := ui.add_frame(root,
        { name="tabs", layout={ dir=.left_and_right, size={160,0} } },
        { point=.top_left },
        { point=.bottom_right },
    )

    for tab in ([][] string {
        { "tab_fragments", "FRAGMENTS" },
        { "tab_archetype", "ARCHETYPE" },
        { "tab_character", "CHARACTER" },
        { "tab_traits", "TRAITS" },
        { "tab_inventory", "INVENTORY" },
    }) {
        ui.add_frame(tabs, {
            name    = tab[0],
            text    = tab[1],
            flags   = {.radio},
            draw    = draw_menu_item,
            click   = proc (f: ^ui.Frame) {
                switch f.name {
                case "tab_fragments": app_menu_switch_page("page_fragments")
                case "tab_archetype": app_menu_switch_page("page_archetype")
                case "tab_character": app_menu_switch_page("page_character")
                case "tab_traits"   : app_menu_switch_page("page_traits")
                case "tab_inventory": app_menu_switch_page("page_inventory")
                }
            },
        })
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
        { name="scrap_count", text_format="<right,font=text_24,color=bw_95>%v  <icon=cubes:1.3>", text="4,076", flags={.terse,.terse_width,.terse_height} },
        { point=.right, offset={-64,0} },
    )
}

app_menu_add_bar_bottom :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="bar_bottom", text="bw_00", size={0,64}, order=1, draw=draw_color_rect },
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
        { point=.top_left, rel_point=.bottom_left, rel_frame=app.ui->get("bar_top") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=app.ui->get("bar_bottom") },
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
            { point=.center, offset=core.vec_on_circle(radius, -math.τ/4 -1.175 -.2*f32(i)) },
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
            { point=.center, offset=core.vec_on_circle(radius, -math.τ/4 +1.175 +.2*f32(i)) },
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

    // side stats column

    stats_column := ui.add_frame(ring,
        { layout={ dir=.up_and_down } },
        { point=.left, offset={-188,0} },
    )

    stats_basic := ui.add_frame(stats_column, { name="stats_basic", text_format="<right,font=text_20,color=bw_95>"+
        "POWER LEVEL\n"+
        "<gap=2.5>HEALTH\n<gap=-.2,font=text_40,color=bw_da>%v</font,/color>\n"+
        "STAMINA\n<gap=-.2,font=text_40,color=bw_da>%v</font,/color>\n"+
        "ARMOR\n<gap=-.2,font=text_40,color=bw_da>%.1f</font,/color>\n"+
        "WEIGHT\n<gap=-.2,font=text_40,color=%v>%.1f</font,/color>",
        flags={.terse,.terse_height},
    })

    ui.set_text(stats_basic, 134.5, 112, 109.9, "weight_lt", 47.5)

    power := ui.add_frame(stats_basic,
        { name="power", text="<color=bw_40,icon=ink-swirl:3.3>", flags={.terse,.terse_width,.terse_height} },
        { point=.left, rel_point=.top_right, offset={24,8} },
    )

    ui.add_frame(power,
        { name="level", text_format="<font=text_32,color=bw_da>%v", text="15", flags={.terse,.terse_height} },
        { point=.center },
    )

    stats_res := ui.add_frame(stats_basic, { name="stats_res", text_format="<left,font=text_32,color=bw_da>"+
        "<gap=.4,color=res_bleed><icon=drop></color> %v\n"+
        "<gap=.4,color=res_fire><icon=candlebright></color> %v\n"+
        "<gap=.4,color=res_lightning><icon=power-lightning></color> %v\n"+
        "<gap=.4,color=res_poison><icon=crossed-bones></color> %v\n"+
        "<gap=.4,color=res_blight><icon=harry-potter-skull></color> %v",
        flags={.terse,.terse_height},
    },
        { point=.bottom_left, rel_point=.bottom_right, offset={24,-8} },
    )

    ui.set_text(stats_res, 6, 3, 1, 14, 6)

    ui.add_frame(stats_res,
        { size={2,80}, text="bw_1a", draw=draw_color_rect },
        { point=.center, rel_point=.left, offset={-stats_res.anchors[0].offset.x/2,0} },
    )

    // side traits column

    gap :: "<gap=.3>"
    pin :: "<icon=round-star>"
    alt_b :: "<color=res_fire>"
    alt_e :: "</color>"

    ui.add_frame(ring, { name="traits_columns", text="<left,font=text_20,color=bw_95>"+
        gap + "Longshot\n"+
        alt_b+pin+pin+pin+pin+pin+pin+pin+pin+pin+pin+alt_e+"\n"+
        gap + "Potency\n"+
        alt_b+pin+pin+pin+pin+pin+pin+pin+pin+pin+alt_e+"\n"+
        gap + "Vigor\n"+
        alt_b+pin+alt_e+pin+pin+pin+pin+pin+pin+pin+pin+pin+"\n"+
        gap + "Expertise\n"+
        alt_b+pin+pin+alt_e+pin+pin+pin+pin+pin+pin+pin+pin+"\n"+
        gap + "Amplitude\n"+
        pin+pin+pin+pin+pin+pin+pin+pin+pin+pin+"\n"+
        gap + "Siphoner\n"+
        pin+pin+pin+pin+pin+"\n"+
        gap + "Endurance\n"+
        alt_b+pin+pin+alt_e+pin+pin+"\n"+
        gap + "Spirit\n"+
        pin+pin+pin+pin,
        flags={.terse,.terse_height},
    },
        { point=.right, offset={100,0} },
    )
}

app_menu_add_page_archetype :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_archetype" },
        { point=.top_left, rel_point=.bottom_left, rel_frame=app.ui->get("bar_top") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=app.ui->get("bar_bottom") },
    )

    ui.add_frame(root,
        { name="msg", text="<font=text_40,color=bw_6c>ARCHETYPE PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

app_menu_add_page_fragments :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_fragments" },
        { point=.top_left, rel_point=.bottom_left, rel_frame=app.ui->get("bar_top") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=app.ui->get("bar_bottom") },
    )

    ui.add_frame(root,
        { name="msg", text="<font=text_40,color=bw_6c>FRAGMENTS PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

app_menu_add_page_traits :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_traits" },
        { point=.top_left, rel_point=.bottom_left, rel_frame=app.ui->get("bar_top") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=app.ui->get("bar_bottom") },
    )

    ui.add_frame(root,
        { name="msg", text="<font=text_40,color=bw_6c>TRAITS PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

app_menu_add_page_inventory :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_inventory" },
        { point=.top_left, rel_point=.bottom_left, rel_frame=app.ui->get("bar_top") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=app.ui->get("bar_bottom") },
    )

    ui.add_frame(root,
        { name="msg", text="<font=text_40,color=bw_6c>INVENTORY PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

app_menu_switch_page :: proc (page_name: string) {
    f := app.ui->get(page_name)

    for child in f.parent.children {
        ui.end_animation(child)
    }

    if .hidden in f.flags {
        ui.animate(f, app_menu_anim_switch_page, .4)
    }
}

app_menu_anim_switch_page :: proc (f: ^ui.Frame) {
    ui.set_opacity(f, f.anim.ratio)
    f.offset = { 0, 40 * (1 - core.ease_ratio(f.anim.ratio, .Cubic_Out)) }

    if f.anim.ratio == 0 {
        s := ui.first_visible_sibling(f)
        if s != nil do ui.animate(s, app_menu_anim_slide_down_disappear, .3)
        ui.show(f)
    }

    if f.anim.ratio == 1 {
        ui.show(f, hide_siblings=true)
    }
}

app_menu_anim_slide_down_disappear :: proc (f: ^ui.Frame) {
    ui.set_opacity(f, 1-f.anim.ratio)
    f.offset = { 0, 80 * core.ease_ratio(f.anim.ratio, .Cubic_In) }
}
