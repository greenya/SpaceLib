package spacelib_core

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:strings"

_ :: fmt
_ :: runtime

// Formats integer value with thousands separator.
// - Appends result to given string buffer
// - Returns whole buffer as string
//
// Examples:
// - `value=123`, `thousands_sep=','` -> `123`
// - `value=1234`, `thousands_sep=','` -> `1,234`
// - `value=1234567`, `thousands_sep='.'` -> `1.234.567`
// - `value=-777888999`, `thousands_sep=' '` -> `-777 888 999`
sbprint_int :: proc (sb: ^strings.Builder, value: $T, thousands_sep := u8(',')) -> string where intrinsics.type_is_integer(T) #no_bounds_check {
    digits_buf: [64] u8
    digits := fmt.bprint(digits_buf[:], value)

    if len(digits) > 0 && digits[0] == '-' {
        strings.write_byte(sb, '-')
        digits = digits[1:]
    }

    if len(digits) <= 3 {
        strings.write_string(sb, digits)
    } else {
        rem := len(digits)
        for d in digits {
            strings.write_byte(sb, u8(d))
            rem -= 1
            if rem > 0 && rem%3 == 0 {
                strings.write_byte(sb, thousands_sep)
            }
        }
    }

    return strings.to_string(sb^)
}

// Returns `sbprint_int()` using provided allocator
aprint_int :: proc (value: $T, thousands_sep := u8(','), allocator := context.allocator) -> string where intrinsics.type_is_integer(T) {
    sb: strings.Builder
    strings.builder_init(&sb, 0, 32, allocator)
    return sbprint_int(&sb, value, thousands_sep)
}

// Returns `aprint_int()` using `context.temp_allocator`
tprint_int :: proc (value: $T, thousands_sep := u8(',')) -> string where intrinsics.type_is_integer(T) {
    return aprint_int(value, thousands_sep, context.temp_allocator)
}

// Returns `sbprint_int()` using backing buffer
bprint_int :: proc (buf: [] u8, value: $T, thousands_sep := u8(',')) -> string where intrinsics.type_is_integer(T) {
    sb := strings.builder_from_bytes(buf)
    return sbprint_int(&sb, value, thousands_sep)
}

// Cuts-off all `0` decimal digits from the right side.
// - `max_decimal_digits` must be in range `0..9`
//
// Examples:
// - `value=123.456777`, `max_decimal_digits=3` -> `123.457`
// - `value=123.456111`, `max_decimal_digits=3` -> `123.456`
// - `value=123.450000`, `max_decimal_digits=3` -> `123.45`
// - `value=123.000000`, `max_decimal_digits=3` -> `123`
// - `value=123.000111`, `max_decimal_digits=3` -> `123`
sbprint_float :: proc (sb: ^strings.Builder, value: $T, max_decimal_digits: int) -> string where intrinsics.type_is_float(T) #no_bounds_check {
    assert(0 <= max_decimal_digits && max_decimal_digits <= 9)

    format_buf := [?] u8 { '%', '.', '0' + u8(max_decimal_digits), 'f' }
    format := string(format_buf[:])

    arr := cast (^runtime.Raw_Dynamic_Array) &sb.buf
    arr_len_before := arr.len
    fmt.sbprintf(sb, format, value)

    if max_decimal_digits > 0 {
        arr_len_after := arr.len
        text := sb.buf[arr_len_before:arr_len_after]

        // Cut-off zeros from the end until non-'0' is met (a digit or '.')
        #reverse for c, i in text do if c != '0' {
            text = text[:i+1]
            break
        }

        // Cut-off possible last '.' (when all decimal digits are 0)
        last_i := len(text) - 1
        if last_i > 0 && text[last_i] == '.' {
            text = text[:last_i]
        }

        arr.len = arr_len_before + len(text)
    }

    return strings.to_string(sb^)
}

// Returns `sbprint_float()` using provided allocator
aprint_float :: proc (value: $T, max_decimal_digits: int, allocator := context.allocator) -> string where intrinsics.type_is_float(T) {
    sb: strings.Builder
    strings.builder_init(&sb, 0, 32, allocator)
    return sbprint_float(&sb, value, max_decimal_digits)
}

// Returns `aprint_float()` using `context.temp_allocator`
tprint_float :: proc (value: $T, max_decimal_digits: int) -> string where intrinsics.type_is_float(T) {
    return aprint_float(value, max_decimal_digits, context.temp_allocator)
}

// Returns `sbprint_float()` using backing buffer
bprint_float :: proc (buf: [] u8, value: $T, max_decimal_digits: int) -> string where intrinsics.type_is_float(T) {
    sb := strings.builder_from_bytes(buf)
    return sbprint_float(&sb, value, max_decimal_digits)
}
