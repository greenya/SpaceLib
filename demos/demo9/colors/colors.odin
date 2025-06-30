package demo9_colors

import "spacelib:core"

bg0     := core.color_from_hex("#000")
bg1     := core.color_from_hex("#223")
primary := core.color_from_hex("#fd9")
accent  := core.color_from_hex("#f9f")

get :: #force_inline proc (name: string) -> core.Color {
    switch name {
    case "bg0"      : return bg0
    case "bg1"      : return bg1
    case "primary"  : return primary
    case "accent"   : return accent
    case            : return core.color_from_hex(name)
    }
}
