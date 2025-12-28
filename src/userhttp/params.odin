package userhttp

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strings"

// TODO: ? maybe rework params to keep values as strings, only allow to pass `any` in `send_request()`
// for convenience; because we still transmit all key-value pairs as strings (query params and
// headers), and we always have strings in the received response headers;
// p.s.: this change would simplify code greatly: no value switch-cases, no need for param_as_string()

Param :: struct {
    name    : string,
    value   : Param_Value,
}

Param_Value :: union { i64, f64, string }

// `name` is case-insensitive.
param :: proc (params: [] Param, name: string) -> Param_Value {
    for p in params {
        if strings.equal_fold(name, p.name) {
            return p.value
        }
    }
    return nil
}

// `name` is case-insensitive.
param_as_string :: proc (params: [] Param, name: string, allocator := context.allocator) -> (result: string, err: Allocator_Error) #optional_allocator_error {
    value := param(params, name)
    result = fmt.aprint(value, allocator=allocator)
    return
}

// `name` is case-insensitive.
param_exists :: proc (params: [] Param, name: string) -> bool {
    for p in params do if strings.equal_fold(name, p.name) do return true
    return false
}

@private
clone_params :: proc (params: [] Param, append_content_type := "", allocator := context.allocator) -> (result: [] Param, err: Allocator_Error) {
    count := len(params) + (append_content_type != "" ? 1 : 0)

    result = make([] Param, count, allocator) or_return
    for p, i in params {
        result[i].name = strings.clone(p.name, allocator) or_return
        switch v in p.value {
        case i64, f64   : result[i].value = v
        case string     : result[i].value = strings.clone(v, allocator) or_return
        }
    }

    if append_content_type != "" {
        result[count-1] = {
            name    = strings.clone("Content-Type", allocator),
            value   = strings.clone(append_content_type, allocator),
        }
    }

    return
}

@private
delete_params :: proc (params: [] Param) -> (err: Allocator_Error) {
    for p in params {
        delete(p.name)
        switch v in p.value {
        case i64, f64   : // nothing
        case string     : delete(v) or_return
        }
    }
    delete(params) or_return
    return
}

@private
create_headers_from_text :: proc (text: string, allocator: mem.Allocator) -> (headers: [] Param, err: Allocator_Error) {
    headers_temp := make([dynamic] Param, context.temp_allocator) or_return

    for line in strings.split_lines(text, context.temp_allocator) or_return {
        if line == "" do continue

        pair := strings.split_n(line, ":", 2, context.temp_allocator) or_return
        if len(pair) != 2 do continue

        name := strings.trim(pair[0], " \t")
        if name == "" do continue

        value := strings.trim(pair[1], " \t")
        if value == "" do continue

        append(&headers_temp, Param {
            name    = strings.clone(name, allocator) or_return,
            value   = strings.clone(value, allocator) or_return,
        })
    }

    headers = slice.clone(headers_temp[:], allocator)
    return
}

@private
create_params_from_pairs :: proc (pairs: [] [2] string, allocator: mem.Allocator) -> (headers: [] Param, err: Allocator_Error) {
    headers = make([] Param, len(pairs), allocator) or_return

    for p, i in pairs {
        name    := strings.clone(p[0], allocator) or_return
        value   := strings.clone(p[1], allocator) or_return
        headers[i] = { name=name, value=value }
    }

    return
}
