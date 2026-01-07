package demo12

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:raylib/draw"
// import "spacelib:raylib/res"
// import "spacelib:terse"
import "spacelib:ui"

Vec2 :: core.Vec2
Rect :: core.Rect

@rodata
Src_Sizes := [?] Vec2 {
    { 1000, 200 },
    { 1000, 500 },
    { 1000, 750 },
    { 1000, 1000 },
    { 750, 1000 },
    { 500, 1000 },
    { 200, 1000 },
}

App :: struct {
    should_debug: bool,

    src_size: Vec2,

    ui: ^ui.UI,
}

app := App { src_size={2000,1000} }

app_startup :: proc () {
    fmt.println(#procedure)

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 12")

    // terse.default_font.measure_text = proc (font: ^terse.Font, text: string) -> Vec2 {
    //     return res.measure_text(rl.GetFontDefault(), font.height, font.rune_spacing, text)
    // }

    app.ui = ui.create(
        root_rect           = {0,0,f32(rl.GetScreenWidth()),f32(rl.GetScreenHeight())},
        scissor_set_proc    = proc (r: Rect) { rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h)) },
        scissor_clear_proc  = proc () { rl.EndScissorMode() },
        terse_draw_proc     = proc (f: ^ui.Frame) { draw.terse(f.terse) },
        frame_overdraw_proc = ODIN_DEBUG\
            ? proc (f: ^ui.Frame) { if app.should_debug do draw.debug_frame(f) }\
            : nil,
    )

    // action_bar := ui.add_frame(app.ui.root, {
    //     layout = ui.Flow {}
    // })

    // ui.add_frame(app.ui.root, {
    //     flags={.terse,.terse_size},
    //     text="<pad=20,c=#8bf>Hello World!",
    // },
    //     { point=.left },
    // )

    ui.add_frame(app.ui.root, {
        size = {500,300},
        draw = proc (f: ^ui.Frame) {
            dst_rect := f.rect
            // draw.rect(dst_rect, core.gray2)
            draw.rect_lines(dst_rect, 2, core.magenta)
            text := fmt.tprintf("%.0f x %.0f", dst_rect.w, dst_rect.h)
            draw.text(text, {dst_rect.x,dst_rect.y}, {0,1}, nil, core.magenta)

            // ui.push_scissor_rect(app.ui, dst_rect)

            src_size := Vec2 { 2000, 1000 }
            // dst_size := Vec2 { dst_rect.w, dst_rect.h }
            fit_rect, fit_scale := core.fit_size_into_rect(src_size, dst_rect)
            // core.rect_move(&fit_rect, {dst_rect.x+10,dst_rect.y+10})
            draw.rect_lines(fit_rect, 8, core.yellow)
            text2 := fmt.tprintf("FIT RECT: %.0f x %.0f\nFIT SCALE: %.3f", fit_rect.w, fit_rect.h, fit_scale)
            draw.text(text2, core.rect_center(fit_rect), .5, nil, core.yellow)

            // ui.pop_scissor_rect(app.ui)
        },
    },
        { point=.center },
    )
}

app_shutdown :: proc () {
    fmt.println(#procedure)

    ui.destroy(app.ui)
    rl.CloseWindow()
}

app_running :: proc () -> bool {
    return !rl.WindowShouldClose()
}

app_tick :: proc () {
    app.should_debug = rl.IsKeyDown(.LEFT_CONTROL)

    ui.tick(app.ui, {0,0,f32(rl.GetScreenWidth()),f32(rl.GetScreenHeight())}, {
        pos         = rl.GetMousePosition(),
        lmb_down    = rl.IsMouseButtonDown(.LEFT),
        wheel_dy    = rl.GetMouseWheelMove(),
    })
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground(core.gray1.rgba)
    ui.draw(app.ui)
    rl.EndDrawing()
}
