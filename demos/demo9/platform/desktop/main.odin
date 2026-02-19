package main_desktop

import "spacelib:core/stack_trace"
import "spacelib:core/time_tracker"
import "spacelib:core/tracking_allocator"

import app "../.."

_ :: stack_trace
_ :: time_tracker
_ :: tracking_allocator

main :: proc () {
    when ODIN_DEBUG {
        context.allocator = tracking_allocator.init()
        defer tracking_allocator.print(.minimal_unless_issues)

        // Only for Windows, as it requires "stdc++_libbacktrace" on Mac and Linux
        when ODIN_OS == .Windows {
            context.assertion_failure_proc = stack_trace.init()
            defer stack_trace.destroy()
        }

        defer {
            time_tracker.print(.by_max)
            time_tracker.destroy()
        }
    }

    app.app_startup()

    for app.app_running() {
        app.app_tick()
        app.app_draw()
        free_all(context.temp_allocator)
    }

    app.app_shutdown()
}
