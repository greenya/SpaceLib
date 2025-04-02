package demo4

import "core:fmt"
import sl "../spacelib"
import sl_rl "../spacelib/raylib"

Main_Menu :: struct {
    menu_panel: ^sl.Frame,
    exit_dialog: ^sl.Frame,
}

create_main_menu :: proc (parent: ^sl.Frame) -> ^Main_Menu {
    menu := new(Main_Menu)
    menu.menu_panel = add_main_menu_panel(parent)
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

add_main_menu_panel :: proc (parent: ^sl.Frame) -> ^sl.Frame {
    root := sl.add_frame({ parent=parent, solid=true, name="Main Menu", size={480,480}, draw=proc (f: ^sl.Frame) {
        draw_sprite(.panel_3, f.rect, colors.one)
    } })
    sl.add_anchor(root, { point=.center })

    title := sl.add_frame({ parent=root, size={0,120}, draw=proc (f: ^sl.Frame) {
        draw_text_centered("Demo IV", sl.rect_center(f.rect), .anaheim_bold_64, colors.seven)
    } })
    sl.add_anchor(title, { point=.top, offset={0,15} })

    rel_frame := title
    for name, i in ([] string { "Play", "How To Play", "Info", "Options", "Exit" }) {
        button := sl.add_frame({ parent=root, name=name, size={200,50}, draw=draw_ui_button, click=proc (f: ^sl.Frame) {
            fmt.println("click!", f.name)
            switch f.name {
            case "Exit": sl.show(game.main_menu.exit_dialog)
            }
        } })
        sl.add_anchor(button, { point=.top, rel_point=.bottom, rel_frame=rel_frame, offset=i > 0 ? {0,10} : {} })
        rel_frame = button
    }

    return root
}

// -----------
// exit dialog
// -----------

add_main_menu_exit_dialog :: proc (parent: ^sl.Frame) -> ^sl.Frame {
    root := sl.add_frame({ parent=parent, solid=true, hidden=true, name="Exit Dialog", draw=draw_ui_dim_rect })
    sl.add_anchor(root, { point=.top_left })
    sl.add_anchor(root, { point=.bottom_right })

    dialog := sl.add_frame({ parent=root, size={440,220}, draw=draw_ui_panel })
    sl.add_anchor(dialog, { point=.center })

    title := sl.add_frame({ parent=dialog, size={0,80}, draw=proc (f: ^sl.Frame) {
        draw_text_centered("Exit the game?", sl.rect_center(f.rect), .anaheim_bold_32, colors.seven)
    } })
    sl.add_anchor(title, { point=.top, offset={0,15} })

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
