package demo4

import "core:fmt"
import rl "vendor:raylib"
import sl "../spacelib"
import sl_rl "../spacelib/raylib"
import sl_ta "../spacelib/tracking_allocator"

Game :: struct {
    time: f32,
    frame_time: f32,
    screen_rect: sl.Rect,
    camera: rl.Camera2D,

    ui: struct {
        manager: ^sl.Manager,
        main_menu: ^Main_Menu,
    },

    debug_drawing: bool,
    exit_requested: bool,
}

game: ^Game

create_game :: proc () {
    fmt.println(#procedure)
    assert(game == nil)

    game = new(Game)
    game.camera = { zoom=1 }

    game.ui.manager = sl.create_manager(
        scissor_set_proc = proc (r: sl.Rect) {
            if game.debug_drawing do return
            rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h))
        },
        scissor_clear_proc = proc () {
            if game.debug_drawing do return
            rl.EndScissorMode()
        },
        overdraw_proc = proc (f: ^sl.Frame) {
            if !game.debug_drawing do return
            sl_rl.debug_draw_frame(f)
            sl_rl.debug_draw_frame_layout(f)
            sl_rl.debug_draw_frame_anchors(f)
        },
    )

    create_main_menu()

    sl.print_frame_tree(game.ui.manager.root)
}

destroy_game :: proc () {
    fmt.println(#procedure)

    destroy_main_menu()
    sl.destroy_manager(game.ui.manager)

    free(game)
    game = nil
}

game_tick :: proc () {
    free_all(context.temp_allocator)
    game.time = f32(rl.GetTime())
    game.frame_time = rl.GetFrameTime()
    game.screen_rect = { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) }
    game.camera.offset = { game.screen_rect.w/2, game.screen_rect.h/2 }
}

main :: proc () {
    context.allocator = sl_ta.init()
    defer sl_ta.print_report()

    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 4")

    load_assets()
    create_game()

    for !rl.WindowShouldClose() && !game.exit_requested {
        game_tick()

        mouse_input := sl.Mouse_Input { rl.GetMousePosition(), rl.GetMouseWheelMove(), rl.IsMouseButtonDown(.LEFT) }
        mouse_input_consumed := sl.update_manager(game.ui.manager, game.screen_rect, mouse_input)
        if !mouse_input_consumed {
            // fmt.printfln("[world] %v", mouse_input)
        }

        game.debug_drawing = rl.IsKeyDown(.LEFT_CONTROL)

        rl.BeginDrawing()
        rl.ClearBackground(colors.one)

        rl.BeginMode2D(game.camera)
        // draw_world()
        rl.EndMode2D()

        sl.draw_manager(game.ui.manager)

        if game.debug_drawing {
            rect := rl.Rectangle { 10, game.screen_rect.h-200-10, 280, 200 }
            rl.DrawRectangleRec(rect, { 40, 10, 20, 255 })
            rl.DrawRectangleLinesEx(rect, 2, rl.RED)
            rl.DrawFPS(i32(rect.x+10), i32(rect.y+10))
            cstr := fmt.ctprintf("%#v", game.ui.manager.stats)
            rl.DrawText(cstr, i32(rect.x+10), i32(rect.y+30), 20, rl.GREEN)
        }

        rl.EndDrawing()
    }

    destroy_game()
    unload_assets()

    rl.CloseWindow()
}
