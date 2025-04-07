package spacelib

import "core:fmt"
import "core:strings"

print_frame_tree :: proc (f: ^Frame, depth := 0) {
    ensure(depth < 100, "Tree depth limit exceeded!")

    sb := strings.builder_make()

    for i in 0..=depth do strings.write_string(&sb, i == 0 ? "+" : "-")
    strings.write_rune(&sb, '{')

    if f.text != "" do fmt.sbprintf(&sb, " text=\"%s\"", f.text)
    if f.scissor do fmt.sbprint(&sb, " scissor=true")
    if f.layout.dir != .none do fmt.sbprintf(&sb, " layout.dir=%v", f.layout.dir)

    if sb.buf[len(sb.buf)-1] != '{' do strings.write_rune(&sb, ' ')
    strings.write_rune(&sb, '}')
    fmt.println(strings.to_string(sb))

    for child in f.children do print_frame_tree(child, depth + 1)
}
