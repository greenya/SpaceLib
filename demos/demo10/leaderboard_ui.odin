package demo10

import "core:fmt"
import "spacelib:ui"

leaderboard_ui_table: ^ui.Frame

leaderboard_ui_add :: proc (tab_parent, content_parent: ^ui.Frame) {
    _, content := ui_add_tab_and_content(tab_parent, content_parent, "Leaderboard")

    bar := ui.add_frame(content, {
        layout=ui.Flow { dir=.right_center, gap=20, auto_size={.height} },
    })

    ui.add_frame(bar, {
        flags={.terse, .terse_size},
        text="<pad=10>Add 1 Row",
        draw=draw_button,
        click=proc (f: ^ui.Frame) {
            leaderboard_gen_new_rows(count=1)
            leaderboard_ui_refresh_table()
        },
    })

    ui.add_frame(bar, {
        flags={.terse, .terse_size},
        text="<pad=10>Add 10 Rows",
        draw=draw_button,
        click=proc (f: ^ui.Frame) {
            leaderboard_gen_new_rows(count=10)
            leaderboard_ui_refresh_table()
        },
    })

    ui.add_frame(bar, {
        flags={.terse, .terse_size},
        text="<pad=10>Clear All",
        draw=draw_button,
        click=proc (f: ^ui.Frame) {
            leaderboard_clear_rows()
            leaderboard_ui_refresh_table()
        },
    })

    ui.add_frame(content, { size={0,20} })
    assert(leaderboard_ui_table == nil)
    leaderboard_ui_table = ui.add_frame(content, {
        layout=ui.Flow { dir=.down, pad={20,20,10,10}, auto_size={.height} },
        draw=draw_leaderboard_bg,
    })

    leaderboard_ui_refresh_table()

    ui.add_frame(content, { size={0,10} })
    ui.add_frame(content, {
        flags={.terse,.terse_height},
        text=fmt.tprintf("<wrap,pad=8>The state stored in \"%s\".", leaderboard_file_name),
    })
}

leaderboard_ui_refresh_table :: proc () {
    assert(leaderboard_ui_table != nil)
    ui.destroy_frame_children(leaderboard_ui_table)

    if len(leaderboard.rows) > 0 {
        for row, i in leaderboard.rows do ui.add_frame(leaderboard_ui_table, {
            flags={.terse,.terse_height},
            text=fmt.tprintf(
                "<left,font=%s>%02i.<tab=80>%06i<tab=250>%s",
                i<3?"5":"4", i+1, row.score, row.name,
            ),
        })
    } else {
        ui.add_frame(leaderboard_ui_table, {
            flags={.terse,.terse_height},
            text="[ List is empty ]",
        })
    }

    ui.update(leaderboard_ui_table)
}
