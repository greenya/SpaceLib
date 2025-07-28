package spacelib_tracking_allocator

import "core:fmt"
import "core:mem"

@private max_issues_printed :: 10
@private track: mem.Tracking_Allocator

// Usage:
//
//      import "spacelib:tracking_allocator"
//      main :: proc () {
//          context.allocator = tracking_allocator.init()
//          defer tracking_allocator.print_report()
//          ...
//      }

init :: proc () -> mem.Allocator {
    mem.tracking_allocator_init(&track, context.allocator)
    fmt.println("[TA] Initialized")
    return mem.tracking_allocator(&track)
}

current_memory_allocated :: #force_inline proc () -> i64 {
    return track.current_memory_allocated
}

print_report :: proc () {
    fmt.println("[TA] ------------- Report -------------")
    fmt.println("[TA] Current memory allocated :", track.current_memory_allocated)
    fmt.println("[TA] Total memory allocated   :", track.total_memory_allocated)
    fmt.println("[TA] Total allocation count   :", track.total_allocation_count)
    fmt.println("[TA] Total memory freed       :", track.total_memory_freed)
    fmt.println("[TA] Total free count         :", track.total_free_count)
    fmt.println("[TA] Peak memory allocated    :", track.peak_memory_allocated)

    if len(track.allocation_map) > 0 {
        fmt.eprintfln("[TA] %v allocation(s) not freed:", len(track.allocation_map))
        i := 0; for _, entry in track.allocation_map {
            fmt.eprintfln("[TA] - %v bytes @ %v", entry.size, entry.location)
            i += 1; if i == max_issues_printed {
                fmt.eprintln("[TA] ... (and more)")
                break
            }
        }
    }

    if len(track.bad_free_array) > 0 {
        fmt.eprintfln("[TA] %v incorrect free(s):", len(track.bad_free_array))
        for entry, i in track.bad_free_array {
            fmt.eprintfln("[TA] - %p @ %v", entry.memory, entry.location)
            if i == max_issues_printed {
                fmt.eprintln("[TA] ... (and more)")
                break
            }
        }
    }

    mem.tracking_allocator_destroy(&track)
    fmt.println("[TA] ----------------------------------")
}

print_report_with_issues_only :: proc () {
    if len(track.allocation_map) > 0 || len(track.bad_free_array) > 0 {
        print_report()
    } else {
        fmt.println("[TA] No issues")
    }
}
