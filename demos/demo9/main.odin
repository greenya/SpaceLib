package demo9

import "spacelib:core/tracking_allocator"

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print(.minimal_unless_issues)

    app_startup()

    for app_running() {
        free_all(context.temp_allocator)
        app_tick()
        app_draw()
    }

    app_shutdown()
}
