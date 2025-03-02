package demo

import "core:fmt"
import rl "vendor:raylib"
import sl "spacelib"

Demo :: struct {
    ui: ^sl.UI,
    debug_info: struct {
        frame: ^sl.Frame,
        fps: ^sl.Frame,
        screen_size: ^sl.Frame,
        mouse_pos: ^sl.Frame,
    },
}

demo: ^Demo

main :: proc () {
    demo_init()
    for !rl.WindowShouldClose() do demo_update()
    demo_shutdown()
}

demo_init :: proc () {
    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "SpaceLib Demo")

    demo = new(Demo)
    demo.ui = sl.create_ui()
    font1 := sl.add_font_from_bytes(demo.ui, #load("../assets/Anaheim/static/Anaheim-Medium.ttf"), 30)
    demo.ui.is_debug = true

    debug_info_init(demo.ui.frame, font1)
    anchor_test_init(demo.ui.frame, font1)
}

demo_shutdown :: proc () {
    sl.destroy_ui(demo.ui)
    free(demo)

    rl.CloseWindow()
}

demo_update :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground({ 45, 50, 80, 255 })

    debug_info_update()
    sl.draw_ui(demo.ui, { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) })
    rl.DrawLine(rl.GetScreenWidth()/2, 0, rl.GetScreenWidth()/2, rl.GetScreenHeight(), { 200, 100, 50, 255 })
    rl.DrawLine(0, rl.GetScreenHeight()/2, rl.GetScreenWidth(), rl.GetScreenHeight()/2, { 200, 100, 50, 255 })

    rl.EndDrawing()
    free_all(context.temp_allocator)
}

debug_info_init :: proc (parent: ^sl.Frame, font: ^sl.Font) {
    di := &demo.debug_info

    di.frame = sl.add_frame(parent)
    sl.set_anchor(di.frame, .top_right, offset={ -20, 20 })

    di.fps = sl.add_text(di.frame, font)
    sl.set_anchor(di.fps, .top_right)

    di.screen_size = sl.add_text(di.frame, font)
    sl.set_anchor(di.screen_size, .top_right, .bottom_right, di.fps)

    di.mouse_pos = sl.add_text(di.frame, font)
    sl.set_anchor(di.mouse_pos, .top_right, .bottom_right, di.screen_size)
}

debug_info_update :: proc () {
    di := &demo.debug_info
    sl.set_text(di.fps, fmt.tprintf("FPS: %v", rl.GetFPS()))
    sl.set_text(di.screen_size, fmt.tprintf("Screen Size: %v x %v", rl.GetScreenWidth(), rl.GetScreenHeight()))
    sl.set_text(di.mouse_pos, fmt.tprintf("Mouse Pos: %v", rl.GetMousePosition()))
}

anchor_test_init :: proc (parent: ^sl.Frame, font: ^sl.Font) {
    frame := sl.add_frame(parent)
    sl.set_anchor(frame, .top_left, offset={ 240, 180 })
    sl.set_anchor(frame, .bottom_right, offset={ -240, -180 })

    for point in sl.Anchor_Point {
        if point == .none do continue
        for rel_point in sl.Anchor_Point {
            if rel_point == .none do continue
            label := sl.add_text(frame, font, fmt.aprintf("%v\n%v", point, rel_point), size={ 100, 100 })
            sl.set_anchor(label, point, rel_point)
        }
    }
}
