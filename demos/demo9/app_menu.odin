package demo9

import "core:slice"
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
        tab := ui.add_frame(tabs, {
            name        = info.name,
            text        = info.text,
            text_format = "<bottom,font=text_5l,pad=20:10>%s",
            flags       = {.radio,.terse,.terse_width},
            draw        = draw_menu_bar_top_tab,
            click       = proc (f: ^ui.Frame) {
                switch f.name {
                case "tab_journey": app_menu_switch_page("page_journey")
                }
            },
        })

        if tab.name == "tab_research" || tab.name == "tab_skills" {
            app_menu_add_bar_top_tab_unspent_points(tab)
        }
    }

    ui.add_frame(root,
        { name="nav_left", text="<pad=6,font=text_5l,icon=key/Q>", flags={.terse,.terse_width,.terse_height}, draw=draw_menu_bar_action_button },
        { point=.right, rel_point=.left, rel_frame=tabs.children[0], offset={-12,12} },
    )

    ui.add_frame(root,
        { name="nav_right", text="<pad=6,font=text_5l,icon=key/E>", flags={.terse,.terse_width,.terse_height}, draw=draw_menu_bar_action_button },
        { point=.left, rel_point=.right, rel_frame=slice.last(tabs.children[:]), offset={12,12} },
    )

    app_menu_update_bar_top()
}

app_menu_add_bar_top_tab_unspent_points :: proc (parent: ^ui.Frame) {
    root := ui.add_frame(parent, {
        name        = "unspent_points",
        text_format = "<font=text_5l,color=bg0,pad=6:0>%i",
        size_min    = {32,0},
        flags       = {.pass,.terse,.terse_width,.terse_height},
        draw        = draw_menu_bar_top_tab_unspent_points,
    }, { point=.center, rel_point=.bottom, offset={0,6} })
    ui.set_text(root, 777)
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
    ui.show(f, hide_siblings=true)
}

app_menu_update_bar_top :: proc () {
    { // update unspent research points
        frame := ui.get(app.ui.root, "tab_research/unspent_points")
        if app.data.player.research_points_avail > 0 {
            ui.set_text(frame, app.data.player.research_points_avail, shown=true)
        } else {
            ui.hide(frame)
        }
    }
    { // update unspent skill points
        frame := ui.get(app.ui.root, "tab_skills/unspent_points")
        if app.data.player.skill_points_avail > 0 {
            ui.set_text(frame, app.data.player.skill_points_avail, shown=true)
        } else {
            ui.hide(frame)
        }
    }
}
