package demo4

import "core:fmt"
import sl "../spacelib"
import sl_rl "../spacelib/raylib"

Main_Menu :: struct {
    menu_panel: ^sl.Frame,

    current_tab_panel: ^sl.Frame,
    tab_panel_play: ^sl.Frame,
    tab_panel_htp: ^sl.Frame,
    tab_panel_info: ^sl.Frame,

    exit_dialog: ^sl.Frame,
}

create_main_menu :: proc (parent: ^sl.Frame) -> ^Main_Menu {
    menu := new(Main_Menu)
    menu.menu_panel = add_main_menu_panel(parent, menu)
    menu.exit_dialog = add_main_menu_exit_dialog(parent)
    return menu
}

destroy_main_menu :: proc (menu: ^Main_Menu) {
    free(menu)
    menu^ = {}
}

// ----------
// menu panel
// ----------

add_main_menu_panel :: proc (parent: ^sl.Frame, menu: ^Main_Menu) -> ^sl.Frame {
    root := sl.add_frame({ parent=parent, name="Main Menu", size={720,480}, draw=proc (f: ^sl.Frame) {
        draw_sprite(.panel_3, f.rect, colors.two)
    } })
    // sl.add_anchor(root, { point=.center })
    sl.add_anchor(root, { point=.top_left, offset={250,100} })
    sl.add_anchor(root, { point=.bottom_right, offset={-250,-100} })

    title_bar := sl.add_frame({ parent=root, size={0,120}, draw=proc (f: ^sl.Frame) {
        draw_text("Roads to Power", f.rect, .anaheim_bold_64, {.center,.center}, colors.seven)
    } })
    sl.add_anchor(title_bar, { point=.top_left, offset={0,20} })
    sl.add_anchor(title_bar, { point=.top_right, offset={0,20} })

    tab_content := sl.add_frame({ parent=root })
    sl.add_anchor(tab_content, { point=.top_left, rel_point=.bottom_left, rel_frame=title_bar, offset={25,0} })
    sl.add_anchor(tab_content, { point=.bottom_right, offset={-25-200,-25} })

    for &tab_panel_frame in ([] ^^sl.Frame { &menu.tab_panel_play, &menu.tab_panel_htp, &menu.tab_panel_info }) {
        tab_panel_frame^ = sl.add_frame({ parent=tab_content, hidden=true, scissor=true, draw=proc (f: ^sl.Frame) {
            switch f {
            case game.main_menu.tab_panel_play:
                // todo: add play panel content
            case game.main_menu.tab_panel_htp:
                // todo: scroll area
                rect := sl.rect_inflated(f.rect, {-30,0})
                font := Font_ID.anaheim_bold_32
                rect = sl.rect_moved(rect, {0,15})
                text_rect := draw_text("All roads lead to Nexus", rect, font, {}, colors.seven)
                rect = sl.rect_moved(rect, {0,text_rect.h})
                text_rect = draw_text("Build roads from any existing node. Roads cannot be destroyed. Build mines, turrets, and plants on empty nodes. The Nexus node is given at the start of the game; if destroyed, the game ends.", rect, font, {}, colors.five)
                rect = sl.rect_moved(rect, {0,text_rect.h+15})
                text_rect = draw_text("Growing world", rect, font, {}, colors.seven)
                rect = sl.rect_moved(rect, {0,text_rect.h})
                draw_text("The world expands every 3 minutes. Newly revealed areas contain enemy units that will attack your units and nodes. Maximize gold mining, and build turrets and plants for unit production.", rect, font, {}, colors.five)
            case game.main_menu.tab_panel_info:
                // todo: add info panel content
                // rect := sl.rect_inflated(f.rect, {-30,0})
                // font := Font_ID.anaheim_bold_32
                // rect = sl.rect_moved(rect, {0,15})
                // text_rect := draw_text("The game is made for Odin 7 Day Jam by Spacemad using Odin and Raylib.", rect, font, {.top,.center}, colors.seven)
            }
            draw_ui_border(f)
        } })
        sl.add_anchor(tab_panel_frame^, { point=.top_left })
        sl.add_anchor(tab_panel_frame^, { point=.bottom_right })

        if tab_panel_frame == &menu.tab_panel_info {
            text_top := sl.add_frame({ parent=tab_panel_frame^, draw=proc (f: ^sl.Frame) {
                text_rect := draw_text("The game is made for Odin 7 Day Jam by Spacemad using Odin and Raylib.", f.rect, .anaheim_bold_32, {.top,.center}, colors.seven)
                f.size.y = text_rect.h
            } })
            sl.add_anchor(text_top, { point=.top_left, offset={30,15} })
            sl.add_anchor(text_top, { point=.top_right, offset={-30,15} })

            btn_open_jam := sl.add_frame({ parent=tab_panel_frame^, size={250,50}, name="Open Jam page", draw=draw_ui_button })
            sl.add_anchor(btn_open_jam, { point=.top, rel_point=.bottom, rel_frame=text_top, offset={0,20} })

            btn_open_game := sl.add_frame({ parent=tab_panel_frame^, size={250,50}, name="Open Game page", draw=draw_ui_button })
            sl.add_anchor(btn_open_game, { point=.top, rel_point=.bottom, rel_frame=btn_open_jam, offset={0,10} })

            btn_open_odin := sl.add_frame({ parent=tab_panel_frame^, size={250,50}, name="Open Odin page", draw=draw_ui_button })
            sl.add_anchor(btn_open_odin, { point=.top, rel_point=.bottom, rel_frame=btn_open_game, offset={0,10} })

            btn_open_raylib := sl.add_frame({ parent=tab_panel_frame^, size={250,50}, name="Open Raylib page", draw=draw_ui_button })
            sl.add_anchor(btn_open_raylib, { point=.top, rel_point=.bottom, rel_frame=btn_open_odin, offset={0,10} })

            text_bottom := sl.add_frame({ parent=tab_panel_frame^, draw=proc (f: ^sl.Frame) {
                text_rect := draw_text("Thank you for playing <3", f.rect, .anaheim_bold_32, {.top,.center}, colors.seven)
                f.size = { f.parent.children[0].rect.w, text_rect.h }
            } })
            sl.add_anchor(text_bottom, { point=.top, rel_point=.bottom, rel_frame=btn_open_raylib, offset={0,20} })
        }
    }

    tab_bar := sl.add_frame({ parent=root })
    sl.add_anchor(tab_bar, { point=.top_left, rel_point=.top_right, rel_frame=tab_content, offset={15,0} })
    sl.add_anchor(tab_bar, { point=.top_right, rel_point=.bottom_right, rel_frame=title_bar, offset={-25,0} })

    prev_button: ^sl.Frame
    for name in ([] string { "Play", "How To Play", "Info", "Exit" }) {
        button := sl.add_frame({ parent=tab_bar, name=name, size={0,50}, draw=draw_ui_button, click=proc (f: ^sl.Frame) {
            menu := game.main_menu
            switch f.name {
            case "Play"         : main_menu_panel_select_tab_panel(menu.tab_panel_play)
            case "How To Play"  : main_menu_panel_select_tab_panel(menu.tab_panel_htp)
            case "Info"         : main_menu_panel_select_tab_panel(menu.tab_panel_info)
            case "Exit"         : sl.show(menu.exit_dialog)
            }
        } })

        if name != "Exit" do button.radio = true

        if prev_button == nil {
            sl.add_anchor(button, { point=.top_left })
            sl.add_anchor(button, { point=.top_right })
        } else {
            sl.add_anchor(button, { point=.top_left, rel_point=.bottom_left, rel_frame=prev_button, offset={0,10} })
            sl.add_anchor(button, { point=.top_right, rel_point=.bottom_right, rel_frame=prev_button, offset={0,10} })
        }

        prev_button = button
    }

    by_text := sl.add_frame({ parent=root, size={150,40}, draw=proc (f: ^sl.Frame) {
        draw_text("by Spacemad", f.rect, .anaheim_bold_32, {.bottom,.right}, colors.three)
    } })
    sl.add_anchor(by_text, { point=.bottom_right, offset={-25,-15} })

    // select default tab
    sl.find(tab_bar, "Info").selected = true
    main_menu_panel_select_tab_panel(menu.tab_panel_info, menu)

    return root
}

main_menu_panel_select_tab_panel :: proc (tab_panel_frame: ^sl.Frame, menu: ^Main_Menu = nil) {
    menu := menu
    if menu == nil do menu = game.main_menu

    if menu.current_tab_panel != nil do sl.hide(menu.current_tab_panel)
    menu.current_tab_panel = tab_panel_frame
    sl.show(tab_panel_frame)
}

// -----------
// exit dialog
// -----------

add_main_menu_exit_dialog :: proc (parent: ^sl.Frame) -> ^sl.Frame {
    root := sl.add_frame({ parent=parent, hidden=true, name="Exit Dialog", draw=draw_ui_dim_rect })
    sl.add_anchor(root, { point=.top_left })
    sl.add_anchor(root, { point=.bottom_right })

    dialog := sl.add_frame({ parent=root, size={440,220}, draw=draw_ui_panel })
    sl.add_anchor(dialog, { point=.center })

    title := sl.add_frame({ parent=dialog, size={0,120}, draw=proc (f: ^sl.Frame) {
        draw_text("Exit the game?", f.rect, .anaheim_bold_32, {.center,.center}, colors.seven)
    } })
    sl.add_anchor(title, { point=.top_left, offset={20,0} })
    sl.add_anchor(title, { point=.top_right, offset={-20,0} })

    yes_button := sl.add_frame({ parent=dialog, name="Yes", size={150,50}, draw=draw_ui_button, click=proc (f: ^sl.Frame) {
        game.exit_requested = true
    } })
    sl.add_anchor(yes_button, { point=.bottom, offset={-90,-30} })

    no_button := sl.add_frame({ parent=dialog, name="No", size={150,50}, draw=draw_ui_button, click=proc (f: ^sl.Frame) {
        sl.hide(game.main_menu.exit_dialog)
    } })
    sl.add_anchor(no_button, { point=.bottom, offset={90,-30} })

    return root
}
