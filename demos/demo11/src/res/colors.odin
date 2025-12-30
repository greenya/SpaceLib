package res

import "core:fmt"
import "core:reflect"
import "core:strings"
import "spacelib:core"

@private Color :: core.Color

Color_ID :: enum {
    default,
    magenta,
    rose,
    peach,
    amber,
    white,
    cyan,
    turquoise,
    teal,
    indigo,
    plum,
}

@private colors     : [Color_ID] Color
@private color_vars : map [string] Color

@private
create_colors :: proc () {
    assert(colors == {} && color_vars == nil)

    for id in Color_ID do switch id {
    case .default   : set_color(id, core.red)
    // https://lospec.com/palette-list/neon-space
    case .magenta   : set_color(id, core.color_from_hex("#df0772"))
    case .rose      : set_color(id, core.color_from_hex("#fe546f"))
    case .peach     : set_color(id, core.color_from_hex("#ff9e7d"))
    case .amber     : set_color(id, core.color_from_hex("#ffd080"))
    case .white     : set_color(id, core.color_from_hex("#fffdff"))
    case .cyan      : set_color(id, core.color_from_hex("#0bffe6"))
    case .turquoise : set_color(id, core.color_from_hex("#01cbcf"))
    case .teal      : set_color(id, core.color_from_hex("#0188a5"))
    case .indigo    : set_color(id, core.color_from_hex("#3e3264"))
    case .plum      : set_color(id, core.color_from_hex("#352a55"))
    }
}

@private
destroy_colors :: proc () {
    colors = {}
    for id in Color_ID do colors[id] = core.red // make all colors red, just in case

    for name in color_vars do delete(name)
    delete(color_vars)
    color_vars = nil
}

color :: #force_inline proc (id: Color_ID, a := f32(1), b := f32(0)) -> Color {
    color := colors[id]
    if a != 1 do color = core.alpha(color, a)
    if b != 0 do color = core.brightness(color, b)
    return color
}

color_by_name :: #force_inline proc (name: string) -> Color {
    if len(name) > 0 && name[0] == '#' {
        return core.color_from_hex(name)
    } else {
        fmt.assertf(name in color_vars, "Unknown color \"%s\"", name)
        return color_vars[name]
    }
}

set_color_by_id :: proc (id: Color_ID, color: Color) {
    name := reflect.enum_string(id)
    assert(name != "")

    colors[id] = color
    set_color_var(name, color)
}

set_color_by_name :: proc (name: string, color: Color) {
    id, ok := reflect.enum_from_name(Color_ID, name)
    assert(ok)
    set_color(id, color)
}

set_color :: proc {
    set_color_by_id,
    set_color_by_name,
}

@private
set_color_var :: #force_inline proc (name: string, color: Color) {
    name := name
    if name not_in color_vars do name = strings.clone(name)
    color_vars[name] = color
}
