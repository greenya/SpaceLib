package demo1

import "core:fmt"
import rl "vendor:raylib"
import sl "../spacelib"
import sl_rl "../spacelib_raylib"

Game :: struct {
    ui: struct {
        root: ^sl.Frame,
    }
}

game: ^Game

main :: proc () {
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 1")

    game = new(Game)
    game.ui.root = sl.add_frame({})
    sl.default_draw_proc = sl_rl.draw_frame_debug

    init_ui_quick_menu()
    init_ui_minimap()
    init_ui_task_tracker()
    init_ui_action_bar()
    init_ui_chat_window()
    init_ui_spell_book()

    for !rl.WindowShouldClose() {
        sl.update_frame_tree(game.ui.root)

        rl.BeginDrawing()
        rl.ClearBackground(rl.DARKGRAY)

        game.ui.root.rect = { 10, 10, f32(rl.GetScreenWidth())-20, f32(rl.GetScreenHeight())-20 }
        sl.draw_frame_tree(game.ui.root)

        rl.EndDrawing()
        free_all(context.temp_allocator)
    }

    sl.destroy_frame_tree(game.ui.root)
    free(game)

    rl.CloseWindow()
}

init_ui_quick_menu :: proc () {
    root := sl.add_frame({ parent=game.ui.root })
    sl.add_anchor(root, {})

    count :: 5
    button_w, button_h :: 24, 40
    button_big_w, button_big_h :: 64, 64
    gap :: 4

    prev_rel_frame := root
    for i in 0..<count {
        button := sl.add_frame({ parent=root, size={ button_w, button_h } })
        sl.add_anchor(button, { rel_point=.top_right, rel_frame=prev_rel_frame, offset={ i == 0 ? 0 : gap, 0 } })
        if i == 0 do button.size = { button_big_w, button_big_h }
        prev_rel_frame = button
    }
}

init_ui_minimap :: proc () {
    size :: 200
    root := sl.add_frame({ parent=game.ui.root, size={ size, size } })
    sl.add_anchor(root, { point=.top_right })
}

init_ui_task_tracker :: proc () {
    width :: 240
    gap_top, gap_bottom :: 240, 200

    root := sl.add_frame({ parent=game.ui.root, size={ width, 0 } })
    sl.add_anchor(root, { point=.top_right, offset={ 0, gap_top } })
    sl.add_anchor(root, { point=.bottom_right, offset={ 0, -gap_bottom } })
}

init_ui_action_bar :: proc () {
    gap :: 6
    button_size :: 48
    button_count :: 8
    bar_width :: button_count * (button_size+gap) + gap

    root := sl.add_frame({ parent=game.ui.root, size={ bar_width, 0 } })
    sl.add_anchor(root, { point=.bottom })

    for i in 0..<button_count {
        button := sl.add_frame({ parent=root, size={ button_size, button_size } })
        sl.add_anchor(button, { point=.bottom_left, offset={ gap + (gap+button_size)*f32(i), 0 } })
    }
}

init_ui_chat_window :: proc () {
    width, height :: 320, 200
    gap :: 10

    root := sl.add_frame({ parent=game.ui.root, size={ width, height } })
    sl.add_anchor(root, { point=.bottom_left })

    filter_bar := sl.add_frame({ parent=root, size={ 0, 32 } })
    sl.add_anchor(filter_bar, { offset={ gap, gap } })
    for i in 0..<4 {
        button_size :: 32
        button := sl.add_frame({ parent=filter_bar, size={ button_size, button_size } })
        sl.add_anchor(button, { offset={ f32(i)*(button_size+8), 0 } })
    }

    input_bar := sl.add_frame({ parent=root, size={ 0, 32 } })
    sl.add_anchor(input_bar, { point=.bottom_left, offset={ gap, -gap } })
    sl.add_anchor(input_bar, { point=.bottom_right, offset={ -gap, -gap } })

    messages_area := sl.add_frame({ parent=root })
    sl.add_anchor(messages_area, { rel_point=.bottom_left, rel_frame=filter_bar, offset={ 0, gap } })
    sl.add_anchor(messages_area, { point=.bottom_right, rel_point=.top_right, rel_frame=input_bar, offset={ 0, -gap } })

    scroll_bar := sl.add_frame({ parent=messages_area, size={ 16, 0 } })
    sl.add_anchor(scroll_bar, { point=.top_right, offset={ -gap, gap } })
    sl.add_anchor(scroll_bar, { point=.bottom_right, offset={ -gap, -gap } })
}

init_ui_spell_book :: proc () {
    width, height :: 420, 380
    gap_top :: 80
    gap_inner :: 20
    gap_cat :: gap_inner/2
    button_size :: 40

    // root

    root := sl.add_frame({ parent=game.ui.root, size={ width, height } })
    sl.add_anchor(root, { offset={ 0, gap_top } })

    // categories

    prev_rel_frame := root
    for i in 0..<3 {
        button := sl.add_frame({ parent=root, size={ button_size, button_size } })
        if i == 0 {
            sl.add_anchor(button, { rel_point=.top_right, offset={ gap_cat, 0 } })
        } else {
            sl.add_anchor(button, { rel_point=.bottom_left, rel_frame=prev_rel_frame, offset={ 0, gap_cat } })
        }
        prev_rel_frame = button
    }

    // pagination

    pag_height :: 32

    page_current := sl.add_frame({ parent=root, size={ 80, pag_height } })
    sl.add_anchor(page_current, { point=.bottom, offset={ 0, -gap_inner } })

    page_prev := sl.add_frame({ parent=root, size={ pag_height, pag_height } })
    sl.add_anchor(page_prev, { point=.bottom_left, offset={ gap_inner, -gap_inner } })

    page_next := sl.add_frame({ parent=root, size={ pag_height, pag_height } })
    sl.add_anchor(page_next, { point=.bottom_right, offset={ -gap_inner, -gap_inner } })

    // spell columns

    col1 := sl.add_frame({ parent=root })
    sl.add_anchor(col1, { offset={ gap_inner, gap_inner } })
    sl.add_anchor(col1, { point=.bottom_right, rel_point=.bottom, offset={ -gap_inner/2, -pag_height - 2*gap_inner } })

    col2 := sl.add_frame({ parent=root })
    sl.add_anchor(col2, { point=.top_right, offset={ -gap_inner, gap_inner } })
    sl.add_anchor(col2, { point=.bottom_left, rel_point=.bottom_right, rel_frame=col1, offset={ gap_inner, 0 } })

    // spell cards

    icon_size :: 48
    text_height :: 32
    card_gap :: 20

    for col in ([] ^sl.Frame { col1, col2 }) {
        for i in 0..<4 {
            card := sl.add_frame({ parent=col })
            sl.add_anchor(card, { offset={ 0, f32(i)*(icon_size+card_gap) } })

            icon := sl.add_frame({ parent=card, size={ icon_size, icon_size } })
            sl.add_anchor(icon, {})

            text := sl.add_frame({ parent=icon, size={ 0, text_height } })
            sl.add_anchor(text, { point=.right, rel_frame=col })
            sl.add_anchor(text, { point=.left, rel_point=.right, offset={ 10, 0 } })
        }
    }
}
