package demo1

import "core:fmt"

main :: proc () {
    fmt.println("The demo is way too old to compile.")
    fmt.println("The demo might be removed from the repo in future.")
    fmt.println("All the code is commented out, please see the source if necessary.")
}

/*

import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:ui"
import "spacelib:raylib/draw"
import "spacelib:tracking_allocator"

Game :: struct {
    ui: ^ui.UI,
}

game: ^Game

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print_report_with_issues_only()

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 1")

    game = new(Game)
    game.ui = ui.create_ui(
        overdraw_proc = proc (f: ^ui.Frame) {
            draw.debug_frame(f)
        },
    )

    init_ui_quick_menu()
    init_ui_minimap()
    init_ui_task_tracker()
    init_ui_action_bar()
    init_ui_chat_window()
    init_ui_spell_book()

    for !rl.WindowShouldClose() {
        ui_root_rect := core.Rect { 10, 10, f32(rl.GetScreenWidth())-20, f32(rl.GetScreenHeight())-20 }
        ui.update_ui(game.ui, ui_root_rect, {})

        rl.BeginDrawing()
        rl.ClearBackground(rl.DARKGRAY)

        ui.draw_ui(game.ui)

        rl.EndDrawing()
        free_all(context.temp_allocator)
    }

    ui.destroy_ui(game.ui)
    free(game)

    rl.CloseWindow()
}

init_ui_quick_menu :: proc () {
    root := ui.add_frame(game.ui.root,
        { layout={ dir=.right, size={24,40}, gap=4 } },
        { point=.top_left },
    )

    for i in 0..<5 {
        button := ui.add_frame(root)
        if i == 0 do button.size = {64,64}
    }
}

init_ui_minimap :: proc () {
    root := ui.add_frame(game.ui.root, { name="minimap", size={200,200} })
    ui.add_anchor(root, { point=.top_right })
}

init_ui_task_tracker :: proc () {
    width :: 240
    gap_top := 40 + ui.get(game.ui.root, "minimap").size.y
    gap_bottom :: 200

    root := ui.add_frame(game.ui.root, { size={ width, 0 } })
    ui.add_anchor(root, { point=.top_right, offset={ 0, gap_top } })
    ui.add_anchor(root, { point=.bottom_right, offset={ 0, -gap_bottom } })
}

init_ui_action_bar :: proc () {
    root := ui.add_frame(game.ui.root,
        { layout={ dir=.left_and_right, align=.end, size={48,48}, gap=6, auto_size=true } },
        { point=.bottom },
    )

    for _ in 0..<8 do ui.add_frame(root)
}

init_ui_chat_window :: proc () {
    width, height :: 320, 200
    gap :: 10

    root := ui.add_frame(game.ui.root, { size={width,height} }, { point=.bottom_left })

    filter_bar := ui.add_frame(root,
        { size={0,32}, layout={ dir=.right, size={32,0}, gap=8 } },
        { offset={gap,gap} },
    )

    for _ in 0..<4 do ui.add_frame(filter_bar)

    input_bar := ui.add_frame(root, { size={0,32} },
        { point=.bottom_left, offset={gap,-gap} },
        { point=.bottom_right, offset={-gap,-gap} },
    )

    messages_area := ui.add_frame(root, {},
        { rel_point=.bottom_left, rel_frame=filter_bar, offset={0,gap} },
        { point=.bottom_right, rel_point=.top_right, rel_frame=input_bar, offset={0,-gap} },
    )

    ui.add_frame(messages_area, { size={16,0} },
        { point=.top_right, offset={-gap,gap} },
        { point=.bottom_right, offset={-gap,-gap} },
    )
}

init_ui_spell_book :: proc () {
    width, height :: 420, 380
    gap_top :: 80
    gap_inner :: 20
    gap_cat :: gap_inner/2
    button_size :: 40

    // root

    root := ui.add_frame(game.ui.root, { size={width,height} }, { offset={0,gap_top} })

    // categories

    categories := ui.add_frame(root,
        { layout={ dir=.down, size={button_size,button_size}, gap=gap_cat } },
        { rel_point=.top_right, offset={gap_cat,0} },
    )

    for _ in 0..<3 do ui.add_frame(categories)

    // pagination

    pag_height :: 32

    ui.add_frame(root, { size={80,pag_height} }, { point=.bottom, offset={0,-gap_inner} })
    ui.add_frame(root, { size={pag_height,pag_height} }, { point=.bottom_left, offset={gap_inner,-gap_inner} })
    ui.add_frame(root, { size={pag_height,pag_height} }, { point=.bottom_right, offset={-gap_inner,-gap_inner} })

    // spell columns

    col1 := ui.add_frame(root, {},
        { offset={gap_inner,gap_inner} },
        { point=.bottom_right, rel_point=.bottom, offset={-gap_inner/2,-pag_height-2*gap_inner} },
    )

    col2 := ui.add_frame(root, {},
        { point=.top_right, offset={-gap_inner,gap_inner} },
        { point=.bottom_left, rel_point=.bottom_right, rel_frame=col1, offset={gap_inner,0} },
    )

    // spell cards

    icon_size :: 48
    text_height :: 32
    card_gap :: 20

    for col in ([] ^ui.Frame { col1, col2 }) {
        for i in 0..<4 {
            card := ui.add_frame(col, {}, { offset={0,f32(i)*(icon_size+card_gap)} })
            icon := ui.add_frame(card, { size={icon_size,icon_size} }, {})
            ui.add_frame(icon, { size={0,text_height} },
                { point=.right, rel_frame=col },
                { point=.left, rel_point=.right, offset={10,0} },
            )
        }
    }
}

*/
