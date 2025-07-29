package demo9

import "spacelib:core/tracking_allocator"

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print(.minimal_unless_issues, max_issues=10)

    app_startup()

    for app_running() {
        app_tick()
        app_draw()
    }

    app_shutdown()
}
