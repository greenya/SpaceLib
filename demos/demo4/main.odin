package demo4

import "spacelib:core/tracking_allocator"

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print_report_with_issues_only()

    app_startup()

    for app_running() {
        app_tick()
        app_draw()
    }

    app_shutdown()
}
