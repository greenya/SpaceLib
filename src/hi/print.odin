package hi

import "core:fmt"
import "core:strings"

print_tree :: proc (ctx: Context, id := ID(0), _depth := 0) {
    print_view(ctx, id, _depth)
    for child_id := ctx.views[id].first_child; child_id > 0; /**/ {
        print_tree(ctx, child_id, _depth + 1)
        child_id = ctx.views[child_id].next_sibling
    }
}

print_view :: proc (ctx: Context, id: ID, _depth := 0) {
    v := &ctx.views[id]
    buf: [200] byte
    sb := strings.builder_from_bytes(buf[:])

    for _ in 0..<_depth do strings.write_string(&sb, "\t")

    fmt.sbprintf(&sb, "#%d \"%s\"", id, v.name)

    if v.computed != {} {
        c := &v.computed
        fmt.sbprintf(&sb, " <%v,%v:%vx%v>", c.pos.x, c.pos.y, c.size.x, c.size.y)
    }

    for f in Flag do if f in v.flags do fmt.sbprintf(&sb, " .%v", f)

    if v.size != {} do fmt.sbprintf(&sb, " size={{%v,%v}}", v.size.x, v.size.y)

    if v.placement != {} {
        p := &v.placement
        fmt.sbprint(&sb, " placement={")
        if p.anchor == p.pivot {
            if p.anchor.x == p.anchor.y do fmt.sbprintf(&sb, "%v", p.anchor.x)
            else                        do fmt.sbprintf(&sb, "{{%v,%v}}", p.anchor.x, p.anchor.y)
        } else {
            if p.anchor.x == p.anchor.y do fmt.sbprintf(&sb, "a=%v", p.anchor.x)
            else                        do fmt.sbprintf(&sb, "a={{%v,%v}}", p.anchor.x, p.anchor.y)
            if p.pivot.x == p.pivot.y   do fmt.sbprintf(&sb, ",p=%v", p.pivot.x)
            else                        do fmt.sbprintf(&sb, ",p={{%v,%v}}", p.pivot.x, p.pivot.y)
        }
        if p.offset != {} {
            if p.offset.x == p.offset.y do fmt.sbprintf(&sb, ",o=%v", p.offset.x)
            else                        do fmt.sbprintf(&sb, ",o={{%v,%v}}", p.offset.x, p.offset.y)
        }
        fmt.sbprint(&sb, "}")
    }

    if v.padding != {} {
        l, t, r, b := v.padding[0], v.padding[1], v.padding[2], v.padding[3]
        switch {
        case l == r && l == t && l == r && l == b:
            fmt.sbprintf(&sb, " padding=%v", l)
        case l == r && t == b:
            fmt.sbprintf(&sb, " padding={{%v,%v}}", l, t)
        case:
            fmt.sbprintf(&sb, " padding={{%v,%v,%v,%v}}", l, t, r, b)
        }
    }

    if v.layout.dir != .none {
        fmt.sbprint(&sb, " layout={")
        fmt.sbprintf(&sb, "%v-%v-%v", v.layout.dir, v.layout.justify, v.layout.align)
        if v.layout.gap != 0 do fmt.sbprintf(&sb, ",gap=%v", v.layout.gap)
        fmt.sbprint(&sb, "}")
    }

    fmt.println(strings.to_string(sb))
}
