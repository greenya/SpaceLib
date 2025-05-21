package spacelib_core

import "core:slice"
_ :: slice

is_consumed :: #force_inline proc (flag: ^bool) -> bool {
    if !flag^ do return false
    flag^ = false
    return true
}

map_keys_sorted :: proc (m: $M/map[$K]$V, allocator := context.allocator) -> [] string {
    keys, _ := slice.map_keys(m, context.temp_allocator)
    slice.sort(keys)
    return keys
}

extract_hrs_mins_secs_from_total_seconds :: proc (time_total_sec: f32) -> (hrs: int, mins: int, secs: int) {
    if time_total_sec < 0 do return 0, 0, 0

    total_sec := int(time_total_sec)
    hrs, total_sec      = total_sec/3600, total_sec%3600
    mins, total_sec     = total_sec/60, total_sec%60
    secs                = total_sec
    return
}
