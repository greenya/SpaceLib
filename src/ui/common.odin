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

    if f.name != ""             do fmt.sbprintf(&sb, " name=\"%s\"", f.name)
    else if f.text != ""        do fmt.sbprintf(&sb, " text=\"%s\"", f.text)
    if .solid in f.flags        do fmt.sbprint (&sb, " solid=true")
    if .scissor in f.flags      do fmt.sbprint (&sb, " scissor=true")
    if f.layout.dir != .none    do fmt.sbprintf(&sb, " layout.dir=%v", f.layout.dir)

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
