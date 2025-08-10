package spacelib_tracking_allocator

import "core:fmt"
import "core:mem"
import "../../core"

Print_Verbosity :: enum {
    full_always,
    minimal_unless_issues,
    silent_unless_issues,
}

track: mem.Tracking_Allocator

// Common usage:
//
//      import "spacelib:core/tracking_allocator"
//      main :: proc () {
//          context.allocator = tracking_allocator.init()
//          defer tracking_allocator.print()
//          ...
//      }

init :: proc () -> mem.Allocator {
    mem.tracking_allocator_init(&track, context.allocator)
    fmt.println("[TA] Initialized")
    return mem.tracking_allocator(&track)
}

destroy :: proc () {
    mem.tracking_allocator_destroy(&track)
    track = {}
}

print :: proc (verbosity := Print_Verbosity.full_always, max_issues := 10, and_destroy := true) {
    defer if and_destroy do destroy()

    has_issues :=\
        len(track.allocation_map) > 0 ||
        len(track.bad_free_array) > 0

    if has_issues {
        print_report(max_issues)
    } else do switch verbosity {
        case .full_always           : print_report(max_issues)
        case .minimal_unless_issues : fmt.println("[TA] No issues")
        case .silent_unless_issues  : // silence goes here
    }
}

@private
print_report :: proc (max_issues: int) {
    fmt_int :: proc (i: int) -> string { return core.format_int(    i , allocator=context.temp_allocator) }
    fmt_i64 :: proc (i: i64) -> string { return core.format_int(int(i), allocator=context.temp_allocator) }

    fmt.println("[TA] --------------- Report ---------------")
    fmt.println("[TA] Current memory allocated :", fmt_i64(track.current_memory_allocated))
    fmt.println("[TA] Peak memory allocated    :", fmt_i64(track.peak_memory_allocated))
    fmt.println("[TA] Total memory allocated   :", fmt_i64(track.total_memory_allocated))
    fmt.println("[TA] Total memory freed       :", fmt_i64(track.total_memory_freed))
    fmt.println("[TA] Total allocation count   :", fmt_i64(track.total_allocation_count))
    fmt.println("[TA] Total free count         :", fmt_i64(track.total_free_count))

    allocation_map_len := len(track.allocation_map)
    if allocation_map_len > 0 {
        fmt.eprintfln("[TA] %s allocation(s) not freed:", fmt_int(allocation_map_len))
        i := 0; for _, entry in track.allocation_map {
            fmt.eprintfln("[TA] - %i bytes @ %v", entry.size, entry.location)
            i += 1; if i == max_issues {
                fmt.eprintln("[TA] ... (and more)")
                break
            }
        }
    }

    bad_free_array_len := len(track.bad_free_array)
    if bad_free_array_len > 0 {
        fmt.eprintfln("[TA] %i incorrect free(s):", bad_free_array_len)
        for entry, i in track.bad_free_array {
            fmt.eprintfln("[TA] - %p @ %v", entry.memory, entry.location)
            if i == max_issues {
                fmt.eprintln("[TA] ... (and more)")
                break
            }
        }
    }

    fmt.println("[TA] --------------------------------------")
}
