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
    if f.name != ""             do fmt.sbprintf(&sb, " <%s>", f.name)
    if f.order != 0             do fmt.sbprintf(&sb, " order=%i", f.order)
    if f.layout.dir != .none    do fmt.sbprintf(&sb, " layout")

    skip_flags :: bit_set [Flag] { .terse_height, .terse_width, .terse_hit_rect }
    for v in Flag do if v in f.flags && v not_in skip_flags do fmt.sbprintf(&sb, " %v", v)

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
