package demo4

import "core:fmt"
import rl "vendor:raylib"
import sl "../spacelib"
import sl_rl "../spacelib/raylib"

Game :: struct {
    time: f32,
    frame_time: f32,
    screen_rect: sl.Rect,
    camera: rl.Camera2D,

    ui_manager: ^sl.Manager,
    main_menu: ^Main_Menu,

    exit_requested: bool,
}

game: ^Game

create_game :: proc () {
    assert(game == nil)

    game = new(Game)
    game.camera = { zoom=1 }
    game.ui_manager = sl.create_manager(
        scissor_start_proc = proc (f: ^sl.Frame) {
            rl.BeginScissorMode(i32(f.rect.x), i32(f.rect.y), i32(f.rect.w), i32(f.rect.h))
        },
        scissor_end_proc = proc (f: ^sl.Frame) {
            rl.EndScissorMode()
        },
        debug_draw_proc = proc (f: ^sl.Frame) {
            if rl.IsKeyDown(.LEFT_CONTROL) {
                sl_rl.debug_draw_frame_anchors(f)
                sl_rl.debug_draw_frame(f)
            }
        },
    )
    game.main_menu = create_main_menu(game.ui_manager.root)
}

destroy_game :: proc () {
    destroy_main_menu(game.main_menu)
    sl.destroy_manager(game.ui_manager)
    free(game)
    game = nil
}

frame_started :: proc () {
    game.time = f32(rl.GetTime())
    game.frame_time = rl.GetFrameTime()
    game.screen_rect = { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) }
    game.camera.offset = { game.screen_rect.w/2, game.screen_rect.h/2 }
}

main :: proc () {
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 4")

    load_assets()
    create_game()

    for !rl.WindowShouldClose() && !game.exit_requested {
        free_all(context.temp_allocator)
        frame_started()

        mouse_input := sl.Mouse_Input { rl.GetMousePosition(), rl.IsMouseButtonDown(.LEFT) }

        mouse_input_consumed := sl.update_manager(game.ui_manager, game.screen_rect, mouse_input)

        if !mouse_input_consumed {
            // fmt.printfln("[world] %v", mouse_input)
        }

        rl.BeginDrawing()
        rl.ClearBackground(colors.one)

        rl.BeginMode2D(game.camera)
        // draw_world()
        rl.EndMode2D()

        sl.draw_manager(game.ui_manager)
        // rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }

    destroy_game()
    unload_assets()

    rl.CloseWindow()
}
