package hi

import "core:fmt"
import "core:strings"

print_view_tree :: proc (v: ^View, _depth := 0) {
    print_view(v, _depth)
    for c := v.first_child; c != nil; c = c.next_sibling {
        print_view_tree(c, _depth + 1)
    }
}

print_view :: proc (v: ^View, _depth := 0) {
    buf: [200] byte
    sb := strings.builder_from_bytes(buf[:])

    for _ in 0..<_depth do strings.write_string(&sb, "\t")

    fmt.sbprintf(&sb, "#%d [%d]", v.sid, v.idx)

    if v.name != "" do fmt.sbprintf(&sb, " \"%s\"", v.name)

    {
        r := &v.solved_rect
        fmt.sbprintf(&sb, " <%v,%v:%vx%v|%f>", r.x, r.y, r.w, r.h, v.solved_opacity)
    }

    for f in Flag do if f in v.flags do fmt.sbprintf(&sb, " .%v", f)

    if v.size != {} do fmt.sbprintf(&sb, " size={{%v,%v}}", v.size.x, v.size.y)

    if v.place != {} {
        p := &v.place
        fmt.sbprint(&sb, " place={")
        if p.anchor == p.pivot {
            if p.anchor.x == p.anchor.y do fmt.sbprintf(&sb, "%v", p.anchor.x)
            else                        do fmt.sbprintf(&sb, "{{%v,%v}}", p.anchor.x, p.anchor.y)
        } else {
            if p.anchor.x == p.anchor.y do fmt.sbprintf(&sb, "anchor=%v", p.anchor.x)
            else                        do fmt.sbprintf(&sb, "anchor={{%v,%v}}", p.anchor.x, p.anchor.y)
            if p.pivot.x == p.pivot.y   do fmt.sbprintf(&sb, ",pivot=%v", p.pivot.x)
            else                        do fmt.sbprintf(&sb, ",pivot={{%v,%v}}", p.pivot.x, p.pivot.y)
        }
        if p.offset != {} {
            if p.offset.x == p.offset.y do fmt.sbprintf(&sb, ",offset=%v", p.offset.x)
            else                        do fmt.sbprintf(&sb, ",offset={{%v,%v}}", p.offset.x, p.offset.y)
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

    if v.scroll != {} {
        s := &v.scroll
        if s.x == s.y   do fmt.sbprintf(&sb, " scroll=%v", s.x)
        else            do fmt.sbprintf(&sb, " scroll={{%v,%v}}", s.x, s.y)
    }

    if v.layout.dir != .none {
        fmt.sbprint(&sb, " layout={")
        fmt.sbprintf(&sb, "%v-%v-%v", v.layout.dir, v.layout.justify, v.layout.align)
        if v.layout.gap != 0 do fmt.sbprintf(&sb, ",gap=%v", v.layout.gap)
        fmt.sbprint(&sb, "}")
    }

    fmt.println(strings.to_string(sb))
}
