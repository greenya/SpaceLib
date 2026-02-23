package spacelib_time_tracker

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:text/table"
import "core:time"

Track :: struct {
    start   : time.Tick,
    total   : time.Duration,
    max     : time.Duration,
    calls   : int,
}

Print_Order :: enum {
    by_name,
    by_calls,
    by_max,
}

tracks: map [string] Track

destroy :: proc () {
    delete(tracks)
    tracks = nil
}

start :: proc (name: string) {
    if name not_in tracks do tracks[name] = {}
    track := &tracks[name]
    fmt.assertf(track.start == {}, "Track `%s` already started", name)

    track.calls += 1
    track.start = time.tick_now()
}

stop :: proc (name: string) {
    if name not_in tracks do tracks[name] = {}
    track := &tracks[name]
    fmt.assertf(track.start != {}, "Track `%s` not started", name)

    duration := time.tick_since(track.start)
    track.start = {}
    track.total += duration
    track.max = max(track.max, duration)
}

@(deferred_out=scope_end)
scope :: proc (name: string, hot := false) -> string {
    #force_inline start(name)
    return name
}

@private
scope_end :: proc (name: string) {
    #force_inline stop(name)
}

print :: proc (order: Print_Order) {
    if len(tracks) == 0 {
        fmt.println("[TT] No tracks")
        return
    }

    entries, _ := slice.map_entries(tracks, context.temp_allocator)
    switch order {
    case .by_name   : slice.sort_by(entries, less=cmp_track_entries_by_name)
    case .by_calls  : slice.sort_by(entries, less=cmp_track_entries_by_calls)
    case .by_max    : slice.sort_by(entries, less=cmp_track_entries_by_max)
    }

    tbl: table.Table
    table.init(&tbl, table_allocator=context.temp_allocator)
    table.caption(&tbl, fmt.tprintf("Time Tracker (order=%v)", order))
    table.padding(&tbl, 1, 1)

    table.header(&tbl, "Name", "Max", "Total", "Calls")

    for e in entries {
        name := e.key
        track := e.value
        table.row(&tbl, name, track.max, track.total, track.calls)
    }

    table.write_plain_table(table.stdio_writer(), &tbl)
}

@private
cmp_track_entries_by_name :: proc (a, b: slice.Map_Entry(string, Track)) -> bool {
    return -1 == strings.compare(a.key, b.key)
}

@private
cmp_track_entries_by_calls :: proc (a, b: slice.Map_Entry(string, Track)) -> bool {
    return a.value.calls > b.value.calls
}

@private
cmp_track_entries_by_max :: proc (a, b: slice.Map_Entry(string, Track)) -> bool {
    return a.value.max > b.value.max
}
