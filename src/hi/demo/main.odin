package main

// import "core:fmt"
// import rl "vendor:raylib"
import hi ".."

main :: proc () {
    ctx := hi.create_context({
        ref_size = 2 * {320,180},
        ref_font_height = 16,
        align_center = true,
    })

    {
        context.user_ptr = hi.begin_scope(ctx)
        defer hi.end_scope()

        /*dialog_id :=*/ add_dialog(
            name = "dialog_exit_game",
            title = "Exit Game?",
            content = "All unsaved progress will be lost. Proceed?",
            button1 = "Yes",
            button2 = "No",
            button3 = "Maybe",
            with_header_close_button = true,
        )

        // After the dialog has been setup, we probably would assign handler, for example:
        // > hi.on_click(dialog_id, proc () { ... })
        // > hi.on_child_click(dialog_id, "footer/button1", proc () { ... })

        // The ugly part of the approach:
        // > hi.on_child_click(dialog_id, "footer/button1", proc () { ... })
        // is that now we need to know the structure -- "footer/button1", and if it changes,
        // this code stops working; maybe we could express it like:
        // > hi.listen(dialog_id, proc (event: string, data: any) { ... })
        // where listen() is a general way to subscribe to custom events of the View, the send an event
        // the View implementation (a dialog) can do
        // > hi.emit(dialog_id, "click_button1", args)
        // basically the idea is that dialog knows its structure, it can modify
        // it any time, we do not depend on it as we don't subscribe to the direct View by path,
        // but rather we "listen" to the custom dialog's event, which any View can emit (well, any code
        // can emit any event, e.g. just pass View's ID and some string as event name)
    }

    // hi.print_tree(ctx)

    hi.update_context(ctx,
        screen_size = { 1280, 720 },
        mouse_input = {
            screen_pos = {1280/2,720/2},
            lmb_down = false,
            scroll_delta = 0,
        },
        dt = .016,
    )

    hi.print_context(ctx)
}

// **** NOTES ****
// * lets don't think about actual "text" content for now (title, content, button1, button2, button3)
// * lets get stuff working for correctly placed rectangles first
// * for text we might want to think about localization, so those will not be strings to display, but some enum or string ids (not sure for now)

add_dialog :: proc (name, title, content, button1: string, button2 := "", button3 := "", with_header_close_button := false) -> (id: hi.ID) {
    id = hi.begin_view({
        name        = name,
        flags       = {.fit_y},
        size        = {200,0},
        padding     = 10,
        layout      = {dir=.column},
        placement   = {anchor=.5,pivot=.5},
    })
    defer hi.end_view()

    hi.begin_view({ name="header", flags={.fill_x,.fit_y}, padding={5,0,0,0}, layout={dir=.row,align=.center,gap=10} })
        hi.add_view({ name="title", flags={.fill_x}, size={0,14}, /*, text=title*/ })
        if with_header_close_button {
            add_icon_button(name="button_close", icon="cross")
        }
    hi.end_view()

    hi.add_view({ name="content", flags={.fill_x}, size={0,80} /*, padding=10, text=content*/ })

    hi.begin_view({ name="columns", flags={.fill_x}, size={0,50}, layout={dir=.row} })
        hi.add_view({ name="col_10", flags={.ratio_x,.fill_y}, size={.1,0} })
        hi.add_view({ name="col_40", flags={.ratio_x,.fill_y}, size={.4,0} })
        hi.add_view({ name="col_50", flags={.fill_x,.fill_y} })
    hi.end_view()

    // Invalid setup: height cannot be solved: parent-fit & child-fill
    // Idea is to not crash or hang, child just collapses to 0 height,
    // parent should keep height proper to pad and gap with 0 height children too
    hi.begin_view({ name="fit_parent", flags={.fill_x,.fit_y}, padding=5, layout={dir=.column,gap=10} })
        hi.add_view({ name="ratio_x_fill_y", flags={.ratio_x,.fill_y}, size={.5,0} })
        hi.add_view({ name="ratio_x_fill_y", flags={.ratio_x,.fill_y}, size={.5,0} })
    hi.end_view()

    // When layout direction is not set, and fit_* is set, we still wrap max dimension
    // The "fit_layout_none" below should have solved.size={120,170}, e.g. 100x150 + pad
    hi.begin_view({ name="fit_layout_none", flags={.fit_x,.fit_y}, padding=10 })
        hi.add_view({ name="box_100x20", size={100,20} })
        hi.add_view({ name="box_1000x1000_hidden", size=1000, flags={.hidden} })
        hi.add_view({ name="box_20x150", size={20,150} })
    hi.end_view()

    // Test 50% columns with pad and gap. Each column should have same solved.size
    // and they should fit into parent with pad and gap
    hi.begin_view({ name="column_ratio_pad_gap", flags={.fill_x}, size={0,40}, padding=5, layout={dir=.row,gap=10} })
        hi.add_view({ name="col_left", flags={.fill_x,.fill_y}, size={.5,0} })
        hi.add_view({ name="col_right", flags={.fill_x,.fill_y}, size={.5,0} })
    hi.end_view()

    // Test if we subtract gaps only on main axis when children uses ratio_*.
    // Each row below should have solved.size.x=170, e.g. 180 - pad
    hi.begin_view({ name="cross_axis_no_gaps", flags={.fill_x,.fit_y}, padding=5, layout={dir=.column,gap=10} })
        hi.add_view({ name="row_20", flags={.ratio_x}, size={1,20} })
        hi.add_view({ name="row_30", flags={.ratio_x}, size={1,30} })
        hi.add_view({ name="row_40", flags={.ratio_x}, size={1,40} })
    hi.end_view()

    hi.begin_view({ name="footer", flags={.fill_x,.fit_y}, padding=5, layout={dir=.row,justify=.center,align=.center,gap=10} })
        add_text_button(name="button1", text=button1)
        if button2 != "" do add_text_button(name="button2", text=button2)
        if button3 != "" do add_text_button(name="button3", text=button3)
    hi.end_view()

    return
}

// `icon` is not used for now
add_icon_button :: proc (name, icon: string) {
    hi.add_view({ name=name, size={20,20} })
}

// `text` is not used for now
add_text_button :: proc (name, text: string) {
    hi.add_view({ name=name, size={60,20} })
}

// This panel tests `fit_*` without layout, the panel solved size updated to fit all children,
// which are positioned directly via `placement`
// **** NOT SUPPORTED AT THE MOMENT ****
// add_tooltip :: proc (name: string) -> (id: hi.ID) {
//     id = hi.begin_view({ name=name, flags={.fit_x,.fit_y}, placement={anchor=1,pivot=1} })
//     defer hi.end_view()

//     hi.add_view({ name="item1", placement={offset=} })

//     return
// }

/*

main :: proc () {
    ctx := hi.create_context({
        ref_size = {320,180},
        ref_font_height = 16,
        align_center = true,
    })

    // ctx->begin()
    // ctx->end()

    context.user_ptr = &ctx
    context.user_index = 0

    context.user_ptr, context.user_index = hi.set_context(&ctx)

    hi.begin_view_context(&ctx, { name="dialog_exit_game", size={120,80} })
        hi.begin_view({ name="header", size={120,20} })
            hi.add_view({ name="text", size={100,20} })
            hi.add_view({ name="button_close", size={20,20} })
        hi.end_view()
        hi.begin_view({ name="content", size={120,60} })
            hi.add_view({ name="button_yes", size={60,20} })
            hi.add_view({ name="button_no", size={60,20} })
        hi.end_view()
    hi.end_view_context()

    dialog_id   := hi.add_view(&ctx, { name="dialog_exit_game", size={120,80} })

    header_id   := hi.add_view(&ctx, { parent=dialog_id, name="header", size={120,20} })
                   hi.add_view(&ctx, { parent=header_id, name="text", size={100,20} })
                   hi.add_view(&ctx, { parent=header_id, name="button_close", size={20,20} })

    content_id  := hi.add_view(&ctx, { parent=dialog_id, name="content", size={120,60} })
                   hi.add_view(&ctx, { parent=content_id, name="button_yes", size={60,20} })
                   hi.add_view(&ctx, { parent=content_id, name="button_no", size={60,20} })

    // hi.on_click(dialog_id, "title_bar/button_close", (event: hi.Mouse_Event) -> bool {
    //     // TODO: close dialog_id, e.g. hi.hide_view(dialog_id)
    //     return true
    // })

    // fmt.printfln("VIEWS: %#v", ctx.views[:])
    hi.print_tree(ctx)

    if true do return // !! DEBUG

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "hi demo")
    defer rl.CloseWindow()

    for !rl.WindowShouldClose() {
        hi.update_context(&ctx,
            screen_size = { int(rl.GetScreenWidth()), int(rl.GetScreenHeight()) },
            mouse_input = {
                screen_pos = rl.GetMousePosition(),
                lmb_down = rl.IsMouseButtonDown(.LEFT),
                scroll_delta = rl.GetMouseWheelMove(),
            },
            dt = rl.GetFrameTime(),
        )

        rl.BeginDrawing()

        rl.ClearBackground({10,40,20,255})

        hi.draw_context(ctx)

        ui_top_left := hi.ref_to_screen(ctx, {})
        ui_bottom_right := hi.ref_to_screen(ctx, ctx.ref_size)
        ui_rect := rl.Rectangle {
            ui_top_left.x,
            ui_top_left.y,
            ui_bottom_right.x - ui_top_left.x,
            ui_bottom_right.y - ui_top_left.y,
        }
        rl.DrawRectangleLinesEx(ui_rect, 10, {0,255,0,64})

        ui_anchor_pos, ui_anchor_size := hi.get_anchor_root(ctx)
        rl.DrawRectangleLinesEx({ ui_anchor_pos.x, ui_anchor_pos.y, ui_anchor_size.x, ui_anchor_size.y }, 3, {255,255,0,255})

        rl.DrawText(
            rl.TextFormat("%#v", ctx),
            posX=10, posY=10,
            fontSize=20, color=rl.LIME,
        )

        rl.EndDrawing()
    }
}

*/
