package main

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:raylib/draw"
import "spacelib:ui"
import "spacelib:userhttp"
import pt "purpletoken"
import "res"

App :: struct {
    should_exit : bool,
    should_debug: bool,

    ui_tab_bar      : ^ui.Frame,
    ui_tab_content  : ^ui.Frame,

    ui: ^ui.UI,
}

app: App

app_startup :: proc () {
    log(#procedure)
    log_build_info()

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "SpaceLib Demo11")

    // rl.SetExitKey(.KEY_NULL)

    res.init()
    userhttp.init({
        default_timeout_ms  = 15_000,
        pre_ready_proc      = log_request,
    })
    pt.init({
        // To run this demo with PurpleToken example working, you need to create
        // PurpleToken account (free) and use your values below:
        // - The "API Secret Pass Phrase" from https://purpletoken.com/profile.php
        // - The "Game Key" from https://purpletoken.com/manage.php
        api_secret  = "A secret pass phrase goes here",
        game_key    = "65ca329ff0f6dc94e3391cab956c02607d5b2271",
    })

    app.ui = ui.create(
        root_rect           = {0,0,f32(rl.GetScreenWidth()),f32(rl.GetScreenHeight())},
        scissor_set_proc    = proc (r: Rect) { rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h)) },
        scissor_clear_proc  = proc () { rl.EndScissorMode() },
        terse_draw_proc     = proc (f: ^ui.Frame) { draw_terse_frame(f) },
        terse_click_proc    = proc (f: ^ui.Frame) { click_terse_frame(f) },
        frame_overdraw_proc = ODIN_DEBUG\
            ? proc (f: ^ui.Frame) { if app.should_debug do draw.debug_frame(f) }\
            : nil,
    )

    panel := ui.add_frame(app.ui.root,
        {},
        { point=.top_left },
        { point=.bottom_right },
    )

    app.ui_tab_bar = ui.add_frame(panel, {
        size    = {220,0},
        layout  = ui.Flow { dir=.down_center, gap=20 },
    },
        { point=.top_left, offset={40,0} },
        { point=.bottom_left, offset={40,0} },
    )

    app.ui_tab_content = ui.add_frame(panel, {
        draw = draw_panel,
    },
        { point=.top_left, rel_point=.top_right, rel_frame=app.ui_tab_bar, offset={40,0} },
        { point=.bottom_right },
    )

    ui.add_frame(app.ui_tab_bar, {
        flags   = {.terse,.terse_size},
        text    = "<font=text_6r,color=white>spacelib:\n<color=amber>userhttp",
    },
        { point=.top, offset={0,40} },
    )

    add_about_page()
    add_purpletoken_page()
    add_fontsource_page()
    add_github_page()

    ui.click(app.ui_tab_bar, "about")
}

app_shutdown :: proc () {
    log(#procedure)

    destroy_github_page()
    ui.destroy(app.ui)
    pt.destroy()
    userhttp.destroy()
    res.destroy()
    rl.CloseWindow()
}

app_tick :: proc () {
    when ODIN_DEBUG {
        app.should_debug = rl.IsKeyDown(.LEFT_CONTROL)
    }

    userhttp.tick()

    ui.tick(app.ui, {0,0,f32(rl.GetScreenWidth()),f32(rl.GetScreenHeight())}, {
        pos         = rl.GetMousePosition(),
        lmb_down    = rl.IsMouseButtonDown(.LEFT),
        wheel_dy    = rl.GetMouseWheelMove(),
    })
}

app_draw :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground(res.color(.plum).rgba)
    ui.draw(app.ui)
    rl.EndDrawing()
}

app_running :: proc () -> bool {
    when ODIN_OS != .JS {
        app.should_exit |= rl.WindowShouldClose()
    }
    return !app.should_exit
}

app_resized :: proc (w, h: i32) {
    log(#procedure, w, h)
    rl.SetWindowSize(w, h)
}

app_add_tab :: proc (text: string) -> (tab, content: ^ui.Frame) {
    assert(app.ui_tab_bar != nil)
    assert(app.ui_tab_content != nil)

    tab = ui.add_frame(app.ui_tab_bar, {
        flags   = {.terse,.terse_height,.radio,.capture},
        text    = fmt.tprintf("<wrap,pad=10,font=text_4r,color=white>%s", text),
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) {
            content := ui.user_ptr(f, ^ui.Frame)
            ensure(content != nil)
            ui.show(content, hide_siblings=true)
            ui.update(content, include_hidden=true)
        },
    })

    content = ui.add_frame(app.ui_tab_content, {
        flags   = {.scissor},
        layout  = ui.Flow { dir=.down, pad={40,80,40,40}, gap=30, align=.start,
                            auto_size={.height}, scroll={step=40} },
    },
        { point=.top_left },
        { point=.bottom_right },
    )

    app_add_scrollbar(content)
    ui.set_user_ptr(tab, content)

    return
}

app_add_scrollbar :: proc (target: ^ui.Frame) -> (track, thumb: ^ui.Frame) {
    assert(.scissor in target.flags)

    track = ui.add_frame(target, {
        size    = {4,0},
        draw    = draw_scrollbar_track,
    },
        { point=.top_left, rel_point=.top_right, offset={-40,40} },
        { point=.bottom_left, rel_point=.bottom_right, offset={-40,-40} },
    )

    thumb = ui.add_frame(track, {
        flags   = {.capture},
        size    = {24,64},
        draw    = draw_scrollbar_thumb,
    },
        { point=.top },
    )

    ui.setup_scrollbar_actors(target, thumb)

    return
}
