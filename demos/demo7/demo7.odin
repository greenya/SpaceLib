package demo7

import "core:fmt"
import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:raylib/res"
import "spacelib:tracking_allocator"
import "spacelib:ui"
import rl "vendor:raylib"

Vec2 :: core.Vec2
Rect :: core.Rect
Color :: core.Color

app: struct {
    res: ^res.Res,
    ui: ^ui.UI,
}

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print_report_with_issues_only()

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 7")

    app.res = res.create()
    res.add_files(app.res, #load_directory("res/fonts"))
    res.load_fonts(app.res)

    app.ui = ui.create_ui()

    time_scale_control := ui.add_frame(app.ui.root,
        { layout={ dir=.up_and_down, align=.end, size={120,40}, gap=10 } },
        { point=.right, offset={-20,0} },
    )

    ui.add_frame(time_scale_control, { text="Time Scale", draw=draw_label })
    ui.add_frame(time_scale_control, { text="x0.25", draw=draw_button,
        click=proc (f: ^ui.Frame) { app.ui.clock.time_scale=.25 },
    })
    ui.add_frame(time_scale_control, { text="x0.5", draw=draw_button,
        click=proc (f: ^ui.Frame) { app.ui.clock.time_scale=.5 },
    })
    ui.add_frame(time_scale_control, { text="x1", draw=draw_button,
        click=proc (f: ^ui.Frame) { app.ui.clock.time_scale=1 },
    })
    ui.add_frame(time_scale_control, { text="x2", draw=draw_button,
        click=proc (f: ^ui.Frame) { app.ui.clock.time_scale=2 },
    })
    ui.add_frame(time_scale_control, { text="x4", draw=draw_button,
        click=proc (f: ^ui.Frame) { app.ui.clock.time_scale=4 },
    })

    ui.add_frame(app.ui.root,
        { size={270,70}, text="Toggle Popup", draw=draw_button, click=click_toggle_popup },
        { point=.top, offset={0,20} },
    )

    popup := ui.add_frame(app.ui.root,
        { size={640,440}, name="popup", flags={.hidden}, draw=draw_panel },
        { point=.center },
    )

    popup_header := ui.add_frame(popup,
        { size={0,100}, text="Hello, World!", draw=draw_panel_header },
        { point=.top_left },
        { point=.top_right },
    )

    popup_button := ui.add_frame(popup,
        { size={170,70}, text="Close", draw=draw_button,
            click=proc (f: ^ui.Frame) { ui.animate(f.parent, anim_hide_slide_down, .2) } },
        { point=.bottom, offset={0,-40} },
    )

    container := ui.add_frame(popup,
        { name="slots", layout={ dir=.left_and_right, align=.center, size={80,140}, pad=40 } },
        { point=.top_left, rel_point=.bottom_left, rel_frame=popup_header },
        { point=.bottom, rel_point=.top, rel_frame=popup_button },
        { point=.right },
    )

    for text in ([] string { "A", "B", "C", "D", "E" }) {
        ui.add_frame(container, { name=text, text=text, draw=draw_slot,
            enter=proc (f: ^ui.Frame) { ui.animate(f, anim_slot_enter_feedback, .2) },
            leave=proc (f: ^ui.Frame) { ui.animate(f, anim_slot_leave_feedback, .6) },
        })
    }

    for !rl.WindowShouldClose() {
        free_all(context.temp_allocator)

        ui.update_ui(app.ui,
            { 0,0,f32(rl.GetScreenWidth()),f32(rl.GetScreenHeight()) },
            { rl.GetMousePosition(), rl.GetMouseWheelMove(), rl.IsMouseButtonDown(.LEFT) },
        )

        rl.BeginDrawing()
        rl.ClearBackground(rl.DARKBROWN)

        ui.draw_ui(app.ui)
        if rl.IsKeyDown(.LEFT_CONTROL) do draw.debug_frame_tree(app.ui.root)

        draw.text(
            fmt.tprintf("clock: %#v", app.ui.clock),
            {10,30}, app.res.fonts["default"], Color {255,255,255,255},
        )

        rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }

    ui.destroy_ui(app.ui)
    res.destroy(app.res)

    rl.CloseWindow()
}

click_toggle_popup :: proc (f: ^ui.Frame) {
    popup := ui.get(app.ui.root, "popup")

    if .hidden in popup.flags {
        ui.animate(popup, anim_show_slide_up, .5)
        for child in ui.get(popup, "slots").children {
            ui.animate(child, anim_slot_leave_feedback, .9)
        }
    } else {
        ui.animate(popup, anim_hide_slide_down, .2)
    }
}

draw_label :: proc (f: ^ui.Frame) {
    font := app.res.fonts["heavy"]
    tx_color := core.alpha({255,255,255,255}, f.opacity)
    draw.text_center(f.text, core.rect_center(f.rect)+{0,8}, font, tx_color)
}

draw_button :: proc (f: ^ui.Frame) {
    font := app.res.fonts["default"]
    bg_color := core.alpha({200,150,100,255}, f.opacity)
    tx_color := core.alpha({80,60,40,255}, f.opacity)

    rect1 := f.rect
    rect2 := core.rect_moved(core.rect_inflated(f.rect, {8,0}), {0,8})

    if f.captured do rect1.y += 8
    else do draw.rect(rect2, core.alpha(core.brightness(bg_color, -.7), .5))

    draw.rect(rect1, bg_color)
    draw.rect_lines(rect1, 4, core.brightness(bg_color, f.hovered ? .6 : .3))
    draw.text_center(f.text, core.rect_center(rect1)+{0,4}, font, tx_color)
}

draw_panel :: proc (f: ^ui.Frame) {
    bg_color := core.alpha({140,180,220,255}, f.opacity)

    draw.rect(f.rect, bg_color)
    draw.rect_lines(f.rect, 4, core.brightness(bg_color, .4))
}

draw_panel_header :: proc (f: ^ui.Frame) {
    font := app.res.fonts["heavy"]
    tx_color := core.alpha({255,255,255,255}, f.opacity)
    ln_color := core.alpha(core.brightness({140,180,220,255}, .4), f.opacity)

    draw.rect(core.rect_line_bottom(core.rect_inflated(f.rect, {-40,0}), 4), ln_color)
    draw.text_center(f.text, core.rect_center(f.rect)+{0,8}, font, tx_color)
}

draw_slot :: proc (f: ^ui.Frame) {
    font := app.res.fonts["huge"]
    tx_color := core.alpha({40,40,40,255}, f.opacity)
    if f.hovered {
        draw.rect_lines(f.rect, 4, tx_color)
        if f.animation.tick == nil {
            font2 := app.res.fonts["default"]
            sub_text := fmt.tprintf("Hello, %s!", f.text)
            draw.text_center(sub_text, core.rect_center(f.rect)+{0,46}, font2, tx_color)
        }
    }
    draw.text_center(f.text, core.rect_center(f.rect)+{0,6}, font, tx_color)
}

anim_show_slide_up :: proc (f: ^ui.Frame, ratio: f32) {
    fmt.println(#procedure, f.name, ratio)

    ui.set_opacity(f, min(1, 3*ratio))
    f.offset = { 0, 40 * (1 - core.ease_ratio(ratio, .Elastic_Out)) }
    if ratio == 0 do ui.show(f)
}

anim_hide_slide_down :: proc (f: ^ui.Frame, ratio: f32) {
    fmt.println(#procedure, f.name, ratio)

    ui.set_opacity(f, 1-ratio)
    f.offset = { 0, 80 * core.ease_ratio(ratio, .Cubic_In) }
    if ratio == 1 do ui.hide(f)
}

anim_slot_enter_feedback :: proc (f: ^ui.Frame, ratio: f32) {
    fmt.println(#procedure, f.name, ratio)

    base_w := f.parent.layout.size.x
    f.size = { base_w + base_w * core.ease_ratio(ratio, .Cubic_Out), 0 }
}

anim_slot_leave_feedback :: proc (f: ^ui.Frame, ratio: f32) {
    fmt.println(#procedure, f.name, ratio)

    base_w := f.parent.layout.size.x
    f.size = { base_w*2 - base_w * core.ease_ratio(ratio, .Cubic_Out), 0 }
}
