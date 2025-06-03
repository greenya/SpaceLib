package demo8

import "core:fmt"
import "core:strings"
import "spacelib:core"
import "spacelib:ui"

app_tooltip_create :: proc () {
    root := ui.add_frame(app.ui.root, { name="tooltip", order=9, flags={.pass} })

    app_tooltip_add_trait(root)
    app_tooltip_add_item(root)

    for child in root.children do ui.hide(child)
}

app_tooltip_destroy :: proc () {
}

app_tooltip_add_trait :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="trait", size={360,0}, layout={ dir=.down, auto_size=.dir }, draw=draw_tooltip_bg },
        { point=.top, rel_point=.mouse, offset={0,30} },
    )

    ui.add_frame(root, { name="border_top", order=-1, text="bw_2c", size={0,4}, draw=draw_color_rect })
    ui.add_frame(root, { name="border_bottom", order=+1, text="bw_2c", size={0,4}, draw=draw_color_rect })

    ui.add_frame(root, { name="title", flags={.terse,.terse_height}, draw=draw_tooltip_title,
        text_format="<pad=20:10,wrap,font=text_24,color=bw_da>%s", text="[PH] Trait Title",
    })

    ui.add_frame(root, { name="subtitle", flags={.terse,.terse_height}, draw=draw_tooltip_subtitle,
        text_format="<pad=20:6,wrap,font=text_18,color=bw_95>%s", text="[PH] Trait Type",
    })

    ui.add_frame(root, { name="desc", flags={.terse,.terse_height}, draw=draw_tooltip_desc,
        text_format="<pad=20:8,wrap,left,font=text_18,color=bw_da>%s", text="[PH] Trait Desc",
    })

    ui.add_frame(root, { name="levels", flags={.terse,.terse_height}, draw=draw_tooltip_body,
        text_format="<pad=20:8,wrap,left,font=text_18,color=bw_6c>%s", text="[PH] Trait Levels",
    })
}

app_tooltip_show_trait :: proc (target: ^ui.Frame) {
    root := app.ui->get("tooltip/trait")
    trait := app.data.traits[target.text]

    title := ui.get(root, "title")
    ui.set_text(title, trait.name)

    subtitle := ui.get(root, "subtitle")
    #partial switch trait.type {
    case .none  : ui.set_text(subtitle, "Trait")
    case .core  : ui.set_text(subtitle, "Core Trait")
    case        : ui.set_text(subtitle, "Archetype Trait")
    }

    desc := ui.get(root, "desc")
    ui.set_text(desc, trait->desc(context.temp_allocator))

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

        levels := ui.get(root, "levels")
        ui.set_text(levels, strings.to_string(sb))
    }

    root.anchors[0].rel_frame = target
    ui.animate(root, app_tooltip_anim_appear, .25)
}

app_tooltip_add_item :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="item", size={360,0}, layout={ dir=.down, auto_size=.dir }, draw=draw_tooltip_bg },
        { point=.top, rel_point=.mouse, offset={0,30} },
    )

    ui.add_frame(root, { name="border_top", order=-1, text="bw_2c", size={0,4}, draw=draw_color_rect })
    ui.add_frame(root, { name="border_bottom", order=+1, text="bw_2c", size={0,4}, draw=draw_color_rect })

    ui.add_frame(root, { name="title", flags={.terse,.terse_height}, draw=draw_tooltip_title,
        text_format="<pad=20:10,wrap,font=text_24,color=bw_da>%s", text="[PH] Item Title",
    })

    ui.add_frame(root, { name="subtitle", flags={.terse,.terse_height}, draw=draw_tooltip_subtitle,
        text_format="<pad=20:6,wrap,font=text_18,color=bw_95>%s", text="[PH] Item Type",
    })

    ui.add_frame(root, { name="image", size={0,128+16+16}, draw=draw_tooltip_image, text="[PH] Image" })

    ui.add_frame(root, { name="desc", flags={.terse,.terse_height}, draw=draw_tooltip_desc,
        text_format="<pad=20:8,wrap,left,font=text_18,color=bw_6c>%s", text="[PH] Item Desc",
    })

    ui.add_frame(root, { name="keys", flags={.terse,.terse_height}, draw=draw_tooltip_keys,
        text_format="<pad=20:6,font=text_18,color=bw_6c>%s", text="[PH] Keys",
    })
}

app_tooltip_show_item :: proc (target: ^ui.Frame) {
    root := app.ui->get("tooltip/item")
    item := app.data.items[target.text]

    title := ui.get(root, "title")
    ui.set_text(title, item.name)

    subtitle := ui.get(root, "subtitle")
    subtitle_text := "???"
    if .consumable in item.tags do subtitle_text = "Consumable"
    if .curative in item.tags   do subtitle_text = "Curative"
    if .material in item.tags   do subtitle_text = "Crafting Material"
    if .quest in item.tags      do subtitle_text = "Quest Item"
    ui.set_text(subtitle, subtitle_text)

    image := ui.get(root, "image")
    ui.set_text(image, item.icon)

    desc := ui.get(root, "desc")
    if item.desc != "" {
        ui.show(desc)
        ui.set_text(desc, item.desc)
    } else {
        ui.hide(desc)
    }

    { // keys
        items := make([dynamic] string, context.temp_allocator)

        if .consumable in item.tags do  append(&items, "<icon=key.Spc:3:1.5>  Use")
                                        append(&items, "<icon=key.RMB:3:1.5>  Inspect")

        keys := ui.get(root, "keys")
        ui.set_text(keys, strings.join(items[:], "        ", context.temp_allocator))
    }

    root.anchors[0].rel_frame = target
    ui.animate(root, app_tooltip_anim_appear, .25)
}

app_tooltip_show :: proc (target: ^ui.Frame) {
    // fmt.println(#procedure, target.name, target.text)
    if target.text == "" do return

    switch target.name {
    case "slot_trait.ex": app_tooltip_show_trait(target)
    case "slot_item"    : app_tooltip_show_item(target)
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
