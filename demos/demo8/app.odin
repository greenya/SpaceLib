package demo8

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:raylib/draw"
import "spacelib:ui"

App :: struct {
    res             : ^App_Res,
    data            : ^App_Data,
    ui              : ^ui.UI,
    debug_drawing   : bool,
    debug_update_ui : bool,
}

app: ^App

app_startup :: proc () {
    fmt.println(#procedure)

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 8")
    rl.MaximizeWindow()

    app = new(App)

    app_res_create()
    app_data_create()

    app.ui = ui.create(
        terse_draw_proc = proc (f: ^ui.Frame) {
            draw_terse(f)
        },
        frame_overdraw_proc = proc (f: ^ui.Frame) {
            if !app.debug_drawing do return
            draw.debug_frame(f)
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
    ui.destroy(app.ui)

    app_data_destroy()
    app_res_destroy()

    free(app)
    app = nil

    rl.CloseWindow()
}

app_running :: proc () -> bool {
    return !rl.WindowShouldClose()
}

app_tick :: proc () {
    if app.debug_update_ui {
        t := app.ui.clock.tick
        w := f32(t%1000)/10
        wc := w < 20\
            ? "weight_ar"\
            : w < 50\
                ? "weight_lt"\
                : w < 80\
                    ? "weight_md"\
                    : "weight_hv"

        ui_set_text("menu/bar_top/scrap_count", t)
        ui_set_text("menu/pages/page_archetype/primary/level", 10+t%20)
        ui_set_text("menu/pages/page_archetype/secondary/level", 10+t%20)
        ui_set_text("menu/pages/page_character/~primary/level", 10+t%20)
        ui_set_text("menu/pages/page_character/~secondary/level", 10+t%20)
        ui_set_text("menu/pages/page_character/ring/column/stats_basic/power/level", 10+t%20)
        ui_set_text("menu/pages/page_character/ring/column/stats_basic/stats_res", 100-t%100, 110-t%100, 120-t%100, t%100, 150-t%100)
        ui_set_text("menu/pages/page_character/ring/column/stats_basic", t%400+100, (t/5)%100+50, f32(t%1500)/20, wc, w)
    }

    ui.tick(app.ui,
        { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) },
        { rl.GetMousePosition(), rl.GetMouseWheelMove(), rl.IsMouseButtonDown(.LEFT) },
    )

    app.debug_drawing = rl.IsKeyDown(.LEFT_CONTROL)
    if rl.IsKeyPressed(.SPACE) do app.debug_update_ui ~= true
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground(color("bw_11").rgba)

    ui.draw(app.ui)

    app_draw_frame_stats()
    rl.EndDrawing()
}

app_draw_frame_stats :: proc () {
    rect_w, rect_h :: 210, 172
    rect := rl.Rectangle { 10, app.ui.root.rect.h-rect_h-72, rect_w, rect_h }
    rl.DrawRectangleRec(rect, { 40, 10, 20, 255 })
    rl.DrawRectangleLinesEx(rect, 2, rl.RED)

    st := app.ui.stats
    cstr := fmt.ctprintf(
        "fps: %v\n"+
        "tick_time: %v\n"+
        "draw_time: %v\n"+
        "frames_total: %v\n"+
        "frames_drawn: %v\n"+
        "[%s] Update values\n"+
        "    every frame",
        rl.GetFPS(),
        st.tick_time, st.draw_time, st.frames_total, st.frames_drawn,
        app.debug_update_ui ? "X" : "_",
    )

    rl.DrawText(cstr, i32(rect.x+10), i32(rect.y+10), 20, rl.GREEN)
}
