package demo3

import "core:fmt"
import rl "vendor:raylib"
import sl "../spacelib"
import sl_rl "../spacelib_raylib"

Game :: struct {
    ui: struct {
        manager: ^sl.Manager,
        frame1: ^sl.Frame,
        frame2: ^sl.Frame,
    }
}

game: ^Game

main :: proc () {
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 3")

    game = new(Game)
    game.ui.manager = sl.create_manager()
    game.ui.manager.default_draw_proc = sl_rl.debug_draw_frame

    init_ui()

    for !rl.WindowShouldClose() {
        screen_w, screen_h := f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())
        mouse_pos, mouse_lmb_down := rl.GetMousePosition(), rl.IsMouseButtonDown(.LEFT)
        sl.update_manager(game.ui.manager, { 10, 10, screen_w-20, screen_h-20 }, { mouse_pos, mouse_lmb_down })

        rl.BeginDrawing()
        rl.ClearBackground(rl.DARKGRAY)

        sl.draw_manager(game.ui.manager)
        if !game.ui.manager.mouse_consumed {
            fmt.printfln("[world] pos=%v lmb=%v", mouse_pos, mouse_lmb_down)
        }

        rl.EndDrawing()
        free_all(context.temp_allocator)
    }

    sl.destroy_manager(game.ui.manager)
    free(game)

    rl.CloseWindow()
}

menu_button_info: map[^sl.Frame] struct {
    index: int,
    point: sl.Anchor_Point,
    is_rel: bool,
}

init_ui :: proc () {
    ui := &game.ui

    ui.frame1 = sl.add_frame({ parent=ui.manager.root, text="Frame 1", size={ 400, 300 } })
    sl.add_anchor(ui.frame1, { point=.center })

    ui.frame2 = sl.add_frame({ parent=ui.manager.root, text="Frame 2", size={ 140, 100 } })
    sl.add_anchor(ui.frame2, { point=.center, rel_frame=ui.frame1 })

    init_ui_anchor_menu(0)
    init_ui_anchor_menu(1)
}

init_ui_anchor_menu :: proc (anchor_index: int) {
    ui := &game.ui

    button_size := sl.Vec2 { 80, 20 }

    menu := sl.add_frame({ parent=ui.manager.root })
    sl.add_anchor(menu, { offset={ 30 + f32(anchor_index)*180, 80 } })

    prev_item: ^sl.Frame
    for p in sl.Anchor_Point {
        item := sl.add_frame({ parent=menu, text=fmt.aprint(p), size=button_size, draw=draw_menu_point, click=click_menu_point })
        sl.add_anchor(item, { rel_point=.bottom_left, rel_frame=prev_item })

        item_rel := sl.add_frame({ parent=menu, text=fmt.aprint(p), size=button_size, draw=draw_menu_point, click=click_menu_point })
        sl.add_anchor(item_rel, { rel_point=.top_right, rel_frame=item })

        if p == .none {
            title := sl.add_frame({ parent=menu, text=fmt.aprintf("anchor %d", anchor_index) })
            sl.add_anchor(title, { rel_frame=item, offset={ 0, -50 } })

            label := sl.add_frame({ parent=menu, text="point" })
            sl.add_anchor(label, { rel_frame=item, offset={ 0, -20 } })

            label_rel := sl.add_frame({ parent=menu, text="rel_point" })
            sl.add_anchor(label_rel, { rel_frame=item_rel, offset={ 0, -20 } })
        }

        menu_button_info[item] = { anchor_index, p, false }
        menu_button_info[item_rel] = { anchor_index, p, true }

        prev_item = item
    }
}

draw_menu_point :: proc (f: ^sl.Frame) {
    sl_rl.debug_draw_frame(f)
    info := menu_button_info[f]

    if info.index < len(game.ui.frame2.anchors) {
        frame_anchor := &game.ui.frame2.anchors[info.index]
        frame_anchor_point := info.is_rel ? frame_anchor.rel_point : frame_anchor.point
        if info.point == frame_anchor_point {
            rl.DrawCircle(i32(f.rect.x+f.rect.w-10), i32(f.rect.y+f.rect.h/2), 5, rl.YELLOW)
        }
    }
}

click_menu_point :: proc (f: ^sl.Frame) {
    info := menu_button_info[f]
    if info.index == 0 {
        if info.point != .none {
            frame_anchor := &game.ui.frame2.anchors[info.index]
            frame_anchor_point := info.is_rel ? &frame_anchor.rel_point : &frame_anchor.point
            frame_anchor_point^ = info.point
        }
    } else if info.index == 1 {
        if info.point == .none {
            resize(&game.ui.frame2.anchors, 1)
        } else {
            if len(game.ui.frame2.anchors) < 2 {
                sl.add_anchor(game.ui.frame2, { point=info.point, rel_frame=game.ui.frame1 })
            } else {
                frame_anchor := &game.ui.frame2.anchors[1]
                frame_anchor_point := info.is_rel ? &frame_anchor.rel_point : &frame_anchor.point
                frame_anchor_point^ = info.point
            }
        }
    }
}
