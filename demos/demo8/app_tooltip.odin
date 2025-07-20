package demo8

import "core:fmt"
import "core:strings"
import "spacelib:core"
import "spacelib:ui"

app_tooltip_create :: proc () {
    root := ui.add_frame(app.ui.root,
        { name="tooltip", order=9, flags={.hidden,.pass}, size={384,0},
            layout=ui.Flow{ dir=.down, auto_size=.dir }, draw=draw_tooltip_bg },
        { rel_point=.mouse },
    )

    ui.add_frame(root, { name="line_top", order=-1, text="bw_2c", size={0,4}, draw=draw_color_rect })
    ui.add_frame(root, { name="line_bottom", order=+1, text="bw_2c", size={0,4}, draw=draw_color_rect })

    ui.add_frame(root, { name="title", flags={.terse,.terse_height}, draw=draw_tooltip_title,
        text_format="<pad=16:12,wrap,font=text_24,color=bw_da>%s", text="[PH] title",
    })

    ui.add_frame(root, { name="subtitle", flags={.terse,.terse_height}, draw=draw_tooltip_subtitle,
        text_format="<pad=16:6,wrap,font=text_18,color=bw_95>%s", text="[PH] subtitle",
    })

    ui.add_frame(root, { name="image", size={0,128+16+16}, draw=draw_tooltip_image, text="[PH] image" })

    stats := ui.add_frame(root, { name="stats", size={0,72}, layout=ui.Flow{dir=.left_and_right,gap=20}, draw=draw_tooltip_stats })
    for name in ([] string { "stat1", "stat2", "stat3", "stat4" }) {
        item := ui.add_frame(stats, { name=name, flags={.terse,.terse_width},
            text_format="<font=text_18,color=bw_95>%s\n<font=text_32,color=bw_da>%.1f",
        })
        ui.set_text(item, "[PH] stat", 777.7)
    }

    resists := ui.add_frame(root, { name="resists", size={0,80},
        layout=ui.Flow{dir=.left_and_right,size={40,64},gap=4,align=.center}, draw=draw_tooltip_resists })

    for name in ([] string { "bleed", "fire", "lightning", "poison", "blight" }) {
        ui.add_frame(resists, { name=name, text="??", draw=draw_tooltip_resists_item })
    }

    ui.add_frame(root, { name="desc", flags={.terse,.terse_height}, draw=draw_tooltip_desc,
        text_format="<pad=16:10,wrap,left,font=text_18,color=bw_6c>%s", text="[PH] desc",
    })

    ui.add_frame(root, { name="body", flags={.terse,.terse_height}, draw=draw_tooltip_body,
        text_format="<pad=16:8,wrap,left,font=text_18,color=bw_6c>%s", text="[PH] body",
    })

    ui.add_frame(root, { name="actions", flags={.terse,.terse_height}, draw=draw_tooltip_actions,
        text_format="<pad=16:6,font=text_18,color=bw_6c>%s", text="[PH] actions",
    })
}

app_tooltip_destroy :: proc () {
}

app_tooltip_reset :: proc () -> (tooltip: ^ui.Frame) {
    tooltip = app.ui->get("tooltip")
    for child in tooltip.children do if child.order == 0 do ui.hide(child)
    return
}

app_tooltip_ready :: proc (tooltip, target: ^ui.Frame) {
    tooltip.anchors[0].rel_frame = target
    ui.animate(tooltip, app_tooltip_anim_appear, .25)
}

app_tooltip_set_stats :: proc (tooltip: ^ui.Frame, item: App_Data_Item) {
    stats := ui.get(tooltip, "stats")
    for child in stats.children do ui.hide(child)

    set_stat :: proc (root: ^ui.Frame, t: string, v: f32) {
        for child in root.children do if .hidden in child.flags {
            ui.set_text(child, t, v, shown=true)
            return
        }
        panic("[tooltip] Stats children overflow")
    }

    st := item.stats
    if st.armor != 0    do set_stat(stats, "Armor", st.armor)
    if st.weight != 0   do set_stat(stats, "Weight", st.weight)

    if ui.first_visible_child(stats) != nil do ui.show(stats)
}

app_tooltip_set_resists :: proc (tooltip: ^ui.Frame, item: App_Data_Item) {
    st := item.stats
    if st.res_bleed==0 && st.res_fire==0 && st.res_lightning==0 && st.res_poison==0 && st.res_blight==0 do return

    resists := ui.get(tooltip, "resists")

    ui.set_text(ui.get(resists, "bleed"),       fmt.tprint(st.res_bleed))
    ui.set_text(ui.get(resists, "fire"),        fmt.tprint(st.res_fire))
    ui.set_text(ui.get(resists, "lightning"),   fmt.tprint(st.res_lightning))
    ui.set_text(ui.get(resists, "poison"),      fmt.tprint(st.res_poison))
    ui.set_text(ui.get(resists, "blight"),      fmt.tprint(st.res_blight))

    ui.show(resists)
}

app_tooltip_show_item :: proc (tooltip, target: ^ui.Frame) {
    item := app.data.items[target.text]

    title := ui.get(tooltip, "title")
    ui.set_text(title, item.name, shown=true)

    subtitle := ui.get(tooltip, "subtitle")
    switch {
    case .quest in item.tags        : ui.set_text(subtitle, "Quest Item", shown=true)
    case .curative in item.tags     : ui.set_text(subtitle, "Curative", shown=true)
    case .consumable in item.tags   : ui.set_text(subtitle, "Consumable", shown=true)
    case .material in item.tags     : ui.set_text(subtitle, "Crafting Material", shown=true)
    case .head_armor in item.tags   : ui.set_text(subtitle, "Helmet", shown=true)
    case .body_armor in item.tags   : ui.set_text(subtitle, "Body Armor", shown=true)
    case .leg_armor in item.tags    : ui.set_text(subtitle, "Leg Armor", shown=true)
    case .glove_armor in item.tags  : ui.set_text(subtitle, "Glove Armor", shown=true)
    case .relic in item.tags        : ui.set_text(subtitle, "Relic", shown=true)
    case .amulet in item.tags       : ui.set_text(subtitle, "Amulet", shown=true)
    case .ring in item.tags         : ui.set_text(subtitle, "Ring", shown=true)
    }

    image := ui.get(tooltip, "image")
    ui.set_text(image, item.icon, shown=true)

    app_tooltip_set_stats(tooltip, item)
    app_tooltip_set_resists(tooltip, item)

    desc := ui.get(tooltip, "desc")
    if item.desc != "" do ui.set_text(desc, item.desc, shown=true)

    { // actions
        items := make([dynamic] string, context.temp_allocator)

        if .gear in item.tags       do append(&items, "<icon=key.F:1.5>  Unequip")
        if .consumable in item.tags do append(&items, "<icon=key.Spc:3:1.5>  Use")
                                       append(&items, "<icon=key.RMB:3:1.5>  Inspect")

        actions := ui.get(tooltip, "actions")
        ui.set_text(actions, strings.join(items[:], "        ", context.temp_allocator), shown=true)
    }
}

app_tooltip_show_skill :: proc (tooltip, target: ^ui.Frame) {
    skill := app.data.skills[target.text]

    title := ui.get(tooltip, "title")
    ui.set_text(title, skill.name, shown=true)

    subtitle := ui.get(tooltip, "subtitle")
    ui.set_text(subtitle, "Archetype Skill", shown=true)

    image := ui.get(tooltip, "image")
    ui.set_text(image, skill.icon, shown=true)

    desc := ui.get(tooltip, "desc")
    ui.set_text(desc, skill.desc, shown=true)

    actions := ui.get(tooltip, "actions")
    if !skill.selected do ui.set_text(actions, "<icon=key.Spc:3:1.5>  Select", shown=true)
}

app_tooltip_show_trait :: proc (tooltip, target: ^ui.Frame) {
    trait := app.data.traits[target.text]

    title := ui.get(tooltip, "title")
    ui.set_text(title, trait.name, shown=true)

    subtitle := ui.get(tooltip, "subtitle")
    #partial switch trait.type {
    case .none  : ui.set_text(subtitle, "Trait", shown=true)
    case .core  : ui.set_text(subtitle, "Core Trait", shown=true)
    case        : ui.set_text(subtitle, "Archetype Trait", shown=true)
    }

    desc := ui.get(tooltip, "desc")
    ui.set_text(desc, trait->desc(context.temp_allocator), shown=true)

    { // levels
        sb := strings.builder_make(context.temp_allocator)
        for lv in 1..=max_trait_levels {
            lv_current := lv == trait.levels_granted + trait.levels_bought
            lv_desc := trait->level_desc(lv, context.temp_allocator)

            if lv_current   do strings.write_string(&sb, "<color=bw_da>")
            if lv > 1       do strings.write_rune(&sb, '\n')
                               strings.write_string(&sb, "<gap=.3>")
                               strings.write_string(&sb, lv_desc)
            if lv_current   do strings.write_string(&sb, "</color>")
        }

        body := ui.get(tooltip, "body")
        ui.set_text(body, strings.to_string(sb), shown=true)
    }
}

app_tooltip_show :: proc (target: ^ui.Frame) {
    // fmt.println(#procedure, target.name, target.text)
    if target.name == "" || target.text == "" do return

    tooltip := app_tooltip_reset()

    switch target.name {
    case "slot_item"    : fallthrough
    case "slot_gear"    : app_tooltip_show_item(tooltip, target)
    case "slot_skill"   : app_tooltip_show_skill(tooltip, target)
    case "slot_trait"   : app_tooltip_show_trait(tooltip, target)
    case                : fmt.panicf("[tooltip] Unexpected target: %s", target.name)
    }

    app_tooltip_ready(tooltip, target)
}

app_tooltip_hide :: proc (target: ^ui.Frame) {
    // fmt.println(#procedure, target.name, target.text)
    tooltip := app.ui->get("tooltip")
    if tooltip.anchors[0].rel_frame == target {
        ui.animate(tooltip, app_tooltip_anim_disappear, .15)
    }
}

app_tooltip_anim_appear :: proc (f: ^ui.Frame) {
    ui.set_opacity(f, f.anim.ratio)
    f.offset = { 0, 40 * (1 - core.ease_ratio(f.anim.ratio, .Cubic_Out)) }
    if f.anim.ratio == 0 {
        ui.show(f)
        app_tooltip_update_anchor(f)
    }
}

app_tooltip_anim_disappear :: proc (f: ^ui.Frame) {
    ui.set_opacity(f, 1-f.anim.ratio)
    f.offset = { 0, 40 * core.ease_ratio(f.anim.ratio, .Cubic_In) }
    if f.anim.ratio == 1 do ui.hide(f)
}

app_tooltip_update_anchor :: proc (f: ^ui.Frame) {
    gap :: 32
    ms_pos := f.ui.mouse.pos
    sc_w, sc_h := f.ui.root.rect.w, f.ui.root.rect.h
    tt_w, tt_h := f.rect.w, f.rect.h

    if ms_pos.y+tt_h+gap > sc_h {
        if ms_pos.x < sc_w/2 {
            f.anchors[0].point = .left
            f.anchors[0].offset = {30,0}
        } else {
            f.anchors[0].point = .right
            f.anchors[0].offset = {-30,0}
        }
    } else {
        if ms_pos.x+tt_w/2+gap > sc_w {
            f.anchors[0].point = .right
            f.anchors[0].offset = {-30,0}
        } else if ms_pos.x-tt_w/2-gap < 0 {
            f.anchors[0].point = .left
            f.anchors[0].offset = {30,0}
        } else {
            f.anchors[0].point = .top
            f.anchors[0].offset = {0,30}
        }
    }

    ui.update(f)
}
