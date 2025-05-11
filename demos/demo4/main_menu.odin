package demo4

import "core:fmt"
import "spacelib:ui"

Main_Menu :: struct {
    menu_panel  : ^ui.Frame,
    exit_dialog : ^ui.Frame,
}

main_menu_init :: proc () {
    fmt.println(#procedure)
    assert(app.ui.main_menu == nil)

    app.ui.main_menu = new(Main_Menu)
    app.ui.main_menu.menu_panel = main_menu_add_panel(app.ui.manager.root)
    app.ui.main_menu.exit_dialog = main_menu_add_exit_dialog(app.ui.manager.root)

    // select default tab
    ui.click(app.ui.main_menu.menu_panel, "text={icon=play}Play ") // TODO: use "tab_bar/play"

    // // !! DEBUG -- test layout.scroll
    // cont1 := ui.add_frame(app.ui.manager.root, {
    //     rect    = {50,50,150,150},
    //     scissor = true,
    //     layout  = { dir=.right, align=.center, pad=20, gap=5, size={50,50}, scroll={ step=20 } },
    //     draw    = draw_ui_border,
    // })
    // for _ in 0..<5 do ui.add_frame(cont1, { draw=draw_ui_border })

    // // !! DEBUG -- test layout.auto_size
    // cont2 := ui.add_frame(app.ui.manager.root, {
    //     size={0,150},
    //     scissor = true,
    //     layout  = { dir=.right, align=.center, pad=20, gap=5, size={50,50}, auto_size=true },
    //     draw    = draw_ui_border,
    // }, { {point=.top_left, offset={50,220}} })
    // for _ in 0..<5 do ui.add_frame(cont2, { draw=draw_ui_border })
}

main_menu_destroy :: proc () {
    fmt.println(#procedure)

    free(app.ui.main_menu)
    app.ui.main_menu = nil
}

// ----------
// menu panel
// ----------

main_menu_add_panel :: proc (parent: ^ui.Frame) -> ^ui.Frame {
    root := ui.add_frame(parent, { name=#procedure, /*size={720,480},*/ draw=proc (f: ^ui.Frame) {
        draw_sprite(.panel_3, f.rect, colors[.c2].val.rgba)
    } }, { /*{ point=.center },*/ { point=.top_left, offset={250,100} }, { point=.bottom_right, offset={-250,-100} } })

    title_bar := ui.add_frame(root,
        { size={0,120}, text_flags={.terse}, text="{font=anaheim_huge,color=c7}Demo Title Text" },
        { { point=.top_left, offset={0,20} }, { point=.top_right, offset={0,20} } },
    )

    tab_content := ui.add_frame(root, {}, {
        { point=.top_left, rel_point=.bottom_left, rel_frame=title_bar, offset={25,0} },
        { point=.bottom_right, offset={-25-225,-25} },
    })

    {
        play_panel := ui.add_frame(tab_content, {
            name="play_panel",
            hidden=true,
            draw=draw_ui_border,
        }, { { point=.top_left }, { point=.bottom_right } })

        ui.add_frame(play_panel,
            { text_flags={.terse,.auto_height}, text=
                "{color=c5}Welcome!\n\n"+
                "Please see {color=c8}How To Play{color=c5} section if you're new to the game.\n\n"+
                "Click {color=c8}New Game{color=c5} below or press ESC to start playing." },
            { { point=.top_left, offset={90,20} }, { point=.top_right, offset={-90,20} } },
        )

        ui.add_frame(play_panel, {
            size={150,50},
            text_flags={.terse},
            text="New Game",
            draw=draw_ui_button,
            click=proc (f: ^ui.Frame) { fmt.println("new game!") },
        }, { { point=.bottom, offset={0,-30} } })
    }

    {
        options_panel := ui.add_frame(tab_content, {
            name="options_panel",
            hidden=true,
            scissor=true,
            layout={ dir=.down, pad=20, gap=5, scroll={step=20} },
            draw_after=draw_ui_border,
        }, { { point=.top_left }, { point=.bottom_right } })

        ui.add_frame(options_panel, { text_flags={.terse,.auto_height}, text="{left}     Play Music", check=true, draw=draw_ui_checkbox })
        ui.add_frame(options_panel, { text_flags={.terse,.auto_height}, text="{left}     Play SFX", check=true, draw=draw_ui_checkbox })
        ui.add_frame(options_panel, { text_flags={.terse,.auto_height}, text="{left}     Do something else", check=true, draw=draw_ui_checkbox })
        ui.add_frame(options_panel, { text_flags={.terse,.auto_height}, text="{left}     And do this too please", check=true, draw=draw_ui_checkbox })

        // todo: add slider demo (and implement the support)
    }

    {
        how_to_play_panel := ui.add_frame(tab_content, {
            name="how_to_play_panel",
            hidden=true,
            draw=draw_ui_border,
            wheel=proc (f: ^ui.Frame, dy: f32) -> bool { return ui.wheel(f, "content", dy) },
        }, { { point=.top_left }, { point=.bottom_right } })

        scrollbar_w :: 50
        scrollbar_btn_h :: 50

        content := ui.add_frame(how_to_play_panel, {
            name="content",
            scissor=true,
            layout={ dir=.down, gap=25, scroll={ step=20 } },
        }, { { point=.top_left, offset={20,20} }, { point=.bottom_right, offset={-10-scrollbar_w-20,-20} } })

        ui.add_frame(content, { text_flags={.terse,.auto_height}, text=
            "{top,left,color=c7}All roads lead to Nexus\n"+
            "{color=c5}Build roads from any existing node. Roads cannot be destroyed. "+
            "Build mines, turrets, and plants on empty nodes. The Nexus node is given "+
            "at the start of the game; if destroyed, the game ends." })

        { // test scrolling child frame
            inline_container := ui.add_frame(content, { layout={ dir=.down, auto_size=true } })
            ui.add_frame(inline_container, { text_flags={.terse,.auto_height}, text="{top,left,color=c7}Test scrolling child frame" })
            sc := ui.add_frame(inline_container, { size={0,80}, scissor=true, layout={dir=.right,size={120,0},pad=10,gap=5,scroll={step=20}}, draw_after=draw_ui_border })
            for text in ([] string { "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta" }) {
                ui.add_frame(sc, { text_flags={.terse}, text=text, radio=true, draw=draw_ui_button })
            }
        }

        ui.add_frame(content, { text_flags={.terse,.auto_height}, text=
            "{top,left,color=c7}Growing world\n"+
            "{color=c5}The world expands every 3 minutes. Newly revealed areas contain "+
            "enemy units that will attack your units and nodes. Maximize gold mining, and "+
            "build turrets and plants for unit production." })

        scrollbar_track := ui.add_frame(how_to_play_panel, {
            name="scrollbar_track",
            size={scrollbar_w,0},
        }, {
            { point=.top_left, rel_point=.top_right, rel_frame=content, offset={10,scrollbar_btn_h} },
            { point=.bottom_left, rel_point=.bottom_right, rel_frame=content, offset={10,-scrollbar_btn_h} },
        })

        scrollbar_thumb := ui.add_frame(scrollbar_track, {
            size={scrollbar_w,scrollbar_btn_h},
            draw=draw_ui_button_sprite_icon_stop,
        }, { { point=.top } })

        scrollbar_up := ui.add_frame(scrollbar_track, {
            size={scrollbar_w,scrollbar_btn_h},
            draw=draw_ui_button_sprite_icon_up,
        }, { { point=.bottom, rel_point=.top } })

        scrollbar_down := ui.add_frame(scrollbar_track, {
            size={scrollbar_w,scrollbar_btn_h},
            draw=draw_ui_button_sprite_icon_down,
        }, { { point=.top, rel_point=.bottom } })

        ui.setup_scrollbar_actors(content, scrollbar_thumb, scrollbar_down, scrollbar_up)
    }

    {
        about_panel := ui.add_frame(tab_content, {
            name="about_panel",
            hidden=true,
            scissor=true,
            layout={ dir=.down, pad=20, gap=5, scroll={step=20} },
            draw_after=draw_ui_border,
        }, { { point=.top_left }, { point=.bottom_right } })

        ui.add_frame(about_panel, { text_flags={.terse,.auto_height}, text=
            "{top,center,color=c7}The game is made for Odin 7 Day Jam by Spacemad using Odin and Raylib.\n" })

        ui.add_frame(about_panel, { text_flags={.terse,.auto_height}, text="{icon=nav}Open Jam page", draw=draw_ui_link })
        ui.add_frame(about_panel, { text_flags={.terse,.auto_height}, text="{icon=nav}Open Game page", draw=draw_ui_link })
        ui.add_frame(about_panel, { text_flags={.terse,.auto_height}, text="{icon=nav}Open Odin page", draw=draw_ui_link })
        ui.add_frame(about_panel, { text_flags={.terse,.auto_height}, text="{icon=nav}Open Raylib page", draw=draw_ui_link })

        ui.add_frame(about_panel, { text_flags={.terse,.auto_height}, text=
            "\n{bottom,center,color=c7}Thank you for playing <3" })
    }

    tab_bar := ui.add_frame(root, { name="tab_bar", layout={ dir=.down, size={0,50}, gap=10 } }, {
        { point=.top_left, rel_point=.top_right, rel_frame=tab_content, offset={15,0} },
        { point=.top_right, rel_point=.bottom_right, rel_frame=title_bar, offset={-25,0} },
    })

    // TODO: rework to use "name" and "text" separately
    for text in ([] string {
        "{icon=play}Play ",
        "{icon=cog}Options ",
        "{icon=question}How To Play ",
        "{icon=info}About ",
        "{icon=exit}Exit ",
    }) {
        button := ui.add_frame(tab_bar, { text_flags={.terse}, text=text, draw=draw_ui_button, click=proc (f: ^ui.Frame) {
            menu := app.ui.main_menu
            switch f.text {
            case "{icon=play}Play "             : ui.show(menu.menu_panel, "play_panel", hide_siblings=true)
            case "{icon=cog}Options "           : ui.show(menu.menu_panel, "options_panel", hide_siblings=true)
            case "{icon=question}How To Play "  : ui.show(menu.menu_panel, "how_to_play_panel", hide_siblings=true)
            case "{icon=info}About "            : ui.show(menu.menu_panel, "about_panel", hide_siblings=true)
            case "{icon=exit}Exit "             : ui.show(menu.exit_dialog)
            }
        } })

        if text == "Play" do button.size.y = 65
        if text != "Exit" do button.radio = true
    }

    ui.add_frame(root,
        { order=-1, text_flags={.terse,.auto_height}, text="{right,color=c3}by Spacemad" },
        { { point=.bottom_right, offset={-25,-15} } },
    )

    return root
}

// -----------
// exit dialog
// -----------

main_menu_add_exit_dialog :: proc (parent: ^ui.Frame) -> ^ui.Frame {
    root := ui.add_frame(parent,
        { name=#procedure, order=10, hidden=true, solid=true, draw=draw_ui_dim_rect },
        { { point=.top_left }, { point=.bottom_right } })

    container := ui.add_frame(root, { size={440,0}, draw=draw_ui_panel,
        layout={ dir=.up_and_down, gap=40, pad=40, auto_size=true } }, { { point=.center } })

    ui.add_frame(container, { text_flags={.terse,.auto_height}, text="{color=c7}{font=anaheim_huge,icon=exit}{font=anaheim_normal} Exit the game?" })

    button_row := ui.add_frame(container, { size={0,50}, layout={ dir=.left_and_right, gap=20 } })

    ui.add_frame(button_row, { text_flags={.terse}, text="Yes", size={150,0}, draw=draw_ui_button, click=proc (f: ^ui.Frame) {
        app.exit_requested = true
    } })

    ui.add_frame(button_row, { text_flags={.terse}, text="No", size={150,0}, draw=draw_ui_button, click=proc (f: ^ui.Frame) {
        ui.hide(app.ui.main_menu.exit_dialog)
    } })

    return root
}
