package spacelib_ui

import "core:fmt"
import "core:strings"
import "../core"

@private Vec2 :: core.Vec2
@private Rect :: core.Rect

print_frame_tree :: proc (f: ^Frame, depth_max := 20, _depth := 0) {
    if _depth == 0 do fmt.println("-------- Frame tree --------")

    sb := strings.builder_make(context.temp_allocator)
    for i in 0..=_depth do strings.write_string(&sb, i == 0 ? "+" : "-")
    strings.write_rune(&sb, '{')

    if f.parent == nil          do fmt.sbprintf(&sb, " root")

    if f.name != ""             do fmt.sbprintf(&sb, " name=\"%s\"", f.name)
    else if f.text != ""        do fmt.sbprintf(&sb, " text=\"%s\"", f.text)

    if f.order != 0             do fmt.sbprintf(&sb, " order=%i", f.order)

    if .hidden in f.flags       do fmt.sbprintf(&sb, " hidden")
    if .disabled in f.flags     do fmt.sbprintf(&sb, " disabled")
    if .pass in f.flags         do fmt.sbprintf(&sb, " pass")
    if .solid in f.flags        do fmt.sbprint (&sb, " solid")
    if .scissor in f.flags      do fmt.sbprint (&sb, " scissor")
    if .check in f.flags        do fmt.sbprint (&sb, " check")
    if .radio in f.flags        do fmt.sbprint (&sb, " radio")
    if .auto_hide in f.flags    do fmt.sbprint (&sb, " auto_hide")
    if .terse in f.flags        do fmt.sbprint (&sb, " terse")

    if f.layout.dir != .none    do fmt.sbprintf(&sb, " layout")

    if sb.buf[len(sb.buf)-1] != '{' do strings.write_rune(&sb, ' ')
    strings.write_rune(&sb, '}')

    if _depth == depth_max && len(f.children) > 0 {
        fmt.sbprintf(&sb, " // children=%d", len(f.children))
    }

    fmt.println(strings.to_string(sb))

    if _depth < depth_max {
        for child in f.children do print_frame_tree(child, depth_max, _depth + 1)
    }

    if _depth == 0 do fmt.println("----------------------------")
}
