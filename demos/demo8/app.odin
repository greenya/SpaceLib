package demo8

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:raylib/res"
import "spacelib:terse"
import "spacelib:ui"

Vec2 :: core.Vec2
Rect :: core.Rect
Color :: core.Color

App :: struct {
    res             : ^res.Res,
    ui              : ^ui.UI,
    menu            : ^App_Menu,

    debug_drawing   : bool,
}

app: ^App

app_startup :: proc () {
    fmt.println(#procedure)

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 8")
    rl.MaximizeWindow()

    app = new(App)

    app.res = res.create()
    res.add_files(app.res, #load_directory("res/colors"))
    res.add_files(app.res, #load_directory("res/fonts"))
    res.add_files(app.res, #load_directory("res/sprites"))
    res.load_colors(app.res)
    res.load_fonts(app.res)
    res.load_sprites(app.res, texture_filter=.BILINEAR)
    // res.print(app.res)

    app.ui = ui.create(
        terse_query_font_proc = proc (name: string) -> ^terse.Font {
            return &app.res.fonts[name].font_tr
        },
        terse_query_color_proc = proc (name: string) -> core.Color {
            return app.res.colors[name].value
        },
        terse_draw_proc = proc (terse: ^terse.Terse) {
            draw_terse(terse)
        },
    )

    app_menu_create()

    ui.print_frame_tree(app.ui.root)
}

app_shutdown :: proc () {
    fmt.println(#procedure)

    app_menu_destroy()
    ui.destroy(app.ui)
    res.destroy(app.res)

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

    app.debug_drawing = rl.IsKeyDown(.LEFT_CONTROL)
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground(app.res.colors["bw_11"].value.rgba)

    // drawing world goes here

    ui.draw(app.ui)
    if app.debug_drawing do draw.debug_frame_tree(app.ui.root)

    // rl.DrawFPS(10, 10)
    rl.EndDrawing()
}
