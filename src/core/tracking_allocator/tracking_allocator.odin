package spacelib_tracking_allocator

import "core:fmt"
import "core:mem"
import "core:text/table"
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
//          defer {
//              tracking_allocator.print()
//              tracking_allocator.destroy()
//          }
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

print :: proc (verbosity := Print_Verbosity.full_always, max_rows := 10) {
    has_issues :=\
        len(track.allocation_map) > 0 ||
        len(track.bad_free_array) > 0

    if !has_issues do switch verbosity {
    case .full_always           : // nothing
    case .minimal_unless_issues : fmt.println("[TA] No issues"); return
    case .silent_unless_issues  : return // silence goes here
    }

    print_stats()
    print_not_freed_allocations(max_rows)
    print_bad_frees(max_rows)
}

@private
print_stats :: proc () {
    fmt_i64 :: proc (i: i64) -> string { return core.format_int_tmp(int(i)) }

    tbl: table.Table
    table.init(&tbl, table_allocator=context.temp_allocator)
    table.caption(&tbl, "Tracking Allocator Stats")
    table.padding(&tbl, 1, 1)

    table.row(&tbl, "Current memory allocated"  , fmt_i64(track.current_memory_allocated))
    table.row(&tbl, "Peak memory allocated"     , fmt_i64(track.peak_memory_allocated))
    table.row(&tbl, "Total memory allocated"    , fmt_i64(track.total_memory_allocated))
    table.row(&tbl, "Total memory freed"        , fmt_i64(track.total_memory_freed))
    table.row(&tbl, "Total allocation count"    , fmt_i64(track.total_allocation_count))
    table.row(&tbl, "Total free count"          , fmt_i64(track.total_free_count))

    table.write_plain_table(table.stdio_writer(), &tbl)
}

@private
print_not_freed_allocations :: proc (max_rows: int) {
    allocation_map_len := len(track.allocation_map)
    if allocation_map_len == 0 do return

    tbl: table.Table
    table.init(&tbl, table_allocator=context.temp_allocator)
    table.caption(&tbl, fmt.tprintf("Tracking Allocator: %s allocation(s) not freed", fmt_int(allocation_map_len)))
    table.padding(&tbl, 1, 1)

    table.header(&tbl, "Bytes", "Location")

    i := 0; for _, entry in track.allocation_map {
        table.row(&tbl, fmt_int(entry.size), entry.location)
        i += 1; if i == max_rows {
            skip_row_count := allocation_map_len - max_rows
            table.row(&tbl, "...", fmt.tprintf("... (+ %s rows)", fmt_int(skip_row_count)))
            break
        }
    }

    table.write_plain_table(table.stdio_writer(), &tbl)
}

@private
print_bad_frees :: proc (max_rows: int) {
    bad_free_array_len := len(track.bad_free_array)
    if bad_free_array_len == 0 do return

    tbl: table.Table
    table.init(&tbl, table_allocator=context.temp_allocator)
    table.caption(&tbl, fmt.tprintf("Tracking Allocator: %s incorrect free(s)", fmt_int(bad_free_array_len)))
    table.padding(&tbl, 1, 1)

    table.header(&tbl, "Address", "Location")

    for entry, i in track.bad_free_array {
        table.row(&tbl, entry.memory, entry.location)
        if i == max_rows {
            skip_row_count := bad_free_array_len - max_rows
            table.row(&tbl, "...", fmt.tprintf("... (+ %s rows)", fmt_int(skip_row_count)))
            break
        }
    }

    table.write_plain_table(table.stdio_writer(), &tbl)
}

@private fmt_int :: proc (i: int) -> string { return core.format_int_tmp(i) }
@private fmt_i64 :: proc (i: i64) -> string { assert(i==i64(int(i))); return core.format_int_tmp(int(i)) }
