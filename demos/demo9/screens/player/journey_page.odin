#+private
package player

import "spacelib:ui"

import "../../partials"

journey_page_tabs: [] struct { name, text, icon: string } = {
    { name="story"      , text="STORY"      , icon="images_mode" },
    { name="contract"   , text="CONTRACT"   , icon="stylus_fountain_pen" },
    { name="codex"      , text="CODEX"      , icon="auto_stories" },
    { name="tutorial"   , text="TUTORIAL"   , icon="stacks" },
}

add_journey_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "journey", "JOURNEY")

    tab_details := make([dynamic] partials.Category_Tab_Details, context.temp_allocator)
    for t in journey_page_tabs do append(&tab_details, partials.Category_Tab_Details { name=t.name, icon=t.icon })

    tabs := partials.add_category_tabs(page, "tabs", items=tab_details[:],
        click=proc (f: ^ui.Frame) {
            title := ui.get(f, "../title")
            assert(f.order >= 0 && f.order < len(journey_page_tabs))
            ui.set_text(title, journey_page_tabs[f.order].text)
            ui.update(f.parent)
        },
    )

    ui.set_order(tabs, 1)
    ui.set_anchors(tabs, { point=.top_left, offset={80,70} })

    content := ui.add_frame(page,
        { name="content" },
        { point=.top_left, rel_frame=tabs, offset={0,60} },
        { point=.bottom_right, offset={-80,-40} },
    )

    ui.print_frame_tree(page)

    add_journey_page_tutorial(content)

    ui.click(tabs, "tutorial")
}

add_journey_page_tutorial :: proc (parent: ^ui.Frame) {
    tutorial := ui.add_frame(parent,
        { name="tutorial" },
        { point=.top_left },
        { point=.bottom_right },
    )

    list := ui.add_frame(tutorial,
        { name="list", flags={.scissor}, layout={dir=.down,gap=10,scroll={step=20}} },
        { point=.top_left },
        { point=.bottom_right, rel_point=.bottom, offset={-40,0} },
    )

    partials.add_scrollbar(list)

    // TODO: add tutorial items to data package; read list from there
    for _ in 0..<20 {
        ui.add_frame(list, {
            // name="...",
            flags       = {.radio,.capture,.terse,.terse_height},
            text        = "SANDWORM DEATH",
            text_format = "<wrap,left,pad=20:16,font=text_4r,color=primary_d2>%s",
            draw        = partials.draw_tutorial_item,
        })
    }

    /*details :=*/ ui.add_frame(tutorial,
        { name="details", flags={.scissor}, layout={dir=.up_and_down,scroll={step=20}} },
        { point=.top_right },
        { point=.bottom_left, rel_point=.bottom, offset={40,0} },
    )
}
