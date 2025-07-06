package spacelib_core

any_as_int :: #force_inline proc (value: any) -> int {
    switch a in value { case int: return a }
    panic("Not an int")
}

any_as_f32 :: #force_inline proc (value: any) -> f32 {
    switch a in value { case f32: return a }
    panic("Not a f32")
}

any_as_bool :: #force_inline proc (value: any) -> bool {
    switch a in value { case bool: return a }
    panic("Not a bool")
}

any_as_string :: #force_inline proc (value: any) -> string {
    switch a in value { case string: return a }
    panic("Not a string")
}

any_args_ordered_ssb :: proc (args: [] any) -> (string, string, bool) {
    assert(len(args) == 3)
    return any_as_string(args[0]), any_as_string(args[1]), any_as_bool(args[2])
}
