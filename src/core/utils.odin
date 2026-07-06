package spacelib_core

import "base:intrinsics"
import "core:fmt"
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

format_buf_int :: proc (buf: [] u8, value: $T, thousands_sep := u8(',')) -> string where intrinsics.type_is_integer(T) {
    if abs(value) < 1000 do return fmt.bprint(buf, value)

    sb := strings.builder_from_bytes(buf)
    if value < 0 do strings.write_byte(&sb, '-')

    digits_buf: [64] u8
    digits := fmt.bprint(digits_buf[:], abs(value))
    for d, i in digits {
        strings.write_byte(&sb, u8(d))
        i_rev := len(digits) - i + 1
        if i_rev-2>0 && (i_rev-2)%3==0 do strings.write_byte(&sb, thousands_sep)
    }

    return strings.to_string(sb)
}

// cuts-off all `0` decimal digits from the right side;
// examples:
// - `123.211100`, `max=3` -> `123.211`
// - `123.210000`, `max=3` -> `123.21`
// - `123.000000`, `max=3` -> `123`
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
