package demo8

import "spacelib:core/tracking_allocator"

main :: proc () {
    context.allocator = tracking_allocator.init(verbosity=.minimal)
    defer {
        tracking_allocator.print()
        tracking_allocator.destroy()
    }

    app_startup()

    for app_running() {
        app_tick()
        app_draw()
        free_all(context.temp_allocator)
    }

    app_shutdown()
}
