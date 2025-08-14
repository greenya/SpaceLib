package spacelib_core

import "base:intrinsics"
import "core:fmt"
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

format_int :: proc (value: int, thousands_separator := ",", allocator := context.allocator) -> string {
    if abs(value) < 1000 do return fmt.aprint(value, allocator=allocator)

    sb := strings.builder_make(allocator)
    if value < 0 do strings.write_byte(&sb, '-')

    digits := fmt.tprint(abs(value))
    for digit, i in digits {
        strings.write_rune(&sb, digit)
        i_rev := len(digits) - i + 1
        if i_rev-2>0 && (i_rev-2)%3==0 do strings.write_string(&sb, thousands_separator)
    }

    return strings.to_string(sb)
}

// cuts-off all `0` decimal digits from the right side;
// examples:
// - 123.211100, max=3 -> 123.211
// - 123.210000, max=3 -> 123.21
// - 123.000000, max=3 -> 123
format_f32 :: proc (value: f32, max_decimal_digits: int, allocator := context.allocator) -> string {
    format := fmt.tprintf("%%.%if", max_decimal_digits)
    text := fmt.aprintf(format, value, allocator=allocator)
    if max_decimal_digits > 0 {
        // cut-off zeros from the end until non-'0' is met (a digit or '.')
        #reverse for c, i in text do if c != '0' { text=text[:i+1]; break }
        // cut-off possible last '.' (when all decimal digits are 0)
        last_i := len(text)-1
        if last_i > 0 && text[last_i] == '.' do text = text[:last_i]
    }
    return text
}
