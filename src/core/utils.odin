package spacelib_core

import "base:intrinsics"
import "core:reflect"
import "core:slice"
import "core:strings"

_ :: reflect
_ :: slice

is_consumed :: #force_inline proc (flag: ^bool) -> bool {
    if !flag^ do return false
    flag^ = false
    return true
}

string_prefix_from_slice :: #force_inline proc (s: string, prefixes: [] string) -> string {
    for prefix in prefixes {
        assert(prefix != "")
        if strings.has_prefix(s, prefix) do return prefix
    }
    return ""
}

string_suffix_from_slice :: #force_inline proc (s: string, suffixes: [] string) -> string {
    for suffix in suffixes {
        assert(suffix != "")
        if strings.has_suffix(s, suffix) do return suffix
    }
    return ""
}

map_keys_sorted :: proc (m: $M/map[$K]$V, allocator := context.allocator) -> [] string {
    keys, _ := slice.map_keys(m, context.temp_allocator)
    slice.sort(keys)
    return keys
}

map_enum_names_to_values :: proc ($T: typeid, allocator := context.allocator) -> map [string] T where intrinsics.type_is_enum(T) {
    result := make(map [string] T, allocator)
    for f in reflect.enum_fields_zipped(T) do result[f.name] = T(f.value)
    return result
}

extract_hrs_mins_secs_from_total_seconds :: proc (time_total_sec: f32) -> (hrs: int, mins: int, secs: int) {
    if time_total_sec < 0 do return 0, 0, 0

    total_sec := int(time_total_sec)
    hrs, total_sec      = total_sec/3600, total_sec%3600
    mins, total_sec     = total_sec/60, total_sec%60
    secs                = total_sec
    return
}
