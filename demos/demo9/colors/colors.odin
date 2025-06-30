package demo9_colors

import "core:strings"
import "spacelib:core"

default := core.color_from_hex("#f00")
bg0     := core.color_from_hex("#000")
bg1     := core.color_from_hex("#223")
primary := core.color_from_hex("#fd9")
accent  := core.color_from_hex("#f9f")

get :: #force_inline proc (name: string) -> core.Color {
    if strings.has_prefix(name, "#") do return core.color_from_hex(name)
    switch name {
    case "bg0"      : return bg0
    case "bg1"      : return bg1
    case "primary"  : return primary
    case "accent"   : return accent
    case            : return default
    }
}
