package demo9_screens_player

import "core:fmt"

import "spacelib:ui"

import "../../data"
import "../../partials"

_ :: fmt

root: ^ui.Frame

create :: proc (parent: ^ui.Frame) {
    assert(root == nil)
    root = ui.add_frame(parent,
        { name="player" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen(root)

    add_map_page()
    add_inventory_page()
    add_crafting_page()
    add_research_page()
    add_skills_page()
    add_journey_page()
    add_customization_page()
}

add_map_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(root, "tab_map", "MAP", "page_map")
    tab.click = proc (f: ^ui.Frame) { switch_page("page_map") }

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>MAP PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_inventory_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(root, "tab_inventory", "INVENTORY", "page_inventory")
    tab.click = proc (f: ^ui.Frame) { switch_page("page_inventory") }

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>INVENTORY PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_crafting_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(root, "tab_crafting", "CRAFTING", "page_crafting")
    tab.click = proc (f: ^ui.Frame) { switch_page("page_crafting") }

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>CRAFTING PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_research_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(root, "tab_research", "RESEARCH", "page_research")
    tab.click = proc (f: ^ui.Frame) { switch_page("page_research") }

    tab_points := ui.get(tab, "points")
    ui.set_text(tab_points, data.player.research_points_avail, shown=true)

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>RESEARCH PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_skills_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(root, "tab_skills", "SKILLS", "page_skills")
    tab.click = proc (f: ^ui.Frame) { switch_page("page_skills") }

    tab_points := ui.get(tab, "points")
    ui.set_text(tab_points, data.player.skill_points_avail, shown=true)

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>SKILLS PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_journey_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(root, "tab_journey", "JOURNEY", "page_journey")
    tab.click = proc (f: ^ui.Frame) { switch_page("page_journey") }

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>JOURNEY PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_customization_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(root, "tab_customization", "CUSTOMIZATION", "page_customization")
    tab.click = proc (f: ^ui.Frame) { switch_page("page_customization") }

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>CUSTOMIZATION PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

switch_page :: proc (page_name: string) {
    f := ui.get(root, page_name)
    ui.show(f, hide_siblings=true)
}

/*add_header_bar :: proc () {
    header_bar := ui.add_frame(root,
        { name="header_bar", text="bg0", size={0,80}, order=1, draw=draw_color_rect },
        { point=.top_left },
        { point=.top_right },
    )

    tabs := ui.add_frame(header_bar,
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
            flags       = {.no_capture,.radio,.terse,.terse_width},
            draw        = draw_screen_tab,
            click       = proc (f: ^ui.Frame) {
                switch f.name {
                case "tab_journey": switch_page("page_journey")
                }

                {
                    unspent_points := ui.get(root, "header_bar/tab_research/unspent_points")
                    anim_fade_start(unspent_points, f.name != "tab_research")
                }

                {
                    unspent_points := ui.get(root, "header_bar/tab_skills/unspent_points")
                    anim_fade_start(unspent_points, f.name != "tab_skills")
                }
            },
        })

        if tab.name == "tab_research" || tab.name == "tab_skills" {
            add_header_bar_tab_unspent_points(tab)
        }
    }

    ui.add_frame(header_bar,
        { name="nav_left", text="<pad=6,font=text_5l,icon=key/Q>", flags={.terse,.terse_width,.terse_height}, draw=draw_button },
        { point=.right, rel_point=.left, rel_frame=tabs.children[0], offset={-12,12} },
    )

    ui.add_frame(header_bar,
        { name="nav_right", text="<pad=6,font=text_5l,icon=key/E>", flags={.terse,.terse_width,.terse_height}, draw=draw_button },
        { point=.left, rel_point=.right, rel_frame=slice.last(tabs.children[:]), offset={12,12} },
    )

    update_header_bar()
}

add_header_bar_tab_unspent_points :: proc (parent: ^ui.Frame) {
    ui.add_frame(parent, {
        name        = "unspent_points",
        text_format = "<font=text_5l,color=bg0,pad=6:0>%i",
        size_min    = {32,0},
        flags       = {.pass,.terse,.terse_width,.terse_height},
        draw        = draw_screen_tab_unspent_points,
    }, { point=.center, rel_point=.bottom, offset={0,6} })
}

add_footer_bar :: proc () {
    ui.add_frame(root,
        { name="footer_bar", text="bg0", size={0,80}, order=1, draw=draw_color_rect },
        { point=.bottom_left },
        { point=.bottom_right },
    )
}

add_page_journey :: proc (parent: ^ui.Frame) {
    page_journey := ui.add_frame(parent,
        { name="page_journey", text="bg1", draw=draw_color_rect },
        { point=.top_left },
        { point=.bottom_right },
    )

    ui.add_frame(page_journey,
        { name="msg", text="<font=text_5l,color=acc>JOURNEY PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

switch_page :: proc (page_name: string) {
    f := ui.get(root, page_name)
    ui.show(f, hide_siblings=true)
}

update_header_bar :: proc () {
    { // update unspent research points
        frame := ui.get(root, "tab_research/unspent_points")
        if data.player.research_points_avail > 0 {
            ui.set_text(frame, data.player.research_points_avail, shown=true)
        } else {
            ui.hide(frame)
        }
    }
    { // update unspent skill points
        frame := ui.get(root, "tab_skills/unspent_points")
        if data.player.skill_points_avail > 0 {
            ui.set_text(frame, data.player.skill_points_avail, shown=true)
        } else {
            ui.hide(frame)
        }
    }
}

anim_fade_start :: proc (f: ^ui.Frame, show: bool) {
    if show {
        if f.opacity < 1 do ui.animate(f, anim_fade_in, .3)
    } else {
        if f.opacity > 0 do ui.animate(f, anim_fade_out, .3)
    }
}

anim_fade_out :: proc (f: ^ui.Frame) {
    ratio := core.ease_ratio(f.anim.ratio, .Cubic_Out)
    ui.set_opacity(f, 1-ratio)
    f.offset.y = ratio*10
}

anim_fade_in :: proc (f: ^ui.Frame) {
    ratio := core.ease_ratio(f.anim.ratio, .Cubic_Out)
    ui.set_opacity(f, ratio)
    f.offset.y = (1-ratio)*10
}*/
