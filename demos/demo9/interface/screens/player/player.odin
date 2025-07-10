package demo9_screens_player

import "spacelib:ui"

import "../../../data"
import "../../../events"
import "../../partials"

@private screen: ^ui.Frame

add :: proc (parent: ^ui.Frame) {
    assert(screen == nil)

    screen = ui.add_frame(parent,
        { name="player" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen_base(screen)

    partials.add_screen_footer_key_button(screen, "close", "Close", key="Esc",
        click=proc (f: ^ui.Frame) {
            events.send_open_screen("home")
        },
    )

    add_map_page()
    add_inventory_page()
    add_crafting_page()
    add_research_page()
    add_skills_page()
    add_journey_page()
    add_customization_page()

    ui.click(screen, "header_bar/tabs/inventory")
}

@private
add_map_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "map", "MAP")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>MAP PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

@private
add_inventory_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "inventory", "INVENTORY")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>INVENTORY PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

@private
add_crafting_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "crafting", "CRAFTING")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>CRAFTING PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

@private
add_research_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(screen, "research", "RESEARCH")

    tab_points := ui.get(tab, "points")
    ui.set_text(tab_points, data.player.intel_points_avail, shown=true)

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>RESEARCH PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

@private
add_skills_page :: proc () {
    tab, page := partials.add_screen_tab_and_page(screen, "skills", "SKILLS")

    tab_points := ui.get(tab, "points")
    ui.set_text(tab_points, data.player.skill_points_avail, shown=true)

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>SKILLS PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

@private
add_journey_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "journey", "JOURNEY")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>JOURNEY PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}

@private
add_customization_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "customization", "CUSTOMIZATION")

    ui.add_frame(page,
        { name="msg", text="<font=text_4l,color=primary>CUSTOMIZATION PAGE GOES HERE...", flags={.terse,.terse_height} },
        { point=.center },
    )
}
