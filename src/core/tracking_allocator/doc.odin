/*

Tracking Allocator

**Example**

    import "spacelib:core/tracking_allocator"

    main :: proc () {
        context.allocator = tracking_allocator.init()
        defer {
            tracking_allocator.print()
            tracking_allocator.destroy()
        }

        // ...
        buf := make([] int, 1000)
    }

**Command Line**

`-define:TRACKING_ALLOCATOR=off` disables all the tracking allocator code into no-op.

*/
package spacelib_tracking_allocator
