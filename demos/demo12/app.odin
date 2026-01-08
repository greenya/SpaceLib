package demo12

import "base:intrinsics"
import "core:fmt"
import "core:reflect"
import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:raylib/res"
import "spacelib:terse"
import "spacelib:ui"

Vec2    :: core.Vec2
Rect    :: core.Rect
Color   :: core.Color

elem_size :: Vec2 {200,40}
src_color :: core.aqua
dst_color :: core.magenta
fit_color :: core.yellow

@rodata
Src_Sizes := [?] Vec2 {
    { 512*2, 512*2 },
    { 512, 512 },
    { 512/2, 512/2 },
    { 512/4, 512/4 },
    { 512/8, 512/8 },
    { 512, 512/2 },
    { 512, 512/4 },
    { 512, 512/8 },
    { 512/8, 512 },
    { 512/4, 512 },
    { 512/2, 512 },
}

@rodata
Dst_Sizes := [?] Vec2 {
    { 600, 300 },
    { 600, 400 },
    { 600, 500 },
    { 600, 600 },
    { 500, 600 },
    { 400, 600 },
    { 300, 600 },
    { 200, 600 },
    { 100, 600 },
    { 1280, 720 },
    { 1280/2, 720/2 },
    { 1280/4, 720/4 },
    { 1280/8, 720/8 },
}

App :: struct {
    should_debug    : bool,
    src_size_idx    : int,
    dst_size_idx    : int,
    dst_use_scissor : bool,
    rect_fit        : core.Rect_Fit,
    dst_frame       : ^ui.Frame,
    ui              : ^ui.UI,
}

app := App { rect_fit=.contain_center }

app_startup :: proc () {
    fmt.println(#procedure)

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .VSYNC_HINT, .WINDOW_RESIZABLE })
    rl.InitWindow(1280, 720, "spacelib demo 12")

    terse.default_font.measure_text = proc (font: ^terse.Font, text: string) -> Vec2 {
        return res.measure_text(rl.GetFontDefault(), font.height, font.rune_spacing, text)
    }

    app.ui = ui.create(
        root_rect           = {0,0,f32(rl.GetScreenWidth()),f32(rl.GetScreenHeight())},
        scissor_set_proc    = proc (r: Rect) { rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h)) },
        scissor_clear_proc  = proc () { rl.EndScissorMode() },
        terse_draw_proc     = proc (f: ^ui.Frame) { draw.terse(f.terse) },
        frame_overdraw_proc = ODIN_DEBUG\
            ? proc (f: ^ui.Frame) { if app.should_debug do draw.debug_frame(f) }\
            : nil,
    )

    src_bar := add_size_selector_flow(app.ui.root, "SRC SIZE", Src_Sizes[:], app.src_size_idx,
        draw    = draw_src_button,
        click   = proc (f: ^ui.Frame) {
            app.src_size_idx = f.user_idx
        },
    )

    ui.set_anchors(src_bar, { point=.top_left, offset={40,60} })

    dst_bar := add_size_selector_flow(app.ui.root, "DST SIZE", Dst_Sizes[:], app.dst_size_idx,
        draw    = draw_dst_button,
        click   = proc (f: ^ui.Frame) {
            app.dst_size_idx = f.user_idx
            app.dst_frame.size = Dst_Sizes[app.dst_size_idx]
        },
    )

    ui.set_anchors(dst_bar, { point=.top_right, offset={-40,60} })

    ui.add_frame(dst_bar)
    ui.add_frame(dst_bar, {
        flags   = {.terse,.check},
        text    = "SCISSOR",
        draw    = draw_dst_button,
        click   = proc (f: ^ui.Frame) {
            app.dst_use_scissor = f.selected
        },
    })

    fit_bar := add_enum_selector_grid(app.ui.root, "FIT", app.rect_fit, wrap=3,
        draw    = draw_fit_button,
        click   = proc (f: ^ui.Frame) {
            app.rect_fit = core.Rect_Fit(f.user_idx)
        },
    )

    ui.set_anchors(fit_bar, { point=.top, offset={0,60} })

    app.dst_frame = ui.add_frame(app.ui.root, {
        size = Dst_Sizes[app.dst_size_idx],
        draw = proc (f: ^ui.Frame) {
            dst_rect := f.rect

            if app.dst_use_scissor do ui.push_scissor_rect(app.ui, dst_rect)

            src_size := Src_Sizes[app.src_size_idx]
            src_rect := core.rect_from_center(core.rect_center(dst_rect), src_size)
            draw.rect(src_rect, core.alpha(src_color, .1))
            draw.rect_lines(src_rect, 4, src_color)

            fit_rect, fit_scale := core.fit_size_into_rect(src_size, dst_rect, app.rect_fit)
            draw.rect(fit_rect, core.alpha(fit_color, .1))
            draw.rect_lines(fit_rect, 8, fit_color)

            fit_text := fmt.tprintf("FIT SIZE: %.0f x %.0f\nFIT SCALE: %.3f", fit_rect.w, fit_rect.h, fit_scale)
            draw.text(fit_text, core.rect_center(fit_rect), .5, nil, fit_color)

            if app.dst_use_scissor do ui.pop_scissor_rect(app.ui)

            draw.rect_lines(dst_rect, 2, dst_color)
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

add_size_selector_flow :: proc (parent: ^ui.Frame, title: string, items: [] Vec2, selected_idx: int, draw, click: ui.Frame_Proc) -> (bar: ^ui.Frame) {
    bar = ui.add_frame(parent, {
        order   = 1,
        layout  = ui.Flow { dir=.down, size=elem_size, auto_size={.width} },
    })

    ui.add_frame(bar, {
        flags   = {.terse},
        size    = elem_size,
        text    = fmt.tprintf("<c=#888>%s", title),
    },
        { point=.bottom, rel_point=.top },
    )

    for it, i in items {
        ui.add_frame(bar, {
            flags       = {.terse,.radio},
            user_idx    = i,
            selected    = i == selected_idx,
            text        = fmt.tprintf("%.0f x %.0f", it.x, it.y),
            draw        = draw,
            click       = click,
        })
    }

    return
}

add_enum_selector_grid :: proc (parent: ^ui.Frame, title: string, selected: $T, wrap: int, draw, click: ui.Frame_Proc) -> (bar: ^ui.Frame) where intrinsics.type_is_enum(T) {
    bar = ui.add_frame(parent, {
        order   = 1,
        layout  = ui.Grid { dir=.right_down, size=elem_size, wrap=wrap, auto_size={.width} },
    })

    ui.add_frame(bar, {
        flags   = {.terse,.check},
        size    = elem_size,
        text    = fmt.tprintf("<c=#888>%s", title),
    },
        { point=.bottom, rel_point=.top },
    )

    for f in reflect.enum_fields_zipped(T) {
        ui.add_frame(bar, {
            flags       = {.terse,.radio},
            user_idx    = int(f.value),
            selected    = T(f.value) == selected,
            text        = fmt.tprint(f.name),
            draw        = draw,
            click       = click,
        })
    }

    return
}

draw_button :: proc (f: ^ui.Frame, color: Color) {
    if f.selected do draw.rect(f.rect, color)
    tx_color := f.selected ? core.black : color
    draw.terse(f.terse, color=tx_color)
}

draw_src_button :: proc (f: ^ui.Frame) { draw_button(f, src_color) }
draw_dst_button :: proc (f: ^ui.Frame) { draw_button(f, dst_color) }
draw_fit_button :: proc (f: ^ui.Frame) { draw_button(f, fit_color) }
