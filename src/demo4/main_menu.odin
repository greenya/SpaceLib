package demo4

import "core:fmt"
import sl "../spacelib"

Main_Menu :: struct {
    menu_panel  : ^sl.Frame,
    exit_dialog : ^sl.Frame,
}

create_main_menu :: proc () {
    fmt.println(#procedure)
    assert(game.ui.main_menu == nil)

    game.ui.main_menu = new(Main_Menu)
    game.ui.main_menu.menu_panel = add_main_menu_panel(game.ui.manager.root)
    game.ui.main_menu.exit_dialog = add_main_menu_exit_dialog(game.ui.manager.root)

    // select default tab
    sl.click(game.ui.main_menu.menu_panel, "How To Play")

    // // !! DEBUG -- test layout.scroll
    // cont1 := sl.add_frame(game.ui.manager.root, {
    //     rect    = {50,50,150,150},
    //     scissor = true,
    //     layout  = { dir=.right, align=.center, pad=20, gap=5, size={50,50}, scroll={ step=20 } },
    //     draw    = draw_ui_border,
    // })
    // for i in 0..<5 do sl.add_frame(cont1, { draw=draw_ui_border })

    // // !! DEBUG -- test layout.auto_size
    // cont2 := sl.add_frame(game.ui.manager.root, {
    //     size={0,150},
    //     scissor = true,
    //     layout  = { dir=.right, align=.center, pad=20, gap=5, size={50,50}, auto_size=true },
    //     draw    = draw_ui_border
    // }, { {point=.top_left, offset={50,220}} })
    // for i in 0..<5 do sl.add_frame(cont2, { draw=draw_ui_border })
}

destroy_main_menu :: proc () {
    fmt.println(#procedure)

    free(game.ui.main_menu)
    game.ui.main_menu = nil
}

// ----------
// menu panel
// ----------

add_main_menu_panel :: proc (parent: ^sl.Frame) -> ^sl.Frame {
    menu := game.ui.main_menu

    root := sl.add_frame(parent, { text=#procedure, /*size={720,480},*/ draw=proc (f: ^sl.Frame) {
        draw_sprite(.panel_3, f.rect, colors.two)
    } }, { /*{ point=.center },*/ { point=.top_left, offset={250,100} }, { point=.bottom_right, offset={-250,-100} } })

    title_bar := sl.add_frame(root, { size={0,120}, draw=proc (f: ^sl.Frame) {
        draw_text("Roads to Power", f.rect, .anaheim_bold_64, {.center,.center}, colors.seven)
    } }, { { point=.top_left, offset={0,20} }, { point=.top_right, offset={0,20} } })

    tab_content := sl.add_frame(root, {
        wheel=proc (f: ^sl.Frame, dy: f32) {
            content := sl.find(game.ui.main_menu.menu_panel, "how_to_play_panel/content")
            if content != nil do sl.wheel(content, dy)
        },
    }, {
        { point=.top_left, rel_point=.bottom_left, rel_frame=title_bar, offset={25,0} },
        { point=.bottom_right, offset={-25-200,-25} },
    })

    {
        play_panel := sl.add_frame(tab_content, {
            text="play_panel",
            hidden=true,
            draw=draw_ui_border,
        }, { { point=.top_left }, { point=.bottom_right } })

        sl.add_frame(play_panel, {
            draw=proc (f: ^sl.Frame) {
                text_rect := draw_text("Welcome!\n\nPlease see How To Play section if you're new to the game.\n\nClick New Game below or press ESC to start playing.", f.rect, .anaheim_bold_32, {.center,.center}, colors.seven)
                f.size.y = text_rect.h
            },
        }, { { point=.top_left, offset={90,20} }, { point=.top_right, offset={-90,20} } })

        sl.add_frame(play_panel, {
            size={150,50},
            text="New Game",
            draw=draw_ui_button,
            click=proc (f: ^sl.Frame) {
                fmt.println("new game!")
            },
        }, { { point=.bottom, offset={0,-30} } })
    }

    {
        options_panel := sl.add_frame(tab_content, {
            text="options_panel",
            hidden=true,
            draw=draw_ui_border,
        }, { { point=.top_left }, { point=.bottom_right } })

        // todo: add checkbox demo
        // todo: add slider demo (and implement the support)
    }

    {
        how_to_play_panel := sl.add_frame(tab_content, {
            text="how_to_play_panel",
            hidden=true,
            draw=draw_ui_border,
        }, { { point=.top_left }, { point=.bottom_right } })

        scrollbar_w :: 50
        scrollbar_btn_h :: 50

        content := sl.add_frame(how_to_play_panel, {
            text="content",
            scissor=true,
            layout={ dir=.down, scroll={ step=20 } },
        }, { { point=.top_left, offset={20,20} }, { point=.bottom_right, offset={-10-scrollbar_w-20,-20} } })

        sl.add_frame(content, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("All roads lead to Nexus", f.rect, .anaheim_bold_32, {.top,.left}, colors.seven)
            f.size.y = text_rect.h
        } })
        sl.add_frame(content, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("Build roads from any existing node. Roads cannot be destroyed. Build mines, turrets, and plants on empty nodes. The Nexus node is given at the start of the game; if destroyed, the game ends.", f.rect, .anaheim_bold_32, {.top,.left}, colors.five)
            f.size.y = text_rect.h + 20
        } })
        sl.add_frame(content, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("Growing world", f.rect, .anaheim_bold_32, {.top,.left}, colors.seven)
            f.size.y = text_rect.h
        } })
        sl.add_frame(content, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("The world expands every 3 minutes. Newly revealed areas contain enemy units that will attack your units and nodes. Maximize gold mining, and build turrets and plants for unit production.", f.rect, .anaheim_bold_32, {.top,.left}, colors.five)
            f.size.y = text_rect.h
        } })

        scrollbar_track := sl.add_frame(how_to_play_panel, {
            text="scrollbar track",
            size={scrollbar_w,0},
        }, {
            { point=.top_left, rel_point=.top_right, rel_frame=content, offset={10,scrollbar_btn_h} },
            { point=.bottom_left, rel_point=.bottom_right, rel_frame=content, offset={10,-scrollbar_btn_h} },
        })

        scrollbar_thumb := sl.add_frame(scrollbar_track, {
            size={scrollbar_w,scrollbar_btn_h},
            draw=draw_ui_button_sprite_icon_stop,
        }, { { point=.top } })

        scrollbar_up := sl.add_frame(scrollbar_track, {
            size={scrollbar_w,scrollbar_btn_h},
            draw=draw_ui_button_sprite_icon_up,
        }, { { point=.bottom, rel_point=.top } })

        scrollbar_down := sl.add_frame(scrollbar_track, {
            size={scrollbar_w,scrollbar_btn_h},
            draw=draw_ui_button_sprite_icon_down,
        }, { { point=.top, rel_point=.bottom } })

        sl.setup_scrollbar_actors(content, scrollbar_thumb, scrollbar_down, scrollbar_up)
    }

    {
        about_panel := sl.add_frame(tab_content,
            { text="about_panel", hidden=true, draw=draw_ui_border },
            { { point=.top_left }, { point=.bottom_right } })

        container := sl.add_frame(about_panel,
            { scissor=true, layout={ dir=.down, align=.center, gap=5 } },
            { { point=.top_left, offset={20,20} }, { point=.bottom_right, offset={-20,-20} } })

        sl.add_frame(container, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("The game is made for Odin 7 Day Jam by Spacemad using Odin and Raylib.", f.rect, .anaheim_bold_32, {.top,.center}, colors.seven)
            f.size.y = text_rect.h + 10
        } })

        sl.add_frame(container, { text="Open Jam page", draw=draw_ui_link })
        sl.add_frame(container, { text="Open Game page", draw=draw_ui_link })
        sl.add_frame(container, { text="Open Odin page", draw=draw_ui_link })
        sl.add_frame(container, { text="Open Raylib page", draw=draw_ui_link })

        sl.add_frame(container, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("Thank you for playing <3", f.rect, .anaheim_bold_32, {.bottom,.center}, colors.seven)
            f.size.y = text_rect.h + 15
        } })
    }

    tab_bar := sl.add_frame(root, { layout={ dir=.down, size={0,50}, gap=10 } }, {
        { point=.top_left, rel_point=.top_right, rel_frame=tab_content, offset={15,0} },
        { point=.top_right, rel_point=.bottom_right, rel_frame=title_bar, offset={-25,0} },
    })

    for text in ([] string { "Play", "Options", "How To Play", "About", "Exit" }) {
        button := sl.add_frame(tab_bar, { text=text, draw=draw_ui_button, click=proc (f: ^sl.Frame) {
            menu := game.ui.main_menu
            switch f.text {
            case "Play"         : sl.show(menu.menu_panel, "play_panel", hide_siblings=true)
            case "Options"      : sl.show(menu.menu_panel, "options_panel", hide_siblings=true)
            case "How To Play"  : sl.show(menu.menu_panel, "how_to_play_panel", hide_siblings=true)
            case "About"        : sl.show(menu.menu_panel, "about_panel", hide_siblings=true)
            case "Exit"         : sl.show(menu.exit_dialog)
            }
        } })

        if text == "Play" do button.size.y = 65
        if text != "Exit" do button.radio = true
    }

    sl.add_frame(root, { size={150,40}, draw=proc (f: ^sl.Frame) {
        draw_text("by Spacemad", f.rect, .anaheim_bold_32, {.bottom,.right}, colors.three)
    } }, { { point=.bottom_right, offset={-25,-15} } })

    return root
}

// -----------
// exit dialog
// -----------

add_main_menu_exit_dialog :: proc (parent: ^sl.Frame) -> ^sl.Frame {
    root := sl.add_frame(parent,
        { text=#procedure, order=10, hidden=true, modal=true, draw=draw_ui_dim_rect },
        { { point=.top_left }, { point=.bottom_right } })

    container := sl.add_frame(root, { size={440,0}, draw=draw_ui_panel,
        layout={ dir=.down, gap=30, pad=30, auto_size=true } }, { { point=.center } })

    sl.add_frame(container, { text="Exit the game?", draw=proc (f: ^sl.Frame) {
        text_rect := draw_text(f.text, sl.rect_inflated(f.rect, {-40, 0}), .anaheim_bold_32, {.center,.center}, colors.seven)
        f.size.y = text_rect.h
    } })

    button_row := sl.add_frame(container, { size={0,50}, layout={ dir=.left_and_right, gap=20 } })

    sl.add_frame(button_row, { text="Yes", size={150,0}, draw=draw_ui_button, click=proc (f: ^sl.Frame) {
        game.exit_requested = true
    } })

    sl.add_frame(button_row, { text="No", size={150,0}, draw=draw_ui_button, click=proc (f: ^sl.Frame) {
        sl.hide(game.ui.main_menu.exit_dialog)
    } })

    return root
}
