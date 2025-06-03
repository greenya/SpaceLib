package demo8

import "core:fmt"
import "core:strings"
import "spacelib:core"
import "spacelib:ui"

app_tooltip_create :: proc () {
    root := ui.add_frame(app.ui.root, { name="tooltip", order=9, flags={.pass} })
    app_tooltip_main_add(root)
}

app_tooltip_destroy :: proc () {
}

app_tooltip_main_add :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="main", size={372,0}, flags={.hidden}, layout={ dir=.down, auto_size=.dir }, draw=draw_tooltip_bg },
        { point=.top, rel_point=.mouse, offset={0,30} },
    )

    ui.add_frame(root, { name="line_top", order=-1, text="bw_2c", size={0,4}, draw=draw_color_rect })
    ui.add_frame(root, { name="line_bottom", order=+1, text="bw_2c", size={0,4}, draw=draw_color_rect })

    ui.add_frame(root, { name="title", flags={.terse,.terse_height}, draw=draw_tooltip_title,
        text_format="<pad=16:10,wrap,font=text_24,color=bw_da>%s", text="[PH] title",
    })

    ui.add_frame(root, { name="subtitle", flags={.terse,.terse_height}, draw=draw_tooltip_subtitle,
        text_format="<pad=16:6,wrap,font=text_18,color=bw_95>%s", text="[PH] subtitle",
    })

    ui.add_frame(root, { name="image", size={0,128+16+16}, draw=draw_tooltip_image, text="[PH] image" })

    stats := ui.add_frame(root, { name="stats", size={0,72}, layout={dir=.left_and_right,gap=20}, draw=draw_tooltip_stats })
    for name in ([] string { "stat1", "stat2", "stat3", "stat4" }) {
        item := ui.add_frame(stats, { name=name, flags={.terse,.terse_width},
            text_format="<font=text_18,color=bw_95>%s\n<font=text_32,color=bw_da>%.1f",
        })
        ui.set_text(item, "[PH] stat", 777.7)
    }

    ui.add_frame(root, { name="desc", flags={.terse,.terse_height}, draw=draw_tooltip_desc,
        text_format="<pad=16:8,wrap,left,font=text_18,color=bw_6c>%s", text="[PH] desc",
    })

    ui.add_frame(root, { name="body", flags={.terse,.terse_height}, draw=draw_tooltip_body,
        text_format="<pad=16:8,wrap,left,font=text_18,color=bw_6c>%s", text="[PH] body",
    })

    ui.add_frame(root, { name="actions", flags={.terse,.terse_height}, draw=draw_tooltip_actions,
        text_format="<pad=16:6,font=text_18,color=bw_6c>%s", text="[PH] actions",
    })
}

app_tooltip_main_reset :: proc () -> (root: ^ui.Frame) {
    root = app.ui->get("tooltip/main")
    for child in root.children do if child.order == 0 do ui.hide(child)
    return
}

app_tooltip_main_ready :: proc (target: ^ui.Frame) {
    root := app.ui->get("tooltip/main")
    root.anchors[0].rel_frame = target
    ui.animate(root, app_tooltip_anim_appear, .25)
}

app_tooltip_main_set_stats :: proc (item: App_Data_Item) {
    root := app.ui->get("tooltip/main/stats")
    for child in root.children do ui.hide(child)

    set_stat :: proc (root: ^ui.Frame, t: string, v: f32) {
        for child in root.children do if .hidden in child.flags {
            ui.set_text(child, t, v, shown=true)
            return
        }
        panic("tooltip/main/stats: count overflow")
    }

    st := item.stats
    if st.armor != 0    do set_stat(root, "Armor", st.armor)
    if st.weight != 0   do set_stat(root, "Weight", st.weight)

    if ui.first_visible_child(root) != nil do ui.show(root)
}

app_tooltip_show_item :: proc (target: ^ui.Frame) {
    root := app_tooltip_main_reset()
    item := app.data.items[target.text]

    title := ui.get(root, "title")
    ui.set_text(title, item.name, shown=true)

    subtitle := ui.get(root, "subtitle")
    switch {
    case .quest in item.tags        : ui.set_text(subtitle, "Quest Item", shown=true)
    case .head_armor in item.tags   : ui.set_text(subtitle, "Helmet", shown=true)
    case .body_armor in item.tags   : ui.set_text(subtitle, "Body Armor", shown=true)
    case .leg_armor in item.tags    : ui.set_text(subtitle, "Leg Armor", shown=true)
    case .glove_armor in item.tags  : ui.set_text(subtitle, "Glove Armor", shown=true)
    case .relic in item.tags        : ui.set_text(subtitle, "Relic", shown=true)
    case .curative in item.tags     : ui.set_text(subtitle, "Curative", shown=true)
    case .consumable in item.tags   : ui.set_text(subtitle, "Consumable", shown=true)
    case .material in item.tags     : ui.set_text(subtitle, "Crafting Material", shown=true)
    }

    image := ui.get(root, "image")
    ui.set_text(image, item.icon, shown=true)

    app_tooltip_main_set_stats(item)

    desc := ui.get(root, "desc")
    if item.desc != "" do ui.set_text(desc, item.desc, shown=true)

    { // actions
        items := make([dynamic] string, context.temp_allocator)

        if .gear in item.tags       do append(&items, "<icon=key.F:1.5>  Unequip")
        if .consumable in item.tags do append(&items, "<icon=key.Spc:3:1.5>  Use")
                                       append(&items, "<icon=key.RMB:3:1.5>  Inspect")

        actions := ui.get(root, "actions")
        ui.set_text(actions, strings.join(items[:], "        ", context.temp_allocator), shown=true)
    }

    app_tooltip_main_ready(target)
}

app_tooltip_show_skill :: proc (target: ^ui.Frame) {
    root := app_tooltip_main_reset()
    skill := app.data.skills[target.text]

    title := ui.get(root, "title")
    ui.set_text(title, skill.name, shown=true)

    subtitle := ui.get(root, "subtitle")
    ui.set_text(subtitle, "Archetype Skill", shown=true)

    image := ui.get(root, "image")
    ui.set_text(image, skill.icon, shown=true)

    desc := ui.get(root, "desc")
    ui.set_text(desc, skill.desc, shown=true)

    actions := ui.get(root, "actions")
    if !skill.selected do ui.set_text(actions, "<icon=key.Spc:3:1.5>  Select", shown=true)

    app_tooltip_main_ready(target)
}

app_tooltip_show_trait :: proc (target: ^ui.Frame) {
    root := app_tooltip_main_reset()
    trait := app.data.traits[target.text]

    title := ui.get(root, "title")
    ui.set_text(title, trait.name, shown=true)

    subtitle := ui.get(root, "subtitle")
    #partial switch trait.type {
    case .none  : ui.set_text(subtitle, "Trait", shown=true)
    case .core  : ui.set_text(subtitle, "Core Trait", shown=true)
    case        : ui.set_text(subtitle, "Archetype Trait", shown=true)
    }

    desc := ui.get(root, "desc")
    ui.set_text(desc, trait->desc(context.temp_allocator), shown=true)

    { // levels
        sb := strings.builder_make(context.temp_allocator)
        for lv in 1..=max_trait_levels {
            lv_current := lv == trait.levels_granted + trait.levels_bought
            lv_desc := trait->level_desc(lv, context.temp_allocator)

            if lv_current   do strings.write_string(&sb, "<color=bw_da>")
            if lv > 1       do strings.write_rune(&sb, '\n')
                               strings.write_string(&sb, lv_desc)
            if lv_current   do strings.write_string(&sb, "</color>")
        }

        body := ui.get(root, "body")
        ui.set_text(body, strings.to_string(sb), shown=true)
    }

    app_tooltip_main_ready(target)
}

app_tooltip_show :: proc (target: ^ui.Frame) {
    // fmt.println(#procedure, target.name, target.text)
    if target.text == "" do return

    switch target.name {
    case "slot_item"    : fallthrough
    case "slot_gear"    : app_tooltip_show_item(target)
    case "slot_skill"   : app_tooltip_show_skill(target)
    case "slot_trait"   : app_tooltip_show_trait(target)
    case                : fmt.panicf("Unexpected tooltip target: %s", target.name)
    }
}

app_tooltip_hide :: proc (target: ^ui.Frame) {
    // fmt.println(#procedure, target.name, target.text)
    tooltip := app.ui->get("tooltip")
    view := ui.first_visible_child(tooltip)
    if view != nil && view.anchors[0].rel_frame == target {
        ui.animate(view, app_tooltip_anim_disappear, .15)
    }
}

app_tooltip_anim_appear :: proc (f: ^ui.Frame) {
    ui.set_opacity(f, f.anim.ratio)
    f.offset = { 0, 40 * (1 - core.ease_ratio(f.anim.ratio, .Cubic_Out)) }
    if f.anim.ratio == 0 do ui.show(f, hide_siblings=true)
}

app_tooltip_anim_disappear :: proc (f: ^ui.Frame) {
    ui.set_opacity(f, 1-f.anim.ratio)
    f.offset = { 0, 40 * core.ease_ratio(f.anim.ratio, .Cubic_In) }
    if f.anim.ratio == 1 do ui.hide(f)
}
