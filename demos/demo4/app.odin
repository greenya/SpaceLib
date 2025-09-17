package demo4

import "core:fmt"
import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:core/tracking_allocator"
import "spacelib:ui"
import "spacelib:terse"
import "spacelib:raylib/draw"

Vec2 :: core.Vec2
Rect :: core.Rect

App :: struct {
    clock: core.Clock(f32),
    screen_rect: Rect,
    camera: rl.Camera2D,

    ui: ^ui.UI,
    main_menu: ^Main_Menu,

    debug_drawing: bool,
    exit_requested: bool,
}

app: ^App

app_startup :: proc () {
    fmt.println(#procedure)
    assert(app == nil)

    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 4")

    assets_load()

    terse.query_font = proc (name: string) -> ^terse.Font {
        return &assets_font(name).font_tr
    }

    terse.query_color = proc (name: string) -> core.Color {
        if name[0] == '#'   do return core.color_from_hex(name)
        else                do return assets_color(name).val
    }

    app = new(App)
    core.clock_init(&app.clock)
    app.camera = { zoom=1 }

    app.ui = ui.create(
        scissor_set_proc = proc (r: Rect) {
            if app.debug_drawing do return
            rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h))
        },
        scissor_clear_proc = proc () {
            if app.debug_drawing do return
            rl.EndScissorMode()
        },
        terse_draw_proc = proc (f: ^ui.Frame) {
            draw_terse(f)
        },
        frame_overdraw_proc = proc (f: ^ui.Frame) {
            if !app.debug_drawing do return
            draw.debug_frame(f)
        },
    )

    main_menu_init()

    ui.print_frame_tree(app.ui.root)
}

app_running :: proc () -> bool {
    return !rl.WindowShouldClose() && !app.exit_requested
}

app_tick :: proc () {
    free_all(context.temp_allocator)
    core.clock_tick(&app.clock)
    app.screen_rect = { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) }
    app.camera.offset = { app.screen_rect.w/2, app.screen_rect.h/2 }

    mouse_input := ui.Mouse_Input { rl.GetMousePosition(), rl.GetMouseWheelMove(), rl.IsMouseButtonDown(.LEFT) }
    mouse_input_consumed := ui.tick(app.ui, app.screen_rect, mouse_input)
    if !mouse_input_consumed {
        // fmt.printfln("[world] %v", mouse_input)
    }

    app.debug_drawing = rl.IsKeyDown(.LEFT_CONTROL)
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground(colors[.c1].val.rgba)
    rl.BeginMode2D(app.camera)
    // draw_world()
    rl.EndMode2D()

    ui.draw(app.ui)

    if app.debug_drawing {
        rect_w, rect_h :: 280, 220
        rect := rl.Rectangle { 10, app.screen_rect.h-rect_h-10, rect_w, rect_h }
        rl.DrawRectangleRec(rect, { 40, 10, 20, 255 })
        rl.DrawRectangleLinesEx(rect, 2, rl.RED)
        rl.DrawFPS(i32(rect.x+10), i32(rect.y+10))
        cstr := fmt.ctprintf("TA Memory: %v\n%#v", tracking_allocator.track.current_memory_allocated, app.ui.stats)
        rl.DrawText(cstr, i32(rect.x+10), i32(rect.y+30), 20, rl.GREEN)
    }

    // rl.DrawFPS(10, 10)
    rl.EndDrawing()
}

app_shutdown :: proc () {
    fmt.println(#procedure)

    main_menu_destroy()
    ui.destroy(app.ui)

    free(app)
    app = nil

    assets_unload()

    rl.CloseWindow()
}
