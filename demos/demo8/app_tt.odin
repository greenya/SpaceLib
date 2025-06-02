package demo8

import "core:fmt"
import "spacelib:ui"

app_tt_create :: proc () {
    root := ui.add_frame(app.ui.root, { name="tt", order=9, flags={.pass,.hidden} }, {})

    app_tt_add_trait(root)
}

app_tt_destroy :: proc () {
}

app_tt_add_trait :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent, { name="trait", size={320,0}, layout={ dir=.down, auto_size=.dir },
        draw=draw_tt_before, draw_after=draw_tt_after,
    }, {})

    ui.add_frame(root, { name="title", flags={.terse,.terse_height}, draw=draw_tt_title,
        text_format="<font=text_24,color=bw_da>%s", text="[PH] Trait Title" })

    ui.add_frame(root, { name="subtitle", flags={.terse,.terse_height}, draw=draw_tt_subtitle,
        text_format="<font=text_18,color=bw_95>%s", text="[PH] Trait Type",
    })

    ui.add_frame(root, { name="desc", flags={.terse,.terse_height}, draw=draw_tt_desc,
        text_format="<wrap,left,font=text_18,color=bw_da>%s", text="[PH] Trait Desc",
    })

    ui.add_frame(root, { name="levels", text="[PH] Trait Levels", flags={.terse,.terse_height} })
}

app_tt_show_trait :: proc (target: ^ui.Frame) {
    trait := app.data.traits[target.text]
    root := app.ui->get("tt/trait")

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

    ui.show(root, hide_siblings=true)
}

app_tt_show :: proc (target: ^ui.Frame) {
    fmt.println(#procedure, target.name, target.text)
    app_tt_hide(target)
    if target.text == "" do return

    switch target.name {
    case "slot_trait.ex": app_tt_show_trait(target)
    }

    tt := app.ui->get("tt")
    if ui.first_visible_child(tt) != nil {
        tt.anchors[0] = { point=.top_left, rel_point=.top_right, rel_frame=target, offset={10,0} }
        ui.show(tt)
    }
}

app_tt_hide :: proc (target: ^ui.Frame) {
    fmt.println(#procedure, target.name, target.text)
    tt := app.ui->get("tt")
    if tt.anchors[0].rel_frame == target {
        ui.hide(tt)
    }
}
