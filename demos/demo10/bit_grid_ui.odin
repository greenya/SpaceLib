package demo10

import "core:fmt"
import "spacelib:ui"

bit_grid_ui_add :: proc (tab_parent, content_parent: ^ui.Frame) {
    _, content := ui_add_tab_and_content(tab_parent, content_parent, "Bit Grid")

    grid := ui.add_frame(content,
        { layout=ui.Grid { wrap=8, auto_size={.height} } },
    )

    for i in 0..<8*8 do ui.add_frame(grid, {
        flags       = {.terse,.check},
        text        = fmt.tprint(i),
        selected    = 0 < bit_grid.board & (1<<u8(i)),
        draw        = draw_grid_bit,
        click       = proc (f: ^ui.Frame) {
            bit_grid_set_bit(ui.index(f), f.selected)
        },
    })

    ui.add_frame(content, {
        flags={.terse,.terse_height},
        text=fmt.tprintf("<wrap,pad=12>The state stored in \"%s\".", bit_grid_file),
    })
}
