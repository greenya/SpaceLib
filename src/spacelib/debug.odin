package spacelib

import "core:fmt"
import "core:strings"

print_frame_tree :: proc (f: ^Frame, depth_max := 20, depth := 0) {
    if depth == 0 do fmt.println("-------- Frame tree --------")

    sb := strings.builder_make(context.temp_allocator)
    for i in 0..=depth do strings.write_string(&sb, i == 0 ? "+" : "-")
    strings.write_rune(&sb, '{')

    if f.text != "" do fmt.sbprintf(&sb, " text=\"%s\"", f.text)
    if f.modal do fmt.sbprint(&sb, " modal=true")
    if f.scissor do fmt.sbprint(&sb, " scissor=true")
    if f.layout.dir != .none do fmt.sbprintf(&sb, " layout.dir=%v", f.layout.dir)

    if sb.buf[len(sb.buf)-1] != '{' do strings.write_rune(&sb, ' ')
    strings.write_rune(&sb, '}')

    if depth == depth_max && len(f.children) > 0 {
        fmt.sbprintf(&sb, " // children=%d", len(f.children))
    }

    fmt.println(strings.to_string(sb))

    if depth < depth_max {
        for child in f.children do print_frame_tree(child, depth_max, depth + 1)
    }

    if depth == 0 do fmt.println("----------------------------")
}
