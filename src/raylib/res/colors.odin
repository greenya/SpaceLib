package spacelib_raylib_res

import "core:encoding/json"
import "core:fmt"
import "core:strings"
import "../../core"
import "../../terse"

@private default_colors_json_file_name :: "colors.json"

Color :: struct {
    name        : string,
    using value : core.Color,
}

load_colors :: proc (res: ^Res) {
    assert(len(res.colors) == 0)

    json_file_name := default_colors_json_file_name
    fmt.assertf(json_file_name in res.files, "File \"%s\" not found.", json_file_name)
    json_file := res.files[json_file_name]

    json_colors: [] struct {
        name    : string,
        hex     : string,
    }

    err := json.unmarshal_any(json_file.data, &json_colors, allocator=context.temp_allocator)
    ensure(err == nil)

    for jc in json_colors {
        add_color(res, jc.name, core.color_from_hex(jc.hex))
    }

    if terse.default_color_name not_in res.colors {
        add_color(res, terse.default_color_name, {255,0,255,255})
    }
}

add_color :: proc (res: ^Res, name: string, value: core.Color) {
    color := new(Color)
    color^ = { name=strings.clone(name), value=value }
    res.colors[color.name] = color
}

@private
destroy_colors :: proc (res: ^Res) {
    for _, color in res.colors {
        delete(color.name)
        free(color)
    }

    delete(res.colors)
    res.colors = nil
}
