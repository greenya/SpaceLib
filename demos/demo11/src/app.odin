package main

import "core:fmt"
import rl "vendor:raylib"

app_startup :: proc () {
    fmt.println(#procedure)

    http_init()

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(400, 300, "SpaceLib Demo11")
}

app_shutdown :: proc () {
    fmt.println(#procedure)

    rl.CloseWindow()

    http_destroy()
}

app_tick :: proc () {
    if rl.IsKeyPressed(.ONE) {
        http_send_request()
    }

    if rl.IsKeyPressed(.TWO) {
        scores, err := pt_get_scores(limit=20, allocator=context.temp_allocator)
        if err != nil   do fmt.printfln("[ERROR] (%i) %v", err, err)
        else            do fmt.printfln("scores: %#v", scores)
    }

    if rl.IsKeyPressed(.THREE) {
        err := pt_submit_score(player="TestPlayerTwo", score=4002)
        if err != nil   do fmt.printfln("[ERROR] (%i) %v", err, err)
        else            do fmt.printfln("score submitted")
    }
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground({22,33,55,255})
    x := rl.GetRandomValue(10, 15)
    y := rl.GetRandomValue(10, 15)
    rl.DrawFPS(x, y)
    rl.EndDrawing()
}

app_running :: proc () -> bool {
    running := true
    when ODIN_OS != .JS {
        if rl.WindowShouldClose() do running = false
    }
    return running
}

app_resized :: proc (w, h: i32) {
    fmt.println(#procedure, w, h)
    rl.SetWindowSize(w, h)
}
