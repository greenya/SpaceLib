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
    root := sl.add_frame({ parent=parent, name="Main Menu", size={680,480}, draw=proc (f: ^sl.Frame) {
        draw_sprite(.panel_3, f.rect, colors.two)
    } })
    sl.add_anchor(root, { point=.center })
    // sl.add_anchor(root, { point=.top_left, offset={250,100} })
    // sl.add_anchor(root, { point=.bottom_right, offset={-250,-100} })

    title := sl.add_frame({ parent=root, size={0,120}, draw=proc (f: ^sl.Frame) {
        draw_text("Roads to Power", f.rect, .anaheim_bold_64, {.center,.center}, colors.seven)
    } })
    sl.add_anchor(title, { point=.top_left, offset={0,20} })
    sl.add_anchor(title, { point=.top_right, offset={0,20} })

    tab_content := sl.add_frame({ parent=root, draw=draw_ui_border })
    sl.add_anchor(tab_content, { point=.top_left, rel_point=.bottom_left, rel_frame=title, offset={25,0} })
    sl.add_anchor(tab_content, { point=.bottom_right, offset={-25-200,-25} })

    for &tab_panel_frame in ([] ^^sl.Frame { &menu.tab_panel_play, &menu.tab_panel_htp, &menu.tab_panel_info }) {
        tab_panel_frame^ = sl.add_frame({ parent=tab_content, draw=proc (f: ^sl.Frame) {
            switch f {
            case game.main_menu.tab_panel_play:
                // todo: add play panel content
            case game.main_menu.tab_panel_htp:
                // todo: scroll area
                rect := sl.rect_inflated(f.rect, {-30,0})
                draw_scissor_start(rect)
                defer draw_scissor_end()
                font := Font_ID.anaheim_bold_32
                rect = sl.rect_moved(rect, {0,15})
                line_rect := draw_text("All roads lead to Nexus", rect, font, {}, colors.seven)
                rect = sl.rect_moved(rect, {0,line_rect.h})
                line_rect = draw_text("Build roads from any existing node. Roads cannot be destroyed. Build mines, turrets, and plants on empty nodes. The Nexus node is given at the start of the game; if destroyed, the game ends.", rect, font, {}, colors.five)
                rect = sl.rect_moved(rect, {0,line_rect.h+15})
                line_rect = draw_text("Growing world", rect, font, {}, colors.seven)
                rect = sl.rect_moved(rect, {0,line_rect.h})
                draw_text("The world expands every 3 minutes. Newly revealed areas contain enemy units that will attack your units and nodes. Maximize gold mining, and build turrets and plants for unit production.", rect, font, {}, colors.five)
            case game.main_menu.tab_panel_info:
                // todo: add info panel content
            }
        } })
        sl.add_anchor(tab_panel_frame^, { point=.top_left })
        sl.add_anchor(tab_panel_frame^, { point=.bottom_right })
    }

    tab_bar := sl.add_frame({ parent=root })
    sl.add_anchor(tab_bar, { point=.top_left, rel_point=.top_right, rel_frame=tab_content, offset={15,0} })
    sl.add_anchor(tab_bar, { point=.bottom_right, offset={-25,-25} })

    prev_button: ^sl.Frame
    for name in ([] string { "Play", "How To Play", "Info", "Exit" }) {
        button := sl.add_frame({ parent=tab_bar, name=name, size={0,50}, draw=draw_ui_button, click=proc (f: ^sl.Frame) {
            fmt.println("click!", f.name)
            switch f.name {
            case "Exit": sl.show(game.main_menu.exit_dialog)
            }
        } })

        if prev_button == nil {
            sl.add_anchor(button, { point=.top_left })
            sl.add_anchor(button, { point=.top_right })
        } else {
            sl.add_anchor(button, { point=.top_left, rel_point=.bottom_left, rel_frame=prev_button, offset={0,10} })
            sl.add_anchor(button, { point=.top_right, rel_point=.bottom_right, rel_frame=prev_button, offset={0,10} })
        }

        prev_button = button
    }

    by_text := sl.add_frame({ parent=tab_bar, size={0,40}, draw=proc (f: ^sl.Frame) {
        draw_text("by Spacemad ", f.rect, .anaheim_bold_32, {.bottom,.right}, colors.three)
    } })
    sl.add_anchor(by_text, { point=.bottom_left })
    sl.add_anchor(by_text, { point=.bottom_right })

    return root
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
