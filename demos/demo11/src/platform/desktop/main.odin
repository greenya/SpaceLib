package main_desktop

import "spacelib:core/stack_trace"
import "spacelib:core/timed_scope"
import "spacelib:core/tracking_allocator"

_ :: stack_trace
_ :: timed_scope
_ :: tracking_allocator

import app "../.."

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print(.minimal_unless_issues)

    // skip stack_trace usage for non-Windows, as it requires "stdc++_libbacktrace"
    when ODIN_OS == .Windows {
        context.assertion_failure_proc = stack_trace.init()
        defer stack_trace.destroy()
    }

    defer timed_scope.print(.by_avg_dur)

    app.app_startup()

    for app.app_running() {
        app.app_tick()
        app.app_draw()
        free_all(context.temp_allocator)
    }

    app.app_shutdown()
}
