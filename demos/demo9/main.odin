package demo9

import "spacelib:core/stack_trace"
import "spacelib:core/timed_scope"
import "spacelib:core/tracking_allocator"

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print(.minimal_unless_issues)

    context.assertion_failure_proc = stack_trace.init()
    defer stack_trace.destroy()

    defer timed_scope.print()

    app_startup()

    for app_running() {
        free_all(context.temp_allocator)
        app_tick()
        app_draw()
    }

    app_shutdown()
}
