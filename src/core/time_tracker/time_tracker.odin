package time_tracker

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
    by_avg,
    by_max,
}

_tracks: map [string] Track

when "off" == #config(TIME_TRACKER, "on") {

init    :: proc (skip_ms := 0) {}
destroy :: proc () {}
start   :: proc (name: string) {}
stop    :: proc (name: string) {}
scope   :: proc (name: string) {}
print   :: proc (order: Print_Order) {}

} else {

_tick_init      : time.Tick
_tick_skip_until: time.Tick

init :: proc (skip_ms := 0) {
    _tick_init = time.tick_now()
    _tick_skip_until = time.tick_add(_tick_init, time.Duration(skip_ms) * time.Millisecond)
    fmt.println("[TT] Initialized")
}

destroy :: proc () {
    delete(_tracks)
    _tracks = nil
}

start :: proc (name: string) {
    tick_now := time.tick_now()
    if tick_now._nsec < _tick_skip_until._nsec do return

    if name not_in _tracks do _tracks[name] = {}
    track := &_tracks[name]
    fmt.assertf(track.start == {}, "Track `%s` already started", name)

    track.start = tick_now
    track.calls += 1
}

stop :: proc (name: string) {
    if name not_in _tracks do _tracks[name] = {}
    track := &_tracks[name]
    if track.start._nsec == 0 do return

    duration := time.tick_since(track.start)
    track.total += duration
    track.max = max(track.max, duration)
    track.start._nsec = 0
}

@(deferred_out=_scope_end)
scope :: proc (name: string) -> string {
    start(name)
    return name
}

_scope_end :: proc (name: string) {
    stop(name)
}

print :: proc (order: Print_Order) {
    if len(_tracks) == 0 {
        fmt.println("[TT] No tracks")
        return
    }

    entries, _ := slice.map_entries(_tracks, context.temp_allocator)
    switch order {
    case .by_name   : slice.sort_by(entries, less=_cmp_track_entries_by_name)
    case .by_calls  : slice.sort_by(entries, less=_cmp_track_entries_by_calls)
    case .by_avg    : slice.sort_by(entries, less=_cmp_track_entries_by_avg)
    case .by_max    : slice.sort_by(entries, less=_cmp_track_entries_by_max)
    }

    tbl: table.Table
    table.init(&tbl, table_allocator=context.temp_allocator)
    table.padding(&tbl, 1, 1)

    table.caption(&tbl, fmt.tprintf(
        "Time Tracker: order=%v, skip=%v, -o:%v",
        order,
        time.tick_diff(_tick_init, _tick_skip_until),
        ODIN_OPTIMIZATION_MODE,
    ))

    table.header(&tbl, "Name", "Avg", "Max", "Total", "Calls")

    for e in entries {
        name := e.key
        track := e.value
        table.row(&tbl, name, _track_avg(track), track.max, track.total, track.calls)
    }

    table.write_plain_table(table.stdio_writer(), &tbl)
}

_cmp_track_entries_by_name :: proc (a, b: slice.Map_Entry(string, Track)) -> bool {
    return -1 == strings.compare(a.key, b.key)
}

_cmp_track_entries_by_calls :: proc (a, b: slice.Map_Entry(string, Track)) -> bool {
    return a.value.calls > b.value.calls
}

_cmp_track_entries_by_avg :: proc (a, b: slice.Map_Entry(string, Track)) -> bool {
    return _track_avg(a.value) > _track_avg(b.value)
}

_cmp_track_entries_by_max :: proc (a, b: slice.Map_Entry(string, Track)) -> bool {
    return a.value.max > b.value.max
}

_track_avg :: proc (t: Track) -> time.Duration {
    return time.Duration(i64(t.total) / i64(t.calls))
}

} // end of "else" of "when #config..."
