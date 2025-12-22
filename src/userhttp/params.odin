package userhttp

import "core:mem"
import "core:slice"
import "core:strings"

Param :: struct {
    name    : string,
    value   : Param_Value,
}

Param_Value :: union { i64, f64, string }

param :: proc (params: [] Param, name: string) -> Param_Value {
    for p in params {
        if strings.equal_fold(name, p.name) {
            return p.value
        }
    }
    return nil
}

@private
clone_params :: proc (params: [] Param, append_content_type := "") -> (result: [] Param, err: mem.Allocator_Error) {
    count := len(params) + (append_content_type != "" ? 1 : 0)

    result = make_([] Param, count) or_return
    for p, i in params {
        result[i].name = strings.clone(p.name) or_return
        switch v in p.value {
        case i64, f64   : result[i].value = v
        case string     : result[i].value = strings.clone(v) or_return
        }
    }

    if append_content_type != "" {
        result[count-1] = {
            name    = strings.clone("Content-Type"),
            value   = strings.clone(append_content_type),
        }
    }

    return
}

@private
delete_params :: proc (params: [] Param) -> (err: mem.Allocator_Error) {
    for p in params {
        delete_(p.name)
        switch v in p.value {
        case i64, f64   : // nothing
        case string     : delete_(v) or_return
        }
    }
    delete_(params) or_return
    return
}

@private
create_headers_from_text :: proc (text: string, allocator: mem.Allocator) -> (headers: [] Param, err: mem.Allocator_Error) {
    headers_temp := make_([dynamic] Param, context.temp_allocator) or_return

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
