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

when "off" == #config(TIME_TRACKER, "on") {

init    :: proc (skip_ms: int) {}
destroy :: proc () {}
start   :: proc (name: string) {}
stop    :: proc (name: string) {}
scope   :: proc (name: string) {}
print   :: proc (order: Print_Order) {}

} else {

@private tick_init: time.Tick
@private tick_skip_until: time.Tick

// Common usage:
//
//      import "spacelib:core/time_tracker"
//      main :: proc () {
//          time_tracker.init(skip_ms=500) // optional, if not called, skip_ms will be effectively 0
//          defer {
//              time_tracker.print(.by_max)
//              time_tracker.destroy()
//          }
//          ...
//      }
//
// Note: `-define:TIME_TRACKER=off` disables all the time tracking code.

init :: proc (skip_ms: int) {
    tick_init = time.tick_now()
    tick_skip_until = time.tick_add(tick_init, time.Duration(skip_ms) * time.Millisecond)
    fmt.println("[TT] Initialized")
}

destroy :: proc () {
    delete(tracks)
    tracks = nil
}

start :: proc (name: string) {
    tick_now := time.tick_now()
    if tick_now._nsec < tick_skip_until._nsec do return

    if name not_in tracks do tracks[name] = {}
    track := &tracks[name]
    fmt.assertf(track.start == {}, "Track `%s` already started", name)

    track.start = tick_now
    track.calls += 1
}

stop :: proc (name: string) {
    if name not_in tracks do tracks[name] = {}
    track := &tracks[name]
    if track.start._nsec == 0 do return

    duration := time.tick_since(track.start)
    track.total += duration
    track.max = max(track.max, duration)
    track.start._nsec = 0
}

@(deferred_out=scope_end)
scope :: proc (name: string) -> string {
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
    table.padding(&tbl, 1, 1)

    table.caption(&tbl, fmt.tprintf(
        "Time Tracker: order=%v, skip=%v, -o:%v",
        order,
        time.tick_diff(tick_init, tick_skip_until),
        ODIN_OPTIMIZATION_MODE,
    ))

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

} // end of "else" of "when #config..."
