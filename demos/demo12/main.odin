package demo12

import "spacelib:core/tracking_allocator"

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print(.minimal_unless_issues)

    app_startup()

    for app_running() {
        app_tick()
        app_draw()
        free_all(context.temp_allocator)
    }

    app_shutdown()
}
