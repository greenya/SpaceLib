package spacelib_tracking_allocator

import "core:fmt"
import "core:mem"
import "core:text/table"
import "../../core"

Verbosity :: enum {
    full,       // Full
    minimal,    // Minimal, unless issues
    silent,     // Silent, unless issues
}

_track: mem.Tracking_Allocator

when "off" == #config(TRACKING_ALLOCATOR, "on") {

init    :: proc (alloc := context.allocator, silent := false) -> mem.Allocator { return alloc }
destroy :: proc () {}
print   :: proc (verbosity := Verbosity.full, max_rows := 10) {}

} else {

// - `alloc` Allocator to be tracked
// - `silent` True to skip printing init message
init :: proc (alloc := context.allocator, silent := false) -> mem.Allocator {
    mem.tracking_allocator_init(&_track, backing_allocator=alloc)
    if !silent do fmt.println("[TA] Initialized")
    return mem.tracking_allocator(&_track)
}

destroy :: proc () {
    mem.tracking_allocator_destroy(&_track)
    _track = {}
}

print :: proc (verbosity := Verbosity.full, max_rows := 10) {
    has_issues :=\
        len(_track.allocation_map) > 0 ||
        len(_track.bad_free_array) > 0

    if !has_issues do switch verbosity {
    case .full:
        /**/

    case .minimal:
        fmt.printfln("[TA] No issues (%m peak)", _track.peak_memory_allocated)
        return

    case .silent:
        return
    }

    _print_stats()
    _print_not_freed_allocations(max_rows)
    _print_bad_frees(max_rows)
}

_print_stats :: proc () {
    tbl: table.Table
    table.init(&tbl, table_allocator=context.temp_allocator)
    table.caption(&tbl, "Tracking Allocator Stats")
    table.padding(&tbl, 1, 1)

    table.row(&tbl, "Current memory allocated"  , core.tprint_int(_track.current_memory_allocated))
    table.row(&tbl, "Peak memory allocated"     , core.tprint_int(_track.peak_memory_allocated))
    table.row(&tbl, "Total memory allocated"    , core.tprint_int(_track.total_memory_allocated))
    table.row(&tbl, "Total memory freed"        , core.tprint_int(_track.total_memory_freed))
    table.row(&tbl, "Total allocation count"    , core.tprint_int(_track.total_allocation_count))
    table.row(&tbl, "Total free count"          , core.tprint_int(_track.total_free_count))

    table.write_plain_table(table.stdio_writer(), &tbl)
}

_print_not_freed_allocations :: proc (max_rows: int) {
    allocation_map_len := len(_track.allocation_map)
    if allocation_map_len == 0 do return

    tbl: table.Table
    table.init(&tbl, table_allocator=context.temp_allocator)
    table.caption(&tbl, fmt.tprintf("Tracking Allocator: %s allocation(s) not freed", core.tprint_int(allocation_map_len)))
    table.padding(&tbl, 1, 1)

    table.header(&tbl, "Bytes", "Location")

    i := 0; for _, entry in _track.allocation_map {
        table.row(&tbl, core.tprint_int(entry.size), entry.location)
        i += 1; if i == max_rows {
            skip_row_count := allocation_map_len - max_rows
            table.row(&tbl, "...", fmt.tprintf("... (+ %s rows)", core.tprint_int(skip_row_count)))
            break
        }
    }

    table.write_plain_table(table.stdio_writer(), &tbl)
}

_print_bad_frees :: proc (max_rows: int) {
    bad_free_array_len := len(_track.bad_free_array)
    if bad_free_array_len == 0 do return

    tbl: table.Table
    table.init(&tbl, table_allocator=context.temp_allocator)
    table.caption(&tbl, fmt.tprintf("Tracking Allocator: %s incorrect free(s)", core.tprint_int(bad_free_array_len)))
    table.padding(&tbl, 1, 1)

    table.header(&tbl, "Address", "Location")

    for entry, i in _track.bad_free_array {
        table.row(&tbl, entry.memory, entry.location)
        if i == max_rows {
            skip_row_count := bad_free_array_len - max_rows
            table.row(&tbl, "...", fmt.tprintf("... (+ %s rows)", core.tprint_int(skip_row_count)))
            break
        }
    }

    table.write_plain_table(table.stdio_writer(), &tbl)
}

} // end of "else" of "when #config..."
