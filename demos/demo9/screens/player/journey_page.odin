#+private
package player

import "spacelib:ui"

import "../../data"
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

    // ui.print_frame_tree(page)

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

    for tip in data.tutorial_tips {
        ui.add_frame(list, {
            name        = tip.id,
            flags       = {.radio,.capture,.terse,.terse_height},
            text        = tip.title,
            text_format = "<wrap,left,pad=24:16,font=text_4r,color=primary_d2>%s",
            draw        = partials.draw_tutorial_item,
            click       = proc (f: ^ui.Frame) { journey_page_show_tutorial_tip(f.name) },
        })
    }

    // FIXME: ui.Frame.layout.dir: .up and .up_and_down doesn't calc correctly (if used here)

    details := ui.add_frame(tutorial,
        { name="details", flags={.scissor}, layout={dir=.down,pad=1,scroll={step=20},align=.center} },
        { point=.bottom_left, rel_point=.bottom, offset={40,0} },
        { point=.top_right },
    )

    partials.add_scrollbar(details)

    details_column := ui.add_frame(details, {
        name    = "column",
        size    = {400,0},
        layout  = {dir=.up_and_down,auto_size=.dir,gap=1},
        text    = "primary_d8",
        draw    = partials.draw_color_rect,
    })

    ui.add_frame(details_column, {
        name        = "title",
        flags       = {.terse,.terse_height},
        text        = "TITLE",
        text_format = "<wrap,left,pad=12:6,font=text_4r,color=primary_d2>%s",
        draw        = partials.draw_hexagon_rect_wide_hangout_accent,
    })

    image := partials.add_placeholder_image(details_column, ._11x5)
    ui.set_name(image, "image")

    ui.add_frame(details_column, {
        name        = "desc",
        flags       = {.terse,.terse_height},
        text        = "DESC",
        text_format = "<wrap,top,left,pad=12:10,font=text_4l,color=primary_d2>%s",
    })

    ui.hide(details)
}

journey_page_show_tutorial_tip :: proc (id: string) {
    tip := data.get_tutorial_tip(id)

    details := ui.get(screen, "pages/journey/content/tutorial/details")
    column := ui.get(details, "column")

    // title
    ui.set_text(ui.get(column, "title"), tip.title, shown=true)

    // image
    image := ui.get(column, "image")
    if tip.image != ""  do ui.show(image)
    else                do ui.hide(image)

    // desc
    desc := ui.get(column, "desc")
    tip_desc := data.get_tutorial_tip_desc(tip, context.temp_allocator)
    if tip_desc != ""   do ui.set_text(desc, tip_desc, shown=true)
    else                do ui.hide(desc)

    ui.set_scroll_offset(details, 0)
    ui.show(details)
    ui.update(details)
}
