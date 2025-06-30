package demo9

import "core:fmt"
import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:terse"
import "spacelib:ui"

import "data"
import "colors"
import "fonts"
import "partials"
import "screens"

App :: struct {
    ui: ^ui.UI,
}

app: ^App

app_startup :: proc () {
    fmt.println(#procedure)

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 9")
    // rl.MaximizeWindow()

    data.create()
    fonts.create()

    app = new(App)
    app.ui = ui.create(
        terse_query_font_proc = proc (name: string) -> ^terse.Font {
            return &fonts.get(name).font_tr
        },
        terse_query_color_proc = proc (name: string) -> core.Color {
            return colors.get(name)
        },
        terse_draw_proc = proc (terse: ^terse.Terse) {
            partials.draw_terse(terse)
        },
        overdraw_proc = proc (f: ^ui.Frame) {
            if !rl.IsKeyDown(.LEFT_CONTROL) do return
            draw.debug_frame(f)
            draw.debug_frame_layout(f)
            draw.debug_frame_anchors(f)
        },
    )

    screens.add_to(app.ui.root)
    screens.open(app.ui.root, "opening")
    // screens.open(app.ui.root, "player", "journey")

    ui.print_frame_tree(app.ui.root)
}

app_shutdown :: proc () {
    fmt.println(#procedure)

    ui.destroy(app.ui)
    fonts.destroy()
    data.destroy()

    free(app)
    app = nil

    rl.CloseWindow()
}

app_running :: proc () -> bool {
    return !rl.WindowShouldClose()
}

app_tick :: proc () {
    free_all(context.temp_allocator)

    ui.tick(app.ui,
        { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) },
        { rl.GetMousePosition(), rl.GetMouseWheelMove(), rl.IsMouseButtonDown(.LEFT) },
    )
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground({})

    ui.draw(app.ui)

    app_draw_frame_stats()
    rl.EndDrawing()
}

app_draw_frame_stats :: proc () {
    // draw.debug_res_texture(app.res, "sprites", {10,100}, .25)

    rect_w, rect_h :: 210, 130
    rect := rl.Rectangle { 10, app.ui.root.rect.h-rect_h-90, rect_w, rect_h }
    rl.DrawRectangleRec(rect, { 40, 10, 20, 255 })
    rl.DrawRectangleLinesEx(rect, 2, rl.RED)

    st := app.ui.stats
    cstr := fmt.ctprintf(
        "fps: %v\n"+
        "tick_time: %v\n"+
        "draw_time: %v\n"+
        "frames_total: %v\n"+
        "frames_drawn: %v",
        rl.GetFPS(),
        st.tick_time, st.draw_time, st.frames_total, st.frames_drawn,
    )

    rl.DrawText(cstr, i32(rect.x+10), i32(rect.y+10), 20, rl.GREEN)
}
