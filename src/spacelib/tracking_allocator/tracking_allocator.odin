package spacelib_tracking_allocator

import "core:fmt"
import "core:mem"

/*

Usage:

    import sl_ta "..."
    main :: proc () {
        context.allocator = sl_ta.init()
        defer sl_ta.print_report()
        ...
    }

*/

init :: proc () -> mem.Allocator {
    mem.tracking_allocator_init(&track, context.allocator)
    fmt.println("Tracking allocator initialized")
    return mem.tracking_allocator(&track)
}

print_report :: proc () {
    fmt.println("---- Tracking allocator report ----")
    fmt.println("Current memory allocated :", track.current_memory_allocated)
    fmt.println("Total memory allocated   :", track.total_memory_allocated)
    fmt.println("Total allocation count   :", track.total_allocation_count)
    fmt.println("Total memory freed       :", track.total_memory_freed)
    fmt.println("Total free count         :", track.total_free_count)
    fmt.println("Peak memory allocated    :", track.peak_memory_allocated)

    if len(track.allocation_map) > 0 {
        fmt.eprintfln("%v allocation(s) not freed:", len(track.allocation_map))
        for _, entry in track.allocation_map {
            fmt.eprintfln("- %v bytes @ %v", entry.size, entry.location)
        }
    }

    if len(track.bad_free_array) > 0 {
        fmt.eprintfln("%v incorrect free(s):", len(track.bad_free_array))
        for entry in track.bad_free_array {
            fmt.eprintfln("- %p @ %v", entry.memory, entry.location)
        }
    }

    mem.tracking_allocator_destroy(&track)
    fmt.println("-----------------------------------")
}

@(private)
track: mem.Tracking_Allocator
