package spacelib_ui

import "core:fmt"
import "core:strings"
import "../core"

@private Vec2 :: core.Vec2
@private Rect :: core.Rect

print_frame_tree :: proc (
    f           : ^Frame,
    skip_flags  := bit_set [Flag] { .terse_size, .terse_height, .terse_width, .terse_hit_rect },
    max_depth   := 20,
    _depth      := 0,
) {
    if _depth == 0 do fmt.println("-------- Frame tree --------")

    sb := strings.builder_make(context.temp_allocator)
    for i in 0..=_depth do strings.write_string(&sb, i == 0 ? "+" : "-")
    strings.write_rune(&sb, '{')

    if f.parent == nil          do fmt.sbprint(&sb, " root")
    if f.order != 0             do fmt.sbprintf(&sb, " %+i", f.order)
    if f.name != ""             do fmt.sbprintf(&sb, " <%s>", f.name)
    if f.entered                do fmt.sbprint(&sb, " entered")
    if f.captured               do fmt.sbprint(&sb, " captured")
    if f.selected               do fmt.sbprint(&sb, " selected")

    switch l in f.layout {
    case Flow: fmt.sbprintf(&sb, " flow")
    case Grid: fmt.sbprintf(&sb, " grid")
    }

    for v in Flag do if v in f.flags && v not_in skip_flags do fmt.sbprintf(&sb, " %v", v)

    if sb.buf[len(sb.buf)-1] != '{' do strings.write_rune(&sb, ' ')
    strings.write_rune(&sb, '}')

    if _depth == max_depth && len(f.children) == 1  do fmt.sbprint(&sb, " // 1 child")
    if _depth == max_depth && len(f.children) > 1   do fmt.sbprintf(&sb, " // %d children", len(f.children))

    fmt.println(strings.to_string(sb))

    if _depth < max_depth {
        for child in f.children do print_frame_tree(child, skip_flags, max_depth, _depth+1)
    }

    if _depth == 0 do fmt.println("----------------------------")
}
