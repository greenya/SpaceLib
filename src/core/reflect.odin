package spacelib_core

import "core:reflect"

any_args_ordered_ssb :: proc (args: [] any) -> (string, string, bool) {
    assert(len(args) == 3)
    s0, s0_ok := reflect.as_string(args[0])
    s1, s1_ok := reflect.as_string(args[1])
    b2, b2_ok := reflect.as_bool(args[2])
    assert(s0_ok && s1_ok && b2_ok)
    return s0, s1, b2
}
