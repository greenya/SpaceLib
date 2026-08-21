/*

Time Tracker

**Example**

    import "spacelib:core/time_tracker"

    main :: proc () {
        time_tracker.init(skip_ms=500)
        defer {
            time_tracker.print(.by_avg)
            time_tracker.destroy()
        }
        // ...
        for _ in 0..<10 do work()
    }

    work :: proc () {
        time_tracker.scope(#procedure)
        // ...
        {
            time_tracker.scope("some scope")
            // ...
        }
        time_tracker.start("some block")
        // ...
        time_tracker.stop("some block")
    }

**Command Line**

`-define:TIME_TRACKER=off` disables all the time tracking code into no-op.

*/

package time_tracker
