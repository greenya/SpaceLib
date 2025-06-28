package demo9

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
        { point=.top_left, rel_point=.bottom_left, rel_frame=app.ui->get("bar_top") },
        { point=.bottom_right, rel_point=.top_right, rel_frame=app.ui->get("bar_bottom") },
    )

    app_menu_add_page_journey(pages)

    app.ui->click("menu/bar_top/tab_journey") // preselect some tab
}

app_menu_destroy :: proc () {
}

app_menu_add_bar_top :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="bar_top", text="bg0", size={0,80}, order=1, draw=draw_color_rect },
        { point=.top_left },
        { point=.top_right },
    )

    tabs := ui.add_frame(root,
        { name="tabs", layout={ dir=.left_and_right } },
        { point=.top_left },
        { point=.bottom_right },
    )

    for info in ([] struct { name:string, text:string } {
        { "tab_map"             , "MAP" },
        { "tab_inventory"       , "INVENTORY" },
        { "tab_crafting"        , "CRAFTING" },
        { "tab_research"        , "RESEARCH" },
        { "tab_skills"          , "SKILLS" },
        { "tab_journey"         , "JOURNEY" },
        { "tab_customization"   , "CUSTOMIZATION" },
    }) {
        ui.add_frame(tabs, {
            name        = info.name,
            text        = info.text,
            text_format = "<bottom,font=text_5l,color=pri,pad=20:10>%s",
            flags       = {.radio,.terse,.terse_width},
            draw        = draw_menu_bar_top_tab,
            click       = proc (f: ^ui.Frame) {
                switch f.name {
                case "tab_journey": app_menu_switch_page("page_journey")
                }
            },
        })
    }

    // ...
}

app_menu_add_bar_bottom :: proc (parent: ^ui.Frame) {
    ui.add_frame(parent,
        { name="bar_bottom", text="bg0", size={0,80}, order=1, draw=draw_color_rect },
        { point=.bottom_left },
        { point=.bottom_right },
    )
}

app_menu_add_page_journey :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent,
        { name="page_journey", text="bg1", draw=draw_color_rect },
        { point=.top_left },
        { point=.bottom_right },
    )

    ui.add_frame(root,
        { name="msg", text="<font=text_5l,color=acc>JOURNEY PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

app_menu_switch_page :: proc (page_name: string) {
    f := app.ui->get(page_name)

    // for child in f.parent.children {
    //     ui.end_animation(child)
    // }

    // if .hidden in f.flags {
    //     ui.animate(f, app_menu_anim_switch_page, .4)
    // }

    ui.show(f, hide_siblings=true)
}
