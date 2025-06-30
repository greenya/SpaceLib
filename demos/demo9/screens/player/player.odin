package demo9_screens_player

import "spacelib:ui"

import "../../data"
import "../../partials"

add_to :: proc (parent: ^ui.Frame) {
    screen := ui.add_frame(parent,
        { name="player" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen_base(screen)

    add_map_page(screen)
    add_inventory_page(screen)
    add_crafting_page(screen)
    add_research_page(screen)
    add_skills_page(screen)
    add_journey_page(screen)
    add_customization_page(screen)

    ui.click(screen, "header_bar/tabs/inventory")
}

add_map_page :: proc (screen: ^ui.Frame) {
    _, page := partials.add_screen_tab_and_page(screen, "map", "MAP")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>MAP PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_inventory_page :: proc (screen: ^ui.Frame) {
    _, page := partials.add_screen_tab_and_page(screen, "inventory", "INVENTORY")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>INVENTORY PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_crafting_page :: proc (screen: ^ui.Frame) {
    _, page := partials.add_screen_tab_and_page(screen, "crafting", "CRAFTING")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>CRAFTING PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_research_page :: proc (screen: ^ui.Frame) {
    tab, page := partials.add_screen_tab_and_page(screen, "research", "RESEARCH")

    tab_points := ui.get(tab, "points")
    ui.set_text(tab_points, data.player.research_points_avail, shown=true)

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>RESEARCH PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_skills_page :: proc (screen: ^ui.Frame) {
    tab, page := partials.add_screen_tab_and_page(screen, "skills", "SKILLS")

    tab_points := ui.get(tab, "points")
    ui.set_text(tab_points, data.player.skill_points_avail, shown=true)

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>SKILLS PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_journey_page :: proc (screen: ^ui.Frame) {
    _, page := partials.add_screen_tab_and_page(screen, "journey", "JOURNEY")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>JOURNEY PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

add_customization_page :: proc (screen: ^ui.Frame) {
    _, page := partials.add_screen_tab_and_page(screen, "customization", "CUSTOMIZATION")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>CUSTOMIZATION PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}
