package demo8

import "core:fmt"
import "core:strings"
import "spacelib:ui"

app_tooltip_create :: proc () {
    root := ui.add_frame(app.ui.root, { name="tooltip", order=9, flags={.pass,.hidden} }, {})

    app_tooltip_add_trait(root)
}

app_tooltip_destroy :: proc () {
}

app_tooltip_add_trait :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent, { name="trait", size={320,0}, layout={ dir=.down, auto_size=.dir },
        draw=draw_tooltip_before, draw_after=draw_tooltip_after,
    }, {})

    ui.add_frame(root, { name="title", flags={.terse,.terse_height}, draw=draw_tooltip_title,
        text_format="<font=text_24,color=bw_da>%s", text="[PH] Trait Title" })

    ui.add_frame(root, { name="subtitle", flags={.terse,.terse_height}, draw=draw_tooltip_subtitle,
        text_format="<font=text_18,color=bw_95>%s", text="[PH] Trait Type",
    })

    ui.add_frame(root, { name="desc", flags={.terse,.terse_height}, draw=draw_tooltip_desc,
        text_format="<wrap,left,font=text_18,color=bw_da>%s", text="[PH] Trait Desc",
    })

    ui.add_frame(root, { name="levels", flags={.terse,.terse_height}, draw=draw_tooltip_body,
        text_format="<left,font=text_18,color=bw_6c>%s", text="[PH] Trait Levels",
    })
}

app_tooltip_show_trait :: proc (target: ^ui.Frame) {
    trait := app.data.traits[target.text]
    root := app.ui->get("tooltip/trait")

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

    {
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

    ui.show(root, hide_siblings=true)
}

app_tooltip_show :: proc (target: ^ui.Frame) {
    fmt.println(#procedure, target.name, target.text)
    app_tooltip_hide(target)
    if target.text == "" do return

    switch target.name {
    case "slot_trait.ex": app_tooltip_show_trait(target)
    }

    tooltip := app.ui->get("tooltip")
    if ui.first_visible_child(tooltip) != nil {
        tooltip.anchors[0] = { point=.top_left, rel_point=.top_right, rel_frame=target, offset={10,0} }
        ui.show(tooltip)
    }
}

app_tooltip_hide :: proc (target: ^ui.Frame) {
    fmt.println(#procedure, target.name, target.text)
    tooltip := app.ui->get("tooltip")
    if tooltip.anchors[0].rel_frame == target {
        ui.hide(tooltip)
    }
}
