package spacelib_timed_scope

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:time"

Scope :: struct {
    calls       : int,
    total_dur   : time.Duration,
    min_dur     : time.Duration,
    max_dur     : time.Duration,
}

Print_Order :: enum {
    by_name,
    by_calls,
    by_avg_dur,
}

print_order_cmp_procs: [Print_Order] proc (a, b: slice.Map_Entry(string, Scope)) -> bool = {
    .by_name        = cmp_scope_entries_by_name,
    .by_calls       = cmp_scope_entries_by_calls,
    .by_avg_dur     = cmp_scope_entries_by_avg_dur,
}

scopes: map [string] Scope

destroy :: proc () {
    delete(scopes)
    scopes = nil
}

@(deferred_out=scope_end)
scope :: #force_inline proc (name := "", loc := #caller_location) -> (string, time.Time) {
    name := name
    if name == "" do name = loc.procedure

    if name not_in scopes {
        scopes[name] = {
            min_dur = time.MAX_DURATION,
            max_dur = time.MIN_DURATION,
        }
    }

    scope := &scopes[name]
    scope.calls += 1

    return name, time.now()
}

@private
scope_end :: #force_inline proc (name: string, scope_start_time: time.Time) {
    scope := &scopes[name]
    scope_dur := time.since(scope_start_time)
    scope.total_dur += scope_dur
    scope.min_dur = min(scope.min_dur, scope_dur)
    scope.max_dur = max(scope.max_dur, scope_dur)
}

print :: proc (order := Print_Order.by_name, and_destroy := true) {
    fmt.println("[TS] -------------- Report --------------")

    scope_entries, _ := slice.map_entries(scopes, context.temp_allocator)
    slice.sort_by(scope_entries, less=print_order_cmp_procs[order])

    for e in scope_entries {
        name := e.key
        scope := e.value

        dur_avg := time.Duration(i64(scope.total_dur) / i64(scope.calls))
        dur_avg_ms := time.duration_milliseconds(dur_avg)
        fmt.printfln(
            "[TS] %0.4f %v (%i) %v..%v",
            dur_avg_ms, name, scope.calls, scope.min_dur, scope.max_dur,
        )
    }

    fmt.println("[TS] ------------------------------------")
    if and_destroy do destroy()
}

@private
cmp_scope_entries_by_name :: proc (a, b: slice.Map_Entry(string, Scope)) -> bool {
    return -1 == strings.compare(a.key, b.key)
}

@private
cmp_scope_entries_by_calls :: proc (a, b: slice.Map_Entry(string, Scope)) -> bool {
    return a.value.calls > b.value.calls
}

@private
cmp_scope_entries_by_avg_dur :: proc (a, b: slice.Map_Entry(string, Scope)) -> bool {
    a_dur_avg := time.Duration(i64(a.value.total_dur) / i64(a.value.calls))
    b_dur_avg := time.Duration(i64(b.value.total_dur) / i64(b.value.calls))
    return a_dur_avg > b_dur_avg
}
