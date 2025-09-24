package demo10

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:raylib/draw"
import "spacelib:ui"
import "spacelib:userfs"

app_name :: "SpaceLib Demo 10"

app_desc_format :: "<wrap,top,left,font=6>spacelib:<color=hl>userfs</,/font>\n" +
"<gap=.8>The <color=hl>userfs</> package allows saving and loading small files both in a web browser " +
"and in a desktop environment. On desktop, it uses <color=hl>os.user_data_dir()</> as the base path, " +
"while on the web it relies on the browser's <color=hl>localStorage</>.\n" +
"<gap=.8>This demo saves its state on every change.\n" +
"<gap=.8>%s"

when ODIN_OS == .JS {
    app_desc_hint :: "++ This is web build ++\nRefresh this page (<color=hl>F5</> or <color=hl>Ctrl+R</>) to see restored state."
} else {
    app_desc_hint :: "++ This is desktop build ++\nRestart demo to see restored state."
}

app_link_userfs_source :: "https://github.com/greenya/SpaceLib/tree/main/src/userfs"
app_link_demo10_source :: "https://github.com/greenya/SpaceLib/tree/main/demos/demo10"

app_should_exit : bool
app_ui          : ^ui.UI

app_startup :: proc () {
    fmt.println(#procedure)

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, app_name)

    // ---- init userfs and load all files ----
    userfs.init(app_name)
    bit_grid_load()
    leaderboard_load()
    options_load()
    // ----------------------------------------

    res_init()

    app_ui = ui.create(
        scissor_set_proc    = proc (r: Rect)        { rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h)) },
        scissor_clear_proc  = proc ()               { rl.EndScissorMode() },
        terse_draw_proc     = proc (f: ^ui.Frame)   { draw_terse(f.terse) },
        frame_overdraw_proc = proc (f: ^ui.Frame)   { if rl.IsKeyDown(.LEFT_CONTROL) do draw.debug_frame(f) },
    )

    column := ui.add_frame(app_ui.root,
        { size={500,0} },
        { point=.top_left, offset={100,40} },
        { point=.bottom_left, offset={100,-40} },
    )

    tab_bar := ui.add_frame(column,
        { size={0,64}, layout=ui.Flow { dir=.right_center } },
        { point=.top_left },
        { point=.top_right },
    )

    tab_content := ui.add_frame(column,
        { flags={.scissor}, layout=ui.Flow { dir=.down, scroll={step=20} }, draw_after=draw_after_tab_content },
        { point=.top_left, rel_point=.bottom_left, rel_frame=tab_bar },
        { point=.bottom_right },
    )

    ui_add_scrollbar(tab_content, position=.right)

    bit_grid_ui_add     (tab_bar, tab_content)
    leaderboard_ui_add  (tab_bar, tab_content)
    options_add_ui      (tab_bar, tab_content)

    about := ui.add_frame(app_ui.root,
        { flags={.scissor}, layout=ui.Flow { dir=.down, scroll={step=20} } },
        { point=.top_left, rel_point=.top_right, rel_frame=column, offset={100,0} },
        { point=.bottom_right, offset={-100,-40} },
    )

    about_track, _ := ui_add_scrollbar(about, position=.left)
    about_track.anchors[0].offset.y += tab_bar.size.y

    ui.add_frame(about,
        { flags={.terse,.terse_height}, text=fmt.tprintf(app_desc_format, app_desc_hint) },
    )

    bar := ui.add_frame(about, {
        layout=ui.Flow { dir=.down, pad={0,0,20,0}, gap=10, auto_size={.height} },
    })

    ui.add_frame(bar, {
        flags={.terse,.terse_size},
        text="<pad=10>Open userfs Package Source Code",
        click=proc (f: ^ui.Frame) { rl.OpenURL(fmt.ctprint(app_link_userfs_source)) },
        draw=draw_button,
    })

    ui.add_frame(bar, {
        flags={.terse,.terse_size},
        text="<pad=10>Open This Demo Source Code",
        click=proc (f: ^ui.Frame) { rl.OpenURL(fmt.ctprint(app_link_demo10_source)) },
        draw=draw_button,
    })

    active_tab_idx := clamp(options.active_tab_idx, 0, len(tab_bar.children))
    ui.click(tab_bar.children[active_tab_idx])

    app_update_vsync()
}

app_shutdown :: proc () {
    fmt.println(#procedure)
    ui.destroy(app_ui)
    leaderboard_destroy()
    res_destroy()
    rl.CloseWindow()
}

app_resized :: proc (w, h: i32) {
    fmt.println(#procedure, w, h)
    rl.SetWindowSize(w, h)
}

app_running :: proc () -> bool {
    when ODIN_OS != .JS { app_should_exit |= rl.WindowShouldClose() }
    return !app_should_exit
}

app_tick :: proc () {
    ui.tick(app_ui,
        root_rect   = { 0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) },
        mouse       = {
            pos         = rl.GetMousePosition(),
            lmb_down    = rl.IsMouseButtonDown(.LEFT),
            wheel_dy    = rl.GetMouseWheelMove(),
        },
    )
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground(color_bg.rgba)
    ui.draw(app_ui)
    if options.show_fps do rl.DrawFPS(10, 10)
    rl.EndDrawing()
}

app_update_vsync :: proc () {
    if options.use_vsync    do rl.SetWindowState({ .VSYNC_HINT })
    else                    do rl.ClearWindowState({ .VSYNC_HINT })
}
