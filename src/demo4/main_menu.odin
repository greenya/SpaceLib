package demo4

import "core:fmt"
import sl "../spacelib"

Main_Menu :: struct {
    menu_panel: ^sl.Frame,

    current_tab_panel: ^sl.Frame,
    tab_panel_play: ^sl.Frame,
    tab_panel_htp: ^sl.Frame,
    tab_panel_info: ^sl.Frame,

    exit_dialog: ^sl.Frame,
}

create_main_menu :: proc () {
    fmt.println(#procedure)
    assert(game.ui.main_menu == nil)

    game.ui.main_menu = new(Main_Menu)
    game.ui.main_menu.menu_panel = add_main_menu_panel(game.ui.manager.root)
    game.ui.main_menu.exit_dialog = add_main_menu_exit_dialog(game.ui.manager.root)

    // !! DEBUG -- test scroll dir
    // cont := sl.add_frame(game.ui.manager.root, {
    //     rect    = {50,50,150,150},
    //     scissor = true,
    //     layout  = { dir=.right, align=.center, pad=20, gap=5, size={50,50}, scroll={ step=20 } },
    //     draw    = draw_ui_border
    // })
    // for i in 0..<5 do sl.add_frame(cont, { draw=draw_ui_border })
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
    } }, { /*{ point=.center },*/ { point=.top_left, offset={250,120} }, { point=.bottom_right, offset={-250,-120} } })

    title_bar := sl.add_frame(root, { size={0,120}, draw=proc (f: ^sl.Frame) {
        draw_text("Roads to Power", f.rect, .anaheim_bold_64, {.center,.center}, colors.seven)
    } }, { { point=.top_left, offset={0,20} }, { point=.top_right, offset={0,20} } })

    tab_content := sl.add_frame(root, anchors={
        { point=.top_left, rel_point=.bottom_left, rel_frame=title_bar, offset={25,0} },
        { point=.bottom_right, offset={-25-200,-25} },
    })

    { // play panel
        menu.tab_panel_play = sl.add_frame(tab_content,
            { text="play panel", hidden=true, draw=draw_ui_border },
            { { point=.top_left }, { point=.bottom_right } })

        sl.add_frame(menu.tab_panel_play, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("Welcome!\n\nPlease see How To Play section if you're new to the game.\n\nClick New Game below or press ESC to start playing.", f.rect, .anaheim_bold_32, {.center,.center}, colors.seven)
            f.size.y = text_rect.h
        } }, { { point=.top_left, offset={90,20} }, { point=.top_right, offset={-90,20} } })

        sl.add_frame(menu.tab_panel_play,
            { size={150,50}, text="New Game", draw=draw_ui_button, click=proc (f: ^sl.Frame) {
                fmt.println("new game!")
            } }, { { point=.bottom, offset={0,-20} } })
    }

    { // how to play panel
        menu.tab_panel_htp = sl.add_frame(tab_content,
            { text="how to play panel", hidden=true, draw=draw_ui_border },
            { { point=.top_left }, { point=.bottom_right } })

        container := sl.add_frame(menu.tab_panel_htp,
            { scissor=true, layout={ dir=.down, scroll={ step=20 } } },
            { { point=.top_left, offset={20,20} }, { point=.bottom_right, offset={-20,-20} } })

        sl.add_frame(container, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("All roads lead to Nexus", f.rect, .anaheim_bold_32, {.top,.left}, colors.seven)
            f.size.y = text_rect.h
        } })
        sl.add_frame(container, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("Build roads from any existing node. Roads cannot be destroyed. Build mines, turrets, and plants on empty nodes. The Nexus node is given at the start of the game; if destroyed, the game ends.", f.rect, .anaheim_bold_32, {.top,.left}, colors.five)
            f.size.y = text_rect.h + 20
        } })
        sl.add_frame(container, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("Growing world", f.rect, .anaheim_bold_32, {.top,.left}, colors.seven)
            f.size.y = text_rect.h
        } })
        sl.add_frame(container, { draw=proc (f: ^sl.Frame) {
            text_rect := draw_text("The world expands every 3 minutes. Newly revealed areas contain enemy units that will attack your units and nodes. Maximize gold mining, and build turrets and plants for unit production.", f.rect, .anaheim_bold_32, {.top,.left}, colors.five)
            f.size.y = text_rect.h
        } })
    }

    { // info panel
        menu.tab_panel_info = sl.add_frame(tab_content,
            { text="info panel", hidden=true, draw=draw_ui_border },
            { { point=.top_left }, { point=.bottom_right } })

        container := sl.add_frame(menu.tab_panel_info,
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

    for text in ([] string { "Play", "How To Play", "Info", "Exit" }) {
        button := sl.add_frame(tab_bar, { text=text, draw=draw_ui_button, click=proc (f: ^sl.Frame) {
            menu := game.ui.main_menu
            switch f.text {
            case "Play"         : main_menu_panel_select_tab_panel(menu.tab_panel_play)
            case "How To Play"  : main_menu_panel_select_tab_panel(menu.tab_panel_htp)
            case "Info"         : main_menu_panel_select_tab_panel(menu.tab_panel_info)
            case "Exit"         : sl.show(menu.exit_dialog)
            }
        } })

        if text == "Play" do button.size.y = 65
        if text != "Exit" do button.radio = true
    }

    sl.add_frame(root, { size={150,40}, draw=proc (f: ^sl.Frame) {
        draw_text("by Spacemad", f.rect, .anaheim_bold_32, {.bottom,.right}, colors.three)
    } }, { { point=.bottom_right, offset={-25,-15} } })

    // select default tab
    sl.click(sl.find(tab_bar, "How To Play"))

    return root
}

main_menu_panel_select_tab_panel :: proc (tab_panel_frame: ^sl.Frame) {
    menu := game.ui.main_menu
    if menu.current_tab_panel != nil do sl.hide(menu.current_tab_panel)
    menu.current_tab_panel = tab_panel_frame
    sl.show(menu.current_tab_panel)
}

// -----------
// exit dialog
// -----------

add_main_menu_exit_dialog :: proc (parent: ^sl.Frame) -> ^sl.Frame {
    root := sl.add_frame(parent,
        { text=#procedure, order=10, hidden=true, modal=true, draw=draw_ui_dim_rect },
        { { point=.top_left }, { point=.bottom_right } })

    dialog := sl.add_frame(root, { size={440,220}, draw=draw_ui_panel }, { { point=.center } })

    sl.add_frame(dialog, { text="Exit the game?", size={0,120}, draw=proc (f: ^sl.Frame) {
        draw_text(f.text, f.rect, .anaheim_bold_32, {.center,.center}, colors.seven)
    } }, { { point=.top_left, offset={20,0} }, { point=.top_right, offset={-20,0} } })

    sl.add_frame(dialog, { size={150,50}, text="Yes", draw=draw_ui_button, click=proc (f: ^sl.Frame) {
        game.exit_requested = true
    } }, { { point=.bottom, offset={-90,-30} } })

    sl.add_frame(dialog, { size={150,50}, text="No", draw=draw_ui_button, click=proc (f: ^sl.Frame) {
        sl.hide(game.ui.main_menu.exit_dialog)
    } }, { { point=.bottom, offset={90,-30} } })

    return root
}
