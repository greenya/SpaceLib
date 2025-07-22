#+private
package player

import "core:fmt"

import "spacelib:ui"

import "../../data"
import "../../partials"

Journey_Page :: struct {
    root        : ^ui.Frame,
    tabs        : ^ui.Frame,

    story       : ^ui.Frame,
    contracts   : ^ui.Frame,

    codex: struct {
        root    : ^ui.Frame,
        list    : ^ui.Frame,
        details : ^ui.Frame,
    },

    tutorial: struct {
        root    : ^ui.Frame,
        list    : ^ui.Frame,
        details: struct {
            root    : ^ui.Frame,
            column  : ^ui.Frame,
            title   : ^ui.Frame,
            image   : ^ui.Frame,
            desc    : ^ui.Frame,
        },
    },
}

journey_page_tabs: [] struct { name, text, icon: string, add: proc (parent: ^ui.Frame) } = {
    { name="story"      , text="STORY"      , icon="images_mode"            , add=add_journey_page_story },
    { name="contracts"  , text="CONTRACTS"  , icon="stylus_fountain_pen"    , add=add_journey_page_contracts },
    { name="codex"      , text="CODEX"      , icon="auto_stories"           , add=add_journey_page_codex },
    { name="tutorial"   , text="TUTORIAL"   , icon="stacks"                 , add=add_journey_page_tutorial },
}

add_journey_page :: proc () {
    journey := &screen.journey
    _, journey.root = partials.add_screen_tab_and_page(&screen, "journey", "JOURNEY")

    tab_details := make([dynamic] partials.Category_Tab_Details, context.temp_allocator)
    for t in journey_page_tabs do append(&tab_details, partials.Category_Tab_Details { name=t.name, icon=t.icon })

    journey.tabs = partials.add_category_tabs(journey.root, "tabs", items=tab_details[:],
        click=proc (f: ^ui.Frame) {
            title := ui.get(f, "../title")
            assert(f.order >= 0 && f.order < len(journey_page_tabs))
            ui.set_text(title, journey_page_tabs[f.order].text)

            content := ui.get(f, "../../content")
            ui.show(content, f.name, hide_siblings=true)

            ui.update(screen.journey.root)
        },
    )

    ui.set_order(journey.tabs, 1)
    ui.set_anchors(journey.tabs, { point=.top_left, offset={80,70} })

    content := ui.add_frame(journey.root,
        { name="content" },
        { point=.top_left, rel_frame=journey.tabs, offset={0,60} },
        { point=.bottom_right, offset={-80,-40} },
    )

    for t in journey_page_tabs do t.add(content)

    // ui.print_frame_tree(journey.root, max_depth=2)

    ui.click(journey.tabs, "codex")
}

add_journey_page_story :: proc (parent: ^ui.Frame) {
    screen.journey.story = ui.add_frame(parent,
        { name="story" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_placeholder_note(screen.journey.story, "STORY SECTION GOES HERE...")
}

add_journey_page_contracts :: proc (parent: ^ui.Frame) {
    screen.journey.contracts = ui.add_frame(parent,
        { name="contracts" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_placeholder_note(screen.journey.contracts, "CONTRACTS SECTION GOES HERE...")
}

add_journey_page_codex :: proc (parent: ^ui.Frame) {
    codex := &screen.journey.codex
    codex.root, codex.list, codex.details = partials.add_screen_page_body_with_list_and_details(
        parent, "codex", with_details_header=true, details_header_icon="auto_stories",
    )

    for data_section in data.codex {
        section := ui.add_frame(codex.list, {
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

        topics_wrap :: 5
        topics := ui.add_frame(codex.list, {
            name    = "topics",
            flags   = {.hidden},
            layout  = ui.Grid { dir=.right_down, wrap=topics_wrap, aspect_ratio=15./23, gap=10, auto_size=true },
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

        empty_cards_to_add := topics_wrap - (len(data_section.topics) % topics_wrap)
        if empty_cards_to_add < topics_wrap do for _ in 0..<empty_cards_to_add {
            ui.add_frame(topics, {
                text = "primary_a3",
                draw = partials.draw_gradient_fade_up_and_down_rect,
            })
        }
    }

    details_flow := ui.layout_flow(codex.details)
    details_flow.pad = 15
    details_flow.gap = 15

    max_articles :: 10
    for _ in 0..<max_articles {
        ui.add_frame(codex.details, {
            name    = "article",
            flags   = {.terse,.terse_height},
        })

        ui.add_frame(codex.details, {
            name    = "line",
            text    = "primary_a2",
            size    = {0,1},
            draw    = partials.draw_color_rect,
        })
    }

    // preselect topic
    ui.click(codex.list, "~the_imperium")
}

journey_page_show_codex_topic :: proc (section_id, topic_id: string) {
    codex := &screen.journey.codex
    data_topic := data.get_codex_topic(section_id, topic_id)
    // fmt.println("data_topic", data_topic)

    header := ui.get(codex.root, "details_header")
    ui.set_text(header, data_topic.title)

    aside := ui.get(header, "aside")
    unlocked_articles, total_articles := data.get_codex_topic_stats(data_topic)
    ui.set_text(aside, fmt.tprintf("%i/%i", unlocked_articles, total_articles))

    ui.hide_children(codex.details)
    for data_article, i in data_topic.articles {
        article := codex.details.children[i*2]

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

        line := codex.details.children[i*2+1]
        ui.show(line)
    }

    ui.update(codex.root)
}

add_journey_page_tutorial :: proc (parent: ^ui.Frame) {
    tutorial := &screen.journey.tutorial
    details := &tutorial.details
    tutorial.root, tutorial.list, details.root = partials.add_screen_page_body_with_list_and_details(
        parent, "tutorial",
    )

    details_flow := ui.layout_flow(details.root)
    details_flow.align = .center
    details.root.draw = nil

    for tip in data.tutorial_tips {
        ui.add_frame(tutorial.list, {
            name        = tip.id,
            flags       = {.radio,.terse,.terse_height},
            text        = tip.title,
            text_format = "<wrap,left,pad=24:16,font=text_4r,color=primary_d2>%s",
            draw        = partials.draw_tutorial_item,
            click       = proc (f: ^ui.Frame) { journey_page_show_tutorial_tip(f.name) },
        })
    }

    details.column = ui.add_frame(details.root, {
        name    = "column",
        size    = {400,0},
        layout  = ui.Flow { dir=.up_and_down,auto_size=.dir,gap=1 },
        text    = "primary_d8",
        draw    = partials.draw_color_rect,
    })

    details.title = ui.add_frame(details.column, {
        name        = "title",
        flags       = {.terse,.terse_height},
        text        = "TITLE",
        text_format = "<wrap,left,pad=12:6,font=text_4r,color=primary_d2>%s",
        draw        = partials.draw_hexagon_rect_wide_hangout_accent,
    })

    details.image = partials.add_placeholder_image(details.column, ._11x5)
    ui.set_name(details.image, "image")

    details.desc = ui.add_frame(details.column, {
        name        = "desc",
        flags       = {.terse,.terse_height},
        text        = "DESC",
        text_format = "<wrap,top,left,pad=12:10,font=text_4l,color=primary_d2>%s",
    })

    ui.hide(details.root)
}

journey_page_show_tutorial_tip :: proc (id: string) {
    tip := data.get_tutorial_tip(id)

    details := screen.journey.tutorial.details

    // title
    ui.set_text(details.title, tip.title, shown=true)

    // image
    if tip.image != ""  do ui.show(details.image)
    else                do ui.hide(details.image)

    // desc
    tip_desc := data.text_to_string(tip.desc, context.temp_allocator)
    if tip_desc != ""   do ui.set_text(details.desc, tip_desc, shown=true)
    else                do ui.hide(details.desc)

    ui.set_scroll_offset(details.root, 0)
    ui.show(details.root)
    ui.update(details.root)
}
