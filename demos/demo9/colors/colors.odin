package demo9_colors

import "core:fmt"
import "core:strings"
import "spacelib:core"

@private Color :: core.Color

@private colors: map [string] Color

default : Color
bg0     : Color
bg1     : Color
primary : Color
accent  : Color

create :: proc () {
    assert(len(colors) == 0)

    default = add_color("default" , core.red)
    bg0     = add_color("bg0"     , core.black)
    bg1     = add_color("bg1"     , core.color_from_hex("#223"))
    primary = add_color("primary" , core.color_from_hex("#fd9"), with_variations=true)
    accent  = add_color("accent"  , core.color_from_hex("#f9f"), with_variations=true)
}

destroy :: proc () {
    for name in colors do delete(name)
    delete(colors)
    colors = {}
}

get :: #force_inline proc (name: string) -> Color {
    if len(name) > 0 && name[0] == '#' {
        return core.color_from_hex(name)
    } else {
        fmt.assertf(name in colors, "Unknown color: \"%s\"", name)
        return colors[name]
    }
}

@private
set :: #force_inline proc (name: string, color: Color) {
    name := name
    if name not_in colors do name = strings.clone(name)
    colors[name] = color
}

@private
add_color :: proc (name: string, color: Color, with_variations := false) -> Color {
    assert(name != "")
    assert(name not_in colors)

    set(name, color)

    if with_variations {
        // alpha:
        // - generate colors from "color_a1" to "color_a9"
        // - we don't gen "color_a0" (always fully transparent), and "color_a10" (the same as just "color")
        for i in 1..=9 {
            n := fmt.tprintf("%s_a%i", name, i)
            set(n, core.alpha(colors[name], f32(i)/10))
        }

        // brightness:
        // - generate colors from "color_d9" (-9) to "color_l9" (+9)
        // - we don't gen "color_d0" or "color_l0", that is same as just "color"
        // - we also don't gen "color_d10" (always black), and "color_l10" (always white)
        for i in -9..=9 {
            if i == 0 do continue
            n := fmt.tprintf("%s_%c%i", name, i<0?'d':'l', abs(i))
            set(n, core.brightness(colors[name], f32(i)/10))
        }
    }

    return color
}
