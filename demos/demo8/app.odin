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
    data            : ^App_Data,
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
    res.load_sprites(app.res, texture_size_limit={1024,2048}, texture_filter=.BILINEAR)
    // res.print(app.res, {.textures,.sprites})

    app_data_create()

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
        overdraw_proc = proc (f: ^ui.Frame) {
            if !app.debug_drawing do return
            draw.debug_frame(f)
            draw.debug_frame_layout(f)
            draw.debug_frame_anchors(f)
        },
    )

    app_menu_create()
    app_tooltip_create()
    ui.print_frame_tree(app.ui.root)
}

app_shutdown :: proc () {
    fmt.println(#procedure)

    app_tooltip_destroy()
    app_menu_destroy()
    app_data_destroy()
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

    // set some values (every frame) {{{

    t := app.ui.clock.tick
    w := f32(t%1000)/10
    wc := w < 20\
        ? "weight_ar"\
        : w < 50\
            ? "weight_lt"\
            : w < 80\
                ? "weight_md"\
                : "weight_hv"

    app.ui->set_text("scrap_count", t)
    app.ui->set_text("page_archetype/primary/level", 10+t%20)
    app.ui->set_text("page_archetype/secondary/level", 10+t%20)
    app.ui->set_text("page_character/primary/level", 10+t%20)
    app.ui->set_text("page_character/secondary/level", 10+t%20)
    app.ui->set_text("power/level", 10+t%20)
    app.ui->set_text("stats_basic", t%400+100, (t/5)%100+50, f32(t%1500)/20, wc, w)
    app.ui->set_text("stats_res", 100-t%100, 110-t%100, 120-t%100, t%100, 150-t%100)

    // }}}

    ui.tick(app.ui,
        { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) },
        { rl.GetMousePosition(), rl.GetMouseWheelMove(), rl.IsMouseButtonDown(.LEFT) },
    )

    app.debug_drawing = rl.IsKeyDown(.LEFT_CONTROL)
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground(app.res.colors["bw_11"].value.rgba)

    ui.draw(app.ui)

    app_draw_stats()
    rl.EndDrawing()
}

app_draw_stats :: proc () {
    // res.debug_draw_texture(app.res, "sprites", {10,100}, .25)

    @static stats: ui.Stats
    // if app.ui.clock.tick%8==0 do stats = app.ui.stats
    stats = app.ui.stats

    rect_w, rect_h :: 240, 200
    rect := rl.Rectangle { 10, app.ui.root.rect.h-rect_h-72, rect_w, rect_h }
    rl.DrawRectangleRec(rect, { 40, 10, 20, 255 })
    rl.DrawRectangleLinesEx(rect, 2, rl.RED)
    rl.DrawFPS(i32(rect.x+10), i32(rect.y+10))
    cstr := fmt.ctprintf("%#v", stats)
    rl.DrawText(cstr, i32(rect.x+10), i32(rect.y+30), 20, rl.GREEN)
}
