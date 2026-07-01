package main

import "core:fmt"

import "../../core"
import "../../core/tracking_allocator"
import hi ".."
import k2 "../../../../karl2d"

log :: fmt.println
logf :: fmt.printfln

main :: proc () {
    context.allocator = tracking_allocator.init(verbosity=.minimal)
    defer {
        tracking_allocator.print()
        tracking_allocator.destroy()
    }

    k2.init(1280, 720, "demo3", { window_mode=.Windowed_Resizable })
    defer k2.shutdown()

    app_init()
    defer app_destroy()

    app_add_panel(path="")

    for main_update() {
        main_draw()
        free_all(context.temp_allocator)
    }
}

main_update :: proc () -> (keep_running: bool) {
    keep_running = k2.update() && !k2.key_went_down(.Escape)

    dt := k2.get_frame_time()
    screen_size := k2.get_screen_size()
    wheel_delta := k2.get_mouse_wheel_delta()
    mouse_input := hi.Mouse_Input {
        lmb_down = k2.mouse_button_is_held(.Left),
        screen_pos = k2.get_mouse_position(),
        wheel_delta = wheel_delta,
    }

    if k2.key_went_down(.Tab) {
        debug := .debug not_in app.ui.root.flags
        hi.set_debug(app.ui.root, debug)
        app.ui_panel_list.padding = debug ? {270,0,0,0} : {}
        hi.queue_solve_context(app.ui)
    }

    app.ui.ref_size = screen_size
    hi.update_context(app.ui, screen_size, mouse_input, dt)

    return
}

main_draw :: proc () {
    k2.clear(core.gray2)
    hi.draw_context(app.ui)
    k2.present()
}
