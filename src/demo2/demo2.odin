package demo2

import "core:fmt"
import rl "vendor:raylib"
import sl "../spacelib"
import sl_rl "../spacelib_raylib"

Game :: struct {
    ui: struct {
        manager: ^sl.Manager,
    }
}

game: ^Game

main :: proc () {
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 2")

    game = new(Game)
    game.ui.manager = sl.create_manager()
    sl.default_draw_proc = sl_rl.draw_frame_debug

    for !rl.WindowShouldClose() {
        screen_w, screen_h := f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())
        mouse_pos, mouse_lmb_down := rl.GetMousePosition(), rl.IsMouseButtonDown(.LEFT)
        sl.update_manager(game.ui.manager, { 10, 10, screen_w-20, screen_h-20 }, { mouse_pos, mouse_lmb_down })

        rl.BeginDrawing()
        rl.ClearBackground(rl.DARKGRAY)

        sl.draw_manager(game.ui.manager)

        rl.EndDrawing()
        free_all(context.temp_allocator)
    }

    sl.destroy_manager(game.ui.manager)
    free(game)

    rl.CloseWindow()
}
