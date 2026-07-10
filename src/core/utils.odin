package spacelib_core

import "base:intrinsics"
import "core:reflect"
import "core:slice"
import "core:strings"

_ :: reflect
_ :: slice

string_prefix_from_slice :: proc (s: string, prefixes: [] string) -> string {
    for prefix in prefixes {
        assert(prefix != "")
        if strings.has_prefix(s, prefix) do return prefix
    }
    return ""
}

string_suffix_from_slice :: proc (s: string, suffixes: [] string) -> string {
    for suffix in suffixes {
        assert(suffix != "")
        if strings.has_suffix(s, suffix) do return suffix
    }
    return ""
}

map_keys_sorted :: proc (m: $M / map [$K] $V, allocator := context.allocator) -> [] string {
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

// Converts given `int` to `string` using provided alphabet base.
// The alphabet should consist of unique chars and be 2+ chars long.
//
// Examples:
// - input: `n=1000`, `abc="0123456789ABCDEF"`, `min_len=8`; output: `000003E8`
// - input: `n=1000`, `abc="STRING"`; output: `SSNINN`
//
// Note: `abc_base_to_int()` converts result back from `string` to `int`.
int_to_abc_base :: proc (n: int, b: ^strings.Builder, abc: string, min_len := 1) -> string #no_bounds_check {
    base := len(abc)
    assert(base >= 2)
    assert(min_len >= 1)

    strings.builder_reset(b)

    if n > 0 {
        for r := n; r > 0; r /= base {
            i := r % base
            strings.write_byte(b, abc[i])
        }
    } else {
        strings.write_byte(b, abc[0])
    }

    for len(b.buf) < min_len {
        strings.write_byte(b, abc[0])
    }

    slice.reverse(b.buf[:])
    return strings.to_string(b^)
}

// Converts given `string` (produced by `int_to_abc_base()`) back to `int`.
abc_base_to_int :: proc (s: string, abc: string) -> (result: int, ok: bool) #no_bounds_check {
    base := len(abc)
    assert(base >= 2)

    m := 1
    i := len(s) - 1
    for i >= 0 {
        j := strings.index_byte(abc, s[i])
        if j < 0 do return 0, false
        result += m * j
        m *= base
        i -= 1
    }

    return result, true
}
