package demo4

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:clock"
import "spacelib:ui"
import rl_sl "spacelib:raylib"
import "spacelib:tracking_allocator"

App :: struct {
    clock: clock.Clock(f32),
    screen_rect: ui.Rect,
    camera: rl.Camera2D,

    ui: struct {
        manager: ^ui.Manager,
        main_menu: ^Main_Menu,
    },

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

    app = new(App)
    clock.init(&app.clock)
    app.camera = { zoom=1 }

    app.ui.manager = ui.create_manager(
        scissor_set_proc = proc (r: ui.Rect) {
            if app.debug_drawing do return
            rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h))
        },
        scissor_clear_proc = proc () {
            if app.debug_drawing do return
            rl.EndScissorMode()
        },
        overdraw_proc = proc (f: ^ui.Frame) {
            if !app.debug_drawing do return
            rl_sl.debug_draw_frame(f)
            rl_sl.debug_draw_frame_layout(f)
            rl_sl.debug_draw_frame_anchors(f)
        },
    )

    main_menu_init()

    ui.print_frame_tree(app.ui.manager.root)
}

app_running :: proc () -> bool {
    return !rl.WindowShouldClose() && !app.exit_requested
}

app_tick :: proc () {
    free_all(context.temp_allocator)
    clock.tick(&app.clock)
    app.screen_rect = { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) }
    app.camera.offset = { app.screen_rect.w/2, app.screen_rect.h/2 }

    mouse_input := ui.Mouse_Input { rl.GetMousePosition(), rl.GetMouseWheelMove(), rl.IsMouseButtonDown(.LEFT) }
    mouse_input_consumed := ui.update_manager(app.ui.manager, app.screen_rect, mouse_input)
    if !mouse_input_consumed {
        // fmt.printfln("[world] %v", mouse_input)
    }

    app.debug_drawing = rl.IsKeyDown(.LEFT_CONTROL)
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground(colors.one)
    rl.BeginMode2D(app.camera)
    // draw_world()
    rl.EndMode2D()

    ui.draw_manager(app.ui.manager)

    if app.debug_drawing {
        rect_w, rect_h :: 280, 220
        rect := rl.Rectangle { 10, app.screen_rect.h-rect_h-10, rect_w, rect_h }
        rl.DrawRectangleRec(rect, { 40, 10, 20, 255 })
        rl.DrawRectangleLinesEx(rect, 2, rl.RED)
        rl.DrawFPS(i32(rect.x+10), i32(rect.y+10))
        cstr := fmt.ctprintf("TA Memory: %v\n%#v", tracking_allocator.current_memory_allocated(), app.ui.manager.stats)
        rl.DrawText(cstr, i32(rect.x+10), i32(rect.y+30), 20, rl.GREEN)
    }

    // rl.DrawFPS(10, 10)
    rl.EndDrawing()
}

app_shutdown :: proc () {
    fmt.println(#procedure)

    main_menu_destroy()
    ui.destroy_manager(app.ui.manager)

    free(app)
    app = nil

    assets_unload()

    rl.CloseWindow()
}
