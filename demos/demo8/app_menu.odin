package demo8

import "core:fmt"
import "core:math"
import "core:slice"
import "spacelib:core"
import "spacelib:ui"

app_menu_create :: proc () {
    root := ui.add_frame(app.ui.root,
        { name="menu" },
        { point=.top_left },
        { point=.bottom_right },
    )

    app_menu_add_bar_top(root)
    app_menu_add_bar_bottom(root)

    pages := ui.add_frame(root,
        { name="pages" },
        { point=.top_left, rel_point=.bottom_left, rel_frame=app.ui->get("~bar_top") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=app.ui->get("~bar_bottom") },
    )

    app_menu_add_page_fragments(pages)
    app_menu_add_page_archetype(pages)
    app_menu_add_page_character(pages)
    app_menu_add_page_traits(pages)
    app_menu_add_page_inventory(pages)

    for child in pages.children do ui.hide(child)

    app.ui->click("menu/bar_top/~tab_character") // preselect some tab
}

app_menu_destroy :: proc () {
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

    for info in ([] struct { name:string, text:string } {
        { "tab_fragments"   , "FRAGMENTS" },
        { "tab_archetype"   , "ARCHETYPE" },
        { "tab_character"   , "CHARACTER" },
        { "tab_traits"      , "TRAITS" },
        { "tab_inventory"   , "INVENTORY" },
    }) {
        ui.add_frame(tabs, {
            name    = info.name,
            text    = info.text,
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
        { name="nav_left", text="<font=text_20,icon=key.Q:1.5>", flags={.capture,.terse,.terse_width,.terse_height}, draw=draw_menu_item_nav },
        { point=.right, rel_point=.left, rel_frame=tabs.children[0], offset={-8,0} },
    )

    ui.add_frame(root,
        { name="nav_right", text="<font=text_20,icon=key.E:1.5>", flags={.capture,.terse,.terse_width,.terse_height}, draw=draw_menu_item_nav },
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
        { name="toggle_stats", text="<left,font=text_20,color=bw_6c><icon=key.R:1.5>  Stats | Loadouts", flags={.capture,.terse,.terse_width,.terse_height}, draw=draw_menu_item_nav },
        { point=.left, offset={64,0} },
    )

    ui.add_frame(root,
        { name="nav_back", text="<right,font=text_20,color=bw_6c><icon=key.Esc:2.2:1.5>  Back", flags={.capture,.terse,.terse_width,.terse_height}, draw=draw_menu_item_nav },
        { point=.right, offset={-64,0} },
    )
}

app_menu_add_page_fragments :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_fragments" },
        { point=.top_left },
        { point=.bottom_right },
    )

    ui.add_frame(root,
        { name="msg", text="<font=text_40,color=bw_6c>FRAGMENTS PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

app_menu_art_ring_radius :: 460

app_menu_pos_on_art_ring :: proc (angle_rad: f32) -> Vec2 {
    return core.vec_on_circle(app_menu_art_ring_radius, angle_rad)
}

app_menu_add_primary_slot :: proc (parent: ^ui.Frame) -> ^ui.Frame {
    root := ui.add_frame(parent,
        { name="primary", text="wolf-howl", size=120, draw=draw_slot_round },
        { point=.center, offset=app_menu_pos_on_art_ring(-math.τ/4 -.75) },
    )

    ui.add_frame(root,
        { name="level", text="10", size=32, draw=draw_slot_round_level },
        { point=.center, rel_point=.left },
    )

    return root
}

app_menu_add_secondary_slot :: proc (parent: ^ui.Frame) -> ^ui.Frame {
    root := ui.add_frame(parent,
        { name="secondary", text="witch-flight", size=120, draw=draw_slot_round },
        { point=.center, offset=app_menu_pos_on_art_ring(-math.τ/4 +.75) },
    )

    ui.add_frame(root,
        { name="level", text="8", size=32, draw=draw_slot_round_level },
        { point=.center, rel_point=.right },
    )

    return root
}

app_menu_add_page_archetype :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_archetype" },
        { point=.top_left },
        { point=.bottom_right },
    )

    ui.add_frame(root,
        { name="title", text="DEAD TO RIGHTS ISOLATOR", size={400,44}, draw=draw_player_title },
        { point=.center, offset={0,-390} },
    )

    // left side

    primary := app_menu_add_primary_slot(root)

    ui.get(primary, "level").anchors[0].rel_point = .bottom

    ui.add_frame(primary,
        { name="desc", text="<right>"+
            "<font=text_24,color=bw_da>HUNTER\n"+
            "<font=text_20,color=bw_95>PRIME ARCHETYPE\n"+
            "<font=text_16,color=bw_6c>SNIPER WAR MEDAL",
            flags={.terse,.terse_width,.terse_height},
        },
        { point=.right, rel_point=.left, offset={-40,0} },
    )

    app_menu_add_page_archetype_line_sections(primary, is_left=true)

    // right side

    secondary := app_menu_add_secondary_slot(root)

    ui.get(secondary, "level").anchors[0].rel_point = .bottom

    ui.add_frame(secondary,
        { name="desc", text="<left>"+
            "<font=text_24,color=bw_da>ALCHEMIST\n"+
            "<font=text_20,color=bw_95>SECONDARY ARCHETYPE\n"+
            "<font=text_16,color=bw_6c>PHILOSOPHER'S STONE",
            flags={.terse,.terse_width,.terse_height},
        },
        { point=.left, rel_point=.right, offset={40,0} },
    )

    app_menu_add_page_archetype_line_sections(secondary, is_left=false)

    // middle bottom

    prime_perk := ui.add_frame(root,
        { name="prime_perk", size={300,0}, layout={ dir=.down, align=.center, gap=20, auto_size=.dir } },
        { point=.top, rel_point=.center, offset={0,40} },
    )

    ui.add_frame(prime_perk, { name="slot", text="fire-silhouette", size=80, draw=draw_slot_perk })
    ui.add_frame(prime_perk, { name="desc", text="<wrap,font=text_20,color=bw_95>"+
        "<font=text_24,color=bw_bc>DEAD TO RIGHTS</font,/color>\n"+
        "<font=text_16,gap=.6>PRIME PERK</font>\n"+
        "<gap=.5>Dealing <color=bw_ff>55</color> Base Ranged or Melee Weakspot Damage extends the duration of active Hunter Skills by <color=bw_ff>3.5s</color>. Can extend timer beyond its initial duration.",
        flags={.terse,.terse_height} })
}

app_menu_add_page_archetype_line_sections :: proc (parent: ^ui.Frame, is_left: bool) {
    line := ui.add_frame(parent,
        { name="line", text="bw_40", order=-1, size={3,420}, draw=draw_color_rect },
        { point=.top, rel_point=.bottom },
    )

    { // skills
        skills := ui.add_frame(line,
            { name="skills" },
            { point=.top, offset={0,50} },
        )

        text := is_left\
            ? "<right,font=text_20,color=bw_95>SKILLS <icon=card.polar-star:2>"\
            : "<left,font=text_20,color=bw_95><icon=card.polar-star:2> SKILLS"
        ui.add_frame(skills,
            { name="header", text=text, flags={.terse,.terse_width,.terse_height} },
            { point=is_left?.right:.left, rel_point=.center, offset={(is_left?1:-1)*20,0} },
        )

        list := ui.add_frame(skills,
            { name="list", layout={ dir=is_left?.left:.right, size=128, gap=8, pad={24,32}, auto_size=.full } },
            { point=is_left?.top_right:.top_left },
        )

        skill_ids := is_left\
            ? [] string { "hunters_mark", "hunters_focus", "hunters_shroud" }\
            : [] string { "vial_stone_mist", "vial_frenzy_dust", "vial_elixir_of_life" }

        for skill_id in skill_ids {
            ui.add_frame(list, { name="slot_skill", text=skill_id, draw=draw_slot_skill,
                enter=app_tooltip_show, leave=app_tooltip_hide,
            })
        }
    }

    { // perks
        perks := ui.add_frame(line,
            { name="perks" },
            {   point       = is_left ? .top_right : .top_left,
                rel_point   = is_left ? .bottom_right : .bottom_left,
                rel_frame   = ui.get(line, "skills/list"),
            },
        )

        text := is_left\
            ? "<right,font=text_20,color=bw_95>PERKS <icon=card.fist:2>"\
            : "<left,font=text_20,color=bw_95><icon=card.fist:2> PERKS"
        ui.add_frame(perks,
            { name="header", text=text, flags={.terse,.terse_width,.terse_height} },
            { point=is_left?.right:.left, rel_point=.center, offset={(is_left?1:-1)*20,0} },
        )

        list := ui.add_frame(perks,
            { name="list", layout={ dir=is_left?.left:.right, size={64,108}, gap=16, pad={24,32}, auto_size=.full } },
            { point=is_left?.top_right:.top_left },
        )

        icon := is_left ? "sword-wound" : "potion-ball"
        for _ in 0..<4 {
            ui.add_frame(list, { name="slot_perk", text=icon, draw=draw_slot_perk_with_cat })
        }
    }

    { // trait
        trait := ui.add_frame(line,
            { name="trait" },
            {   point       = is_left ? .top_right : .top_left,
                rel_point   = is_left ? .bottom_right : .bottom_left,
                rel_frame   = ui.get(line, "perks/list"),
            },
        )

        text := is_left\
            ? "<right,font=text_20,color=bw_95>TRAIT <icon=card.hand:2>"\
            : "<left,font=text_20,color=bw_95><icon=card.hand:2> TRAIT"
        ui.add_frame(trait,
            { name="header", text=text, flags={.terse,.terse_width,.terse_height} },
            { point=is_left?.right:.left, rel_point=.center, offset={(is_left?1:-1)*20,0} },
        )

        slot_trait := ui.add_frame(trait,
            { name="slot_trait.flat", text=is_left?"longshot":"potency", size={100,220}, draw=draw_slot_trait },
            { point=is_left?.top_right:.top_left, offset={(is_left?-1:1)*24,32} },
        )

        pin :: "<icon=round-star>"
        alt_b :: "<color=bw_40>"
        alt_e :: "</color>"

        desc: string
        if is_left {
            desc = fmt.tprintf("<wrap,right,font=text_16,color=bw_95>"+
                "<font=text_20,color=bw_ff>Longshot</font,/color>\n"+
                "<font=text_16,color=bw_6c>Archetype Trait</font,/color>\n"+
                pin+pin+pin+pin+pin+pin+pin+pin+pin+pin+"\n\n"+
                "%s",
                app.data.traits["longshot"]->desc(context.temp_allocator),
            )
        } else {
            desc = fmt.tprintf("<wrap,left,font=text_16,color=bw_95>"+
                "<font=text_20,color=bw_ff>Potency</font,/color>\n"+
                "<font=text_16,color=bw_6c>Archetype Trait</font,/color>\n"+
                pin+pin+pin+pin+pin+pin+pin+pin+pin+alt_b+pin+alt_e+"\n\n"+
                "%s",
                app.data.traits["potency"]->desc(context.temp_allocator),
            )
        }

        ui.add_frame(slot_trait,
            { name="desc", text=desc, size={200,0}, flags={.terse,.terse_height} },
            {   point       = is_left ? .right : .left,
                rel_point   = is_left ? .left : .right,
                offset      = is_left ? {-24,0} : {24,0},
            },
        )
    }
}

app_menu_add_page_character :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_character" },
        { point=.top_left },
        { point=.bottom_right },
    )

    ring := ui.add_frame(root,
        { name="ring", size=2*app_menu_art_ring_radius, flags={.pass_self}, draw=draw_art_ring },
        { point=.center },
    )

    // left side

    primary := app_menu_add_primary_slot(ring)

    ui.add_frame(root,
        { name="slot_skill", text="hunters_mark", size=80, order=-1, draw=draw_slot_skill,
            enter=app_tooltip_show, leave=app_tooltip_hide },
        { point=.right, rel_point=.left, rel_frame=primary, offset={20,0} },
    )

    gear_item_ids := [] string {
        "leto_mark_2_helmet",
        "academics_overcoat",
        "academics_trousers",
        "academics_gloves",
        "resonating_heart",
    }

    for item_id, i in gear_item_ids {
        ui.add_frame(ring,
            { name="slot_gear", text=item_id, size=80, draw=draw_slot_item,
                enter=app_tooltip_show, leave=app_tooltip_hide },
            { point=.center, offset=app_menu_pos_on_art_ring(-math.τ/4 -1.175 -.2*f32(i)) },
        )
    }

    // right side

    secondary := app_menu_add_secondary_slot(ring)

    ui.add_frame(root,
        { name="slot_skill", text="vial_frenzy_dust", size=80, order=-1, draw=draw_slot_skill,
            enter=app_tooltip_show, leave=app_tooltip_hide },
        { point=.left, rel_point=.right, rel_frame=secondary, offset={-20,0} },
    )

    accessory_item_ids := [] string {
        "whispering_marble",
        "stone_of_expanse",
        "braided_thorns",
        "dried_clay_ring",
        "thalos_eyelet",
    }

    for item_id, i in accessory_item_ids {
        ui.add_frame(ring,
            { name="slot_gear", text=item_id, size=80, draw=draw_slot_item,
                enter=app_tooltip_show, leave=app_tooltip_hide },
            { point=.center, offset=app_menu_pos_on_art_ring(-math.τ/4 +1.175 +.2*f32(i)) },
        )
    }

    // bottom area

    weapon_bar := ui.add_frame(ring,
        { layout={ dir=.left_and_right, size={240,80}, gap=16, align=.center } },
        { point=.left, rel_point=.center, offset=app_menu_pos_on_art_ring(math.τ/4 +.75) },
        { point=.right, rel_point=.center, offset=app_menu_pos_on_art_ring(math.τ/4 -.75) },
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
        "<gap=.4,color=res_bleed><icon=water-drop></color> %v\n"+
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
    alt_e :: "</>"

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

app_menu_add_page_traits :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_traits" },
        { point=.top_left },
        { point=.bottom_right },
    )

    header := ui.add_frame(root, { name="header", text=""+
        "<font=text_24,color=bw_da>0  <color=bw_95>TRAIT POINTS AVAILABLE\n"+
        "<gap=.2,font=text_20>38  <color=bw_59>TOTAL TRAIT POINTS",
        flags={.terse,.terse_height},
    },
        { point=.top, offset={0,32} },
    )

    list := ui.add_frame(root,
        { name="list", layout={ dir=.down, gap=12, auto_size=.full } },
        { point=.top, rel_point=.bottom, rel_frame=header, offset={0,32} },
    )

    row_count :: 3
    col_count :: 8

    trait_ids := [] string {
        "longshot", "potency", "vigor", "endurance",
        "spirit", "expertise", "amplitude", "blood_bond",
        "bloodstream", "siphoner",
    }

    for row_idx in 0..<row_count {
        row := ui.add_frame(list, { name="row", layout={ dir=.right, size={100,220}, gap=12, auto_size=.full } })
        for col_idx in 0..<col_count {
            trait_idx := row_idx*col_count + col_idx
            trait_id := trait_idx < len(trait_ids) ? trait_ids[trait_idx] : ""
            ui.add_frame(row, { name="slot_trait", text=trait_id, draw=draw_slot_trait,
                enter=app_tooltip_show, leave=app_tooltip_hide })
        }
    }
}

app_menu_add_page_inventory :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_inventory" },
        { point=.top_left },
        { point=.bottom_right },
    )

    sections := ui.add_frame(root,
        { name="sections", layout={ dir=.down, gap=10, auto_size=.full } },
        { point=.center },
    )

    col_count :: 9

    for info in ([] struct { name:string, text:string, row_count:int, item_tag: App_Data_Item_Tag } {
        { "consumables" , "<font=text_16,color=bw_59>CONSUMABLES" , 2, .consumable },
        { "quest"       , "<font=text_16,color=bw_59>QUEST"       , 1, .quest },
        { "materials"   , "<font=text_16,color=bw_59>MATERIALS"   , 3, .material },
    }) {
        item_ids := app_data_item_ids_filtered_by_tag(info.item_tag, context.temp_allocator)

        section := ui.add_frame(sections, { name=info.name, layout={ dir=.down, gap=10, align=.center, auto_size=.full } })
        ui.add_frame(section, { name="header", text=info.text, flags={.terse,.terse_height,.terse_width} })

        rows := ui.add_frame(section, { layout={ dir=.down, gap=12, auto_size=.full } })
        for row_idx in 0..<info.row_count {
            row := ui.add_frame(rows, { layout={ dir=.right, gap=12, auto_size=.full } })
            for col_idx in 0..<col_count {
                item_idx := row_idx*col_count + col_idx
                item_id := item_idx < len(item_ids) ? item_ids[item_idx] : ""
                ui.add_frame(row, { size=100, name="slot_item", text=item_id, draw=draw_slot_item,
                    enter=app_tooltip_show, leave=app_tooltip_hide })
            }
        }
    }
}

app_menu_switch_page :: proc (page_name: string) {
    page_name_rule := fmt.tprintf("menu/pages/%s", page_name)
    f := app.ui->get(page_name_rule)

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
