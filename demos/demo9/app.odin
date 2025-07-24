package demo9

import "core:fmt"
import rl "vendor:raylib"

import "colors"
import "data"
import "events"
import "fonts"
import "interface"
import "screens/credits"
import "screens/dialog"
import "screens/home"
import "screens/player"
import "screens/settings"
import "sprites"

app_exit_requested: bool

app_startup :: proc () {
    fmt.println(#procedure)

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 9")
    // rl.MaximizeWindow()

    colors.create()
    data.create()
    events.create()
    fonts.create()
    sprites.create()

    interface.create()
    {
        l := interface.get_screens_layer()
        credits.add(l)
        dialog.add(l)
        home.add(l)
        player.add(l)
        settings.add(l)
    }

    events.listen(.exit_app, proc (args: events.Args) { app_exit_requested=true })

    // events.open_screen({ screen_name="home" })
    // events.open_screen({ screen_name="credits" })
    // events.open_dialog({ dialog_id="tyg_rolsum", chat_id="welcome" })
    // events.open_dialog({ dialog_id="ornithopter_pilot", chat_id="welcome" })
    // events.open_screen({ screen_name="settings", tab_name="graphics" })
    events.open_screen({ screen_name="player", tab_name="journey" })
}

app_shutdown :: proc () {
    fmt.println(#procedure)

    interface.destroy()

    colors.destroy()
    data.destroy()
    events.destroy()
    fonts.destroy()
    sprites.destroy()

    rl.CloseWindow()
}

app_running :: proc () -> bool {
    return !rl.WindowShouldClose() && !app_exit_requested
}

app_tick :: proc () {
    free_all(context.temp_allocator)
    interface.tick()
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground({20,25,30,255})

    { // drawing the game world
        cx := f32(rl.GetScreenWidth()/2)
        cy := f32(rl.GetScreenHeight()/2)
        cr := min(cx,cy)
        rl.DrawRing({cx,cy}, cr-40, cr, 0, 360, 64, {30,35,40,255})

        fh := i32(cr/12.345)
        tx := cstring("/* game world rendering goes here */")
        tw := rl.MeasureText(tx, fh)
        rl.DrawText(tx, i32(cx)-tw/2, i32(cy)-fh/2, fh, {40,45,50,255})
    }

    interface.draw()

    // app_draw_frame_stats()
    rl.EndDrawing()
}

// app_draw_frame_stats :: proc () {
//     // tex := sprites.textures[0]
//     // draw.texture(sprites.textures[0]^, {0,0,f32(tex.width),f32(tex.height)}, {0,0,f32(tex.width),f32(tex.height)})

//     rect_w, rect_h :: 210, 150
//     rect := rl.Rectangle { 10, interface.get_ui().root.rect.h-rect_h-90, rect_w, rect_h }
//     rl.DrawRectangleRec(rect, { 40, 10, 20, 255 })
//     rl.DrawRectangleLinesEx(rect, 2, rl.RED)

//     st := interface.get_ui().stats
//     cstr := fmt.ctprintf(
//         "fps: %v\n"+
//         "tick_time: %v\n"+
//         "draw_time: %v\n"+
//         "frames_total: %v\n"+
//         "frames_drawn: %v\n"+
//         "scissors_set: %v",
//         rl.GetFPS(),
//         st.tick_time, st.draw_time, st.frames_total, st.frames_drawn, st.scissors_set,
//     )

//     rl.DrawText(cstr, i32(rect.x+10), i32(rect.y+10), 20, rl.GREEN)
// }
