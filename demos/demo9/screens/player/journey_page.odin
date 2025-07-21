#+private
package player

import "core:fmt"

import "spacelib:ui"

import "../../data"
import "../../partials"

journey_page: ^ui.Frame

journey_page_tabs: [] struct { name, text, icon: string, add: proc (parent: ^ui.Frame) } = {
    { name="story"      , text="STORY"      , icon="images_mode"            , add=add_journey_page_story },
    { name="contract"   , text="CONTRACT"   , icon="stylus_fountain_pen"    , add=add_journey_page_contract },
    { name="codex"      , text="CODEX"      , icon="auto_stories"           , add=add_journey_page_codex },
    { name="tutorial"   , text="TUTORIAL"   , icon="stacks"                 , add=add_journey_page_tutorial },
}

add_journey_page :: proc () {
    _, journey_page = partials.add_screen_tab_and_page(screen, "journey", "JOURNEY")

    tab_details := make([dynamic] partials.Category_Tab_Details, context.temp_allocator)
    for t in journey_page_tabs do append(&tab_details, partials.Category_Tab_Details { name=t.name, icon=t.icon })

    tabs := partials.add_category_tabs(journey_page, "tabs", items=tab_details[:],
        click=proc (f: ^ui.Frame) {
            title := ui.get(f, "../title")
            assert(f.order >= 0 && f.order < len(journey_page_tabs))
            ui.set_text(title, journey_page_tabs[f.order].text)

            content := ui.get(f, "../../content")
            ui.show(content, f.name, hide_siblings=true)

            ui.update(journey_page)
        },
    )

    ui.set_order(tabs, 1)
    ui.set_anchors(tabs, { point=.top_left, offset={80,70} })

    content := ui.add_frame(journey_page,
        { name="content" },
        { point=.top_left, rel_frame=tabs, offset={0,60} },
        { point=.bottom_right, offset={-80,-40} },
    )

    for t in journey_page_tabs do t.add(content)

    // ui.print_frame_tree(journey_page, max_depth=2)

    ui.click(tabs, "codex")
}

add_journey_page_story :: proc (parent: ^ui.Frame) {
    story := ui.add_frame(parent,
        { name="story" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_placeholder_note(story, "STORY SECTION GOES HERE...")
}

add_journey_page_contract :: proc (parent: ^ui.Frame) {
    contract := ui.add_frame(parent,
        { name="contract" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_placeholder_note(contract, "CONTRACT SECTION GOES HERE...")
}

codex_page: ^ui.Frame

add_journey_page_codex :: proc (parent: ^ui.Frame) {
    page, list, details := partials.add_screen_page_body_with_list_and_details(
        parent, "codex", with_details_header=true, details_header_icon="auto_stories",
    )

    codex_page = page

    for data_section in data.codex {
        section := ui.add_frame(list, {
            name        = data_section.id,
            size        = {0,200},
            flags       = {.check,.terse},
            text_format = "<wrap,top,left,pad=24:16,font=text_4m,color=primary_l3>%s\n<gap=.2,font=text_4r,color=primary_d3>%s",
            draw        = partials.draw_codex_section_item,
            click       = proc (f: ^ui.Frame) {
                topics := ui.next_sibling(f)
                assert(topics != nil && topics.name == "topics")
                if f.selected   do ui.show(topics)
                else            do ui.hide(topics)
            },
        })

        finished_topics, total_topics := data.get_codex_section_stats(data_section)
        ui.set_text(section, data_section.title, fmt.tprintf("%i/%i", finished_topics, total_topics))

        topics := ui.add_frame(list, {
            name    = "topics",
            flags   = {.hidden},
            layout  = ui.Grid { dir=.right_down, wrap=5, aspect_ratio=15./23, gap=10, auto_size=true },
        })

        for data_topic in data_section.topics {
            ui.add_frame(topics, {
                name        = data_topic.id,
                flags       = {.terse},
                text        = data_topic.title,
                text_format = "<wrap,pad=12:6,font=text_4l,color=primary_l2>%s",
                draw        = partials.draw_codex_topic_item,
                click       = proc (f: ^ui.Frame) {
                    topics := f.parent
                    section := ui.prev_sibling(topics)
                    assert(section != nil)
                    journey_page_show_codex_topic(section.name, f.name)
                },
            })
        }
    }

    details_flow := ui.layout_flow(details)
    details_flow.pad = 15
    details_flow.gap = 15

    max_articles :: 10
    for _ in 0..<max_articles {
        ui.add_frame(details, {
            name    = "article",
            flags   = {.terse,.terse_height},
        })

        ui.add_frame(details, {
            name    = "line",
            text    = "primary_a2",
            size    = {0,1},
            draw    = partials.draw_color_rect,
        })
    }

    // preselect topic
    ui.click(list, "~the_imperium")
}

journey_page_show_codex_topic :: proc (section_id, topic_id: string) {
    // fmt.println("-------------------------------------")
    // fmt.println("section_id", section_id)
    // fmt.println("topic_id", topic_id)
    // fmt.println("-------------------------------------")

    data_topic := data.get_codex_topic(section_id, topic_id)
    // fmt.println("data_topic", data_topic)

    header := ui.get(codex_page, "details_header")
    ui.set_text(header, data_topic.title)

    aside := ui.get(header, "aside")
    unlocked_articles, total_articles := data.get_codex_topic_stats(data_topic)
    ui.set_text(aside, fmt.tprintf("%i/%i", unlocked_articles, total_articles))

    details := ui.get(codex_page, "details")
    ui.hide_children(details)
    for data_article, i in data_topic.articles {
        article := details.children[i*2]

        locked := data_article.locked
        if locked != "" {
            text := fmt.tprintf("<wrap,left,font=text_4l,color=primary_d5>%s", locked)
            ui.set_text(article, text, shown=true)
        } else {
            text := fmt.tprintf(
                "<wrap,left,font=text_4r,color=primary_l2>%i. %s\n\n<font=text_4l,color=primary_d2>%s",
                i+1,
                data_article.title,
                data.text_to_string(data_article.desc, context.temp_allocator),
            )
            ui.set_text(article, text, shown=true)
        }

        line := details.children[i*2+1]
        ui.show(line)
    }

    ui.update(codex_page)
}

add_journey_page_tutorial :: proc (parent: ^ui.Frame) {
    _, list, details := partials.add_screen_page_body_with_list_and_details(parent, "tutorial")

    details_flow := ui.layout_flow(details)
    details_flow.dir = .up_and_down
    details_flow.align = .center
    details.draw = nil

    for tip in data.tutorial_tips {
        ui.add_frame(list, {
            name        = tip.id,
            flags       = {.radio,.terse,.terse_height},
            text        = tip.title,
            text_format = "<wrap,left,pad=24:16,font=text_4r,color=primary_d2>%s",
            draw        = partials.draw_tutorial_item,
            click       = proc (f: ^ui.Frame) { journey_page_show_tutorial_tip(f.name) },
        })
    }

    details_column := ui.add_frame(details, {
        name    = "column",
        size    = {400,0},
        layout  = ui.Flow { dir=.up_and_down,auto_size=.dir,gap=1 },
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
    tip_desc := data.text_to_string(tip.desc, context.temp_allocator)
    if tip_desc != ""   do ui.set_text(desc, tip_desc, shown=true)
    else                do ui.hide(desc)

    ui.set_scroll_offset(details, 0)
    ui.show(details)
    ui.update(details)
}
