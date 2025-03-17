package demo2

import "core:fmt"
import rl "vendor:raylib"
import sl "../spacelib"

Game :: struct {
    ui: struct {
        root: ^sl.Frame,
    }
}

game: ^Game

main :: proc () {
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 2")

    game = new(Game)
    game.ui.root = sl.add_frame({})
    sl.default_draw_proc = draw_frame_debug

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.DARKGRAY)

        screen_w, screen_h := f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())
        game.ui.root.rect = { 10, 10, screen_w-20, screen_h-20 }
        sl.draw_frame(game.ui.root)

        rl.EndDrawing()
        free_all(context.temp_allocator)
    }

    sl.destroy_frame_tree(game.ui.root)
    free(game)

    rl.CloseWindow()
}

draw_frame_debug :: proc (f: ^sl.Frame) {
    rect := transmute(rl.Rectangle) f.rect

    if f == game.ui.root {
        thick :: 10
        cx, cy := rect.x + rect.width/2, rect.y + rect.height/2
        rl.DrawRectangleLinesEx(rect, thick, rl.ColorAlpha(rl.GRAY, 0.4))
        rl.DrawLineEx({ cx, rect.y }, { cx, rect.y+rect.height }, thick, rl.ColorAlpha(rl.GRAY, 0.2))
        rl.DrawLineEx({ rect.x, cy }, { rect.x+rect.width, cy }, thick, rl.ColorAlpha(rl.GRAY, 0.2))
        return
    }

    color := rl.WHITE
    if rect.width > 0 && rect.height > 0 {
        rl.DrawRectangleRec(rect, rl.ColorAlpha(color, .1))
        rl.DrawRectangleLinesEx(rect, 1, color)
    } else if rect.width > 0 {
        rl.DrawLineEx({ rect.x, rect.y }, { rect.x + rect.width, rect.y }, 3, color)
        rl.DrawLineEx({ rect.x, rect.y-6 }, { rect.x, rect.y+5 }, 3, color)
        rl.DrawLineEx({ rect.x+rect.width, rect.y-6 }, { rect.x+rect.width, rect.y + 5 }, 3, color)
    } else if rect.height > 0 {
        rl.DrawLineEx({ rect.x, rect.y }, { rect.x, rect.y+rect.height }, 3, color)
        rl.DrawLineEx({ rect.x-6, rect.y }, { rect.x+5, rect.y }, 3, color)
        rl.DrawLineEx({ rect.x-6, rect.y+rect.height }, { rect.x+5, rect.y+rect.height }, 3, color)
    } else {
        rl.DrawLineEx({ rect.x-5, rect.y+1 }, { rect.x+6, rect.y+1 }, 3, color)
        rl.DrawLineEx({ rect.x+1, rect.y-6 }, { rect.x+1, rect.y+6 }, 3, color)
    }
}
