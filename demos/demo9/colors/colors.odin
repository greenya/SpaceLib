package demo9_colors

import "core:fmt"
import "core:reflect"
import "core:strings"

import "spacelib:core"

ID :: enum {
    default,
    bg0,
    bg1,
    bg2,
    primary,
    accent,
}

Tag :: enum {
    vars_alpha,
    vars_brightness,
}

@private Color :: core.Color

@private colors: [ID] Color
@private color_vars: map [string] Color
@private color_tags: [ID] bit_set [Tag] = #partial {
    .primary    = { .vars_alpha, .vars_brightness },
    .accent     = { .vars_alpha, .vars_brightness },
}

create :: proc () {
    assert(color_vars == nil)

    for id in ID do switch id {
    case .default   : set(id, core.red)
    case .bg0       : set(id, core.black)
    case .bg1       : set(id, core.color_from_hex("#151515"))
    case .bg2       : set(id, core.color_from_hex("#223"))
    case .primary   : set(id, core.color_from_hex("#fd9"))
    case .accent    : set(id, core.color_from_hex("#f9f"))
    }
}

destroy :: proc () {
    colors = {}

    for name in color_vars do delete(name)
    delete(color_vars)
    color_vars = nil
}

get :: #force_inline proc (id: ID, brightness := f32(0), alpha := f32(1)) -> Color {
    color := colors[id]
    if brightness != 0  do color = core.brightness(color, brightness)
    if alpha != 1       do color = core.alpha(color, alpha)
    return color
}

get_by_name :: #force_inline proc (name: string, alpha := f32(1)) -> Color {
    color: Color

    if len(name) > 0 && name[0] == '#' {
        color = core.color_from_hex(name)
    } else {
        fmt.assertf(name in color_vars, "Unknown color \"%s\"", name)
        color = color_vars[name]
    }

    if alpha != 1 do color = core.alpha(color, alpha)
    return color
}

set :: proc (id: ID, color: Color) {
    name := reflect.enum_string(id)
    assert(name != "")

    colors[id] = color
    set_color_var(name, color)

    if .vars_alpha in color_tags[id] {
        // alpha variations:
        // - gen colors from "color_a1" to "color_a9"
        // - we don't gen "color_a0" (always fully transparent), and "color_a10" (the same as just "color")
        for i in 1..=9 {
            n := fmt.tprintf("%s_a%i", name, i)
            set_color_var(n, core.alpha(colors[id], f32(i)/10))
        }
    }

    if .vars_brightness in color_tags[id] {
        // brightness variations:
        // - gen colors from "color_d9" (-9) to "color_l9" (+9)
        // - we don't gen "color_d0" or "color_l0", that is same as just "color"
        // - we also don't gen "color_d10" (always black), and "color_l10" (always white)
        for i in -9..=9 {
            if i == 0 do continue
            n := fmt.tprintf("%s_%c%i", name, i<0?'d':'l', abs(i))
            set_color_var(n, core.brightness(colors[id], f32(i)/10))
        }
    }
}

@private
set_color_var :: #force_inline proc (name: string, color: Color) {
    name := name
    if name not_in color_vars do name = strings.clone(name)
    color_vars[name] = color
}
