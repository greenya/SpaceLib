package demo4

import "core:fmt"
import "spacelib:ui"

Main_Menu :: struct {
    menu_panel  : ^ui.Frame,
    exit_dialog : ^ui.Frame,
}

main_menu_init :: proc () {
    fmt.println(#procedure)
    assert(app.main_menu == nil)

    app.main_menu = new(Main_Menu)
    app.main_menu.menu_panel = main_menu_add_panel(app.ui.root)
    app.main_menu.exit_dialog = main_menu_add_exit_dialog(app.ui.root)

    // select default tab
    ui.click(app.main_menu.menu_panel, "tab_bar/play")

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

    free(app.main_menu)
    app.main_menu = nil
}

// ----------
// menu panel
// ----------

main_menu_add_panel :: proc (parent: ^ui.Frame) -> ^ui.Frame {
    root := ui.add_frame(parent, { name=#procedure, /*size={720,480},*/ draw=proc (f: ^ui.Frame) {
        draw_sprite(.panel_3, f.rect, colors[.c2].val.rgba)
    } }, /*{ point=.center }*/ { point=.top_left, offset={250,100} }, { point=.bottom_right, offset={-250,-100} })

    title_bar := ui.add_frame(root,
        { size={0,120}, flags={.terse}, text="<font=anaheim_huge,color=c7>Demo Title Text" },
        { point=.top_left, offset={0,20} },
        { point=.top_right, offset={0,20} },
    )

    tab_content := ui.add_frame(root, {},
        { point=.top_left, rel_point=.bottom_left, rel_frame=title_bar, offset={25,0} },
        { point=.bottom_right, offset={-25-225,-25} },
    )

    {
        play_panel := ui.add_frame(tab_content,
            { name="play_panel", flags={ .hidden }, draw=draw_ui_border_17, },
            { point=.top_left },
            { point=.bottom_right },
        )

        ui.add_frame(play_panel,
            { flags={.terse,.terse_height}, text=
                "<wrap,color=c5>Welcome!\n\n"+
                "Please see <color=c8>How To Play</color> section if you're new to the game.\n\n"+
                "Click <color=c8>New Game</color> below or press ESC to start playing." },
            { point=.top_left, offset={90,20} },
            { point=.top_right, offset={-90,20} },
        )

        ui.add_frame(play_panel, {
            size={150,50},
            flags={.capture,.terse},
            text="New Game",
            draw=draw_ui_button,
            click=proc (f: ^ui.Frame) { fmt.println("new game!") },
        }, { point=.bottom, offset={0,-30} })
    }

    {
        options_panel := ui.add_frame(tab_content, {
            name="options_panel",
            flags={ .hidden, .scissor },
            layout=ui.Flow{ dir=.down, pad=20, gap=5, scroll={step=20} },
            draw_after=draw_ui_border_17,
        }, { point=.top_left }, { point=.bottom_right })

        ui.add_frame(options_panel, { flags={.capture,.check,.terse,.terse_height,.terse_hit_rect}, text="<left><group=tick><icon=border_15></group> Play Music", draw=draw_ui_checkbox })
        ui.add_frame(options_panel, { flags={.capture,.check,.terse,.terse_height,.terse_hit_rect}, text="<left><group=tick><icon=border_15></group> Play SFX", draw=draw_ui_checkbox })
        ui.add_frame(options_panel, { flags={.capture,.check,.terse,.terse_height,.terse_hit_rect}, text="<left><group=tick><icon=border_15></group> Do something else", draw=draw_ui_checkbox })
        ui.add_frame(options_panel, { flags={.capture,.check,.terse,.terse_height,.terse_hit_rect}, text="<left><group=tick><icon=border_15></group> And do this too please", draw=draw_ui_checkbox })

        // todo: add slider demo (and implement the support)
    }

    {
        how_to_play_panel := ui.add_frame(tab_content, {
            name="how_to_play_panel",
            flags={ .hidden },
            draw=draw_ui_border_17,
            wheel=proc (f: ^ui.Frame, dy: f32) -> bool { return ui.wheel(f, "content", dy) },
        }, { point=.top_left }, { point=.bottom_right })

        scrollbar_w :: 50
        scrollbar_btn_h :: 50

        content := ui.add_frame(how_to_play_panel, {
            name="content",
            flags={ .scissor },
            layout=ui.Flow{ dir=.down, gap=25, scroll={ step=20 } },
        }, { point=.top_left, offset={20,20} }, { point=.bottom_right, offset={-10-scrollbar_w-20,-20} })

        ui.add_frame(content, { flags={.terse,.terse_height}, text=
            "<wrap,top,left,color=c5,color=c7>All roads lead to Nexus</color>\n"+
            "Build roads from any existing node. Roads cannot be destroyed. "+
            "Build mines, turrets, and plants on empty nodes. The Nexus node is given "+
            "at the start of the game; if destroyed, the game ends." })

        { // test scrolling child frame
            inline_container := ui.add_frame(content, { layout=ui.Flow{ dir=.down, auto_size={.height} } })
            ui.add_frame(inline_container, { flags={.terse,.terse_height}, text="<top,left,color=c7>Test scrolling child frame" })
            sc := ui.add_frame(inline_container, { size={0,80}, flags={.scissor}, layout=ui.Flow{dir=.right,size={120,0},pad=10,gap=5,scroll={step=20}}, draw_after=draw_ui_border_15 })
            for text in ([] string { "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta" }) {
                ui.add_frame(sc, { flags={.capture,.radio,.terse}, text=text, draw=draw_ui_button })
            }
        }

        ui.add_frame(content, { flags={.terse,.terse_height}, text=
            "<wrap,top,left,color=c5,color=c7>Growing world</color>\n"+
            "The world expands every 3 minutes. Newly revealed areas contain "+
            "enemy units that will attack your units and nodes. Maximize gold mining, and "+
            "build turrets and plants for unit production." })

        scrollbar_track := ui.add_frame(how_to_play_panel,
            { name="scrollbar_track", size={scrollbar_w,0} },
            { point=.top_left, rel_point=.top_right, rel_frame=content, offset={10,scrollbar_btn_h} },
            { point=.bottom_left, rel_point=.bottom_right, rel_frame=content, offset={10,-scrollbar_btn_h} },
        )

        scrollbar_thumb := ui.add_frame(scrollbar_track, {
            flags={.capture},
            size={scrollbar_w,scrollbar_btn_h},
            draw=draw_ui_button_sprite_icon_stop,
        }, { point=.top })

        scrollbar_up := ui.add_frame(scrollbar_track, {
            flags={.capture},
            size={scrollbar_w,scrollbar_btn_h},
            draw=draw_ui_button_sprite_icon_up,
        }, { point=.bottom, rel_point=.top })

        scrollbar_down := ui.add_frame(scrollbar_track, {
            flags={.capture},
            size={scrollbar_w,scrollbar_btn_h},
            draw=draw_ui_button_sprite_icon_down,
        }, { point=.top, rel_point=.bottom })

        ui.setup_scrollbar_actors(content, scrollbar_thumb, scrollbar_down, scrollbar_up)
    }

    {
        about_panel := ui.add_frame(tab_content, {
            name="about_panel",
            flags={ .hidden, .scissor },
            layout=ui.Flow{ dir=.down, pad=20, gap=5, scroll={step=20} },
            draw_after=draw_ui_border_17,
        }, { point=.top_left }, { point=.bottom_right })

        ui.add_frame(about_panel, { flags={.terse,.terse_height}, text=
            "<wrap,top,center,color=c5>The game is made for <color=c8>Odin 7 Day Jam</color> "+
            "by Spacemad using Odin and Raylib.\n" })

        // ui.add_frame(about_panel, { flags={.terse,.terse_height}, text=
        //     "{top,center,color=c5}"+
        //     "The game is made for {group=jm_link,color=c8}Odin 7 Day Jam{/color,/group} "+
        //     "by {group=sm_link,color=c8}Spacemad{/color,/group} "+
        //     "using {group=od_link,color=c8}Odin{/color,/group} "+
        //     "and {group=rl_link,color=c8}Raylib{/color,/group}.\n" })

        ui.add_frame(about_panel, { flags={.capture,.terse,.terse_height,.terse_hit_rect}, text="<icon=nav>Open Jam page", draw=draw_ui_link })
        ui.add_frame(about_panel, { flags={.capture,.terse,.terse_height,.terse_hit_rect}, text="<icon=nav>Open Game page", draw=draw_ui_link })
        ui.add_frame(about_panel, { flags={.capture,.terse,.terse_height,.terse_hit_rect}, text="<icon=nav>Open Odin page", draw=draw_ui_link })
        ui.add_frame(about_panel, { flags={.capture,.terse,.terse_height,.terse_hit_rect}, text="<icon=nav>Open Raylib page", draw=draw_ui_link })

        ui.add_frame(about_panel, { flags={.terse,.terse_height}, text=
            "\n<bottom,center,color=c7>Thank you for playing <3" })
    }

    tab_bar := ui.add_frame(root,
        { name="tab_bar", layout=ui.Flow{ dir=.down, size={0,50}, gap=10 } },
        { point=.top_left, rel_point=.top_right, rel_frame=tab_content, offset={15,0} },
        { point=.top_right, rel_point=.bottom_right, rel_frame=title_bar, offset={-25,0} },
    )

    for info in ([][2] string {
        { "play"        , "<icon=play>Play " },
        { "options"     , "<icon=cog>Options " },
        { "how_to_play" , "<icon=question>How To Play "},
        { "about"       , "<icon=info>About " },
        { "exit"        , "<icon=exit>Exit " },
    }) {
        name := info[0]
        text := info[1]
        draw := draw_ui_button

        button := ui.add_frame(tab_bar,
            { name=name, flags={.capture,.terse}, text=text, draw=draw, click=proc (f: ^ui.Frame) {
                menu := app.main_menu
                switch f.name {
                case "play"         : ui.show(menu.menu_panel, "~play_panel", hide_siblings=true)
                case "options"      : ui.show(menu.menu_panel, "~options_panel", hide_siblings=true)
                case "how_to_play"  : ui.show(menu.menu_panel, "~how_to_play_panel", hide_siblings=true)
                case "about"        : ui.show(menu.menu_panel, "~about_panel", hide_siblings=true)
                case "exit"         : ui.show(menu.exit_dialog)
                }
            },
        })

        if name == "play" do button.size.y = 65
        if name != "exit" do button.flags += { .radio }
    }

    ui.add_frame(root,
        { order=-1, flags={.terse,.terse_size}, text="<right,color=c3>by Spacemad" },
        { point=.bottom_right, offset={-25,-15} },
    )

    return root
}

// -----------
// exit dialog
// -----------

main_menu_add_exit_dialog :: proc (parent: ^ui.Frame) -> ^ui.Frame {
    root := ui.add_frame(parent,
        { name=#procedure, order=10, flags={ .hidden, .block_wheel }, draw=draw_ui_dim_rect },
        { point=.top_left },
        { point=.bottom_right },
    )

    container := ui.add_frame(root, { size={440,0}, draw=draw_ui_panel,
        layout=ui.Flow{ dir=.down, gap=40, pad=40, align=.center, auto_size={.height} } }, { point=.center })

    ui.add_frame(container, {
        flags={.terse,.terse_height},
        text="<wrap,color=c7,font=anaheim_huge,icon=exit></font> Exit the game?",
    })

    button_row := ui.add_frame(container, { size={0,50}, layout=ui.Flow{ dir=.right, gap=20, auto_size={.width} } })

    ui.add_frame(button_row, { flags={.capture,.terse}, text="Yes", size={150,0}, draw=draw_ui_button, click=proc (f: ^ui.Frame) {
        app.exit_requested = true
    } })

    ui.add_frame(button_row, { flags={.capture,.terse}, text="No", size={150,0}, draw=draw_ui_button, click=proc (f: ^ui.Frame) {
        ui.hide(app.main_menu.exit_dialog)
    } })

    return root
}
