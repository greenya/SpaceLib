package spacelib_terse

import "core:fmt"
import "core:strings"
import "../core"

@private Vec2 :: core.Vec2
@private Rect :: core.Rect
@private Color :: core.Color

apply_offset :: proc (terse: ^Terse, offset: Vec2) {
    assert(terse != nil)

    terse.rect_input.x += offset.x
    terse.rect_input.y += offset.y

    terse.rect.x += offset.x
    terse.rect.y += offset.y

    for &word in terse.words {
        word.rect.x += offset.x
        word.rect.y += offset.y
    }

    for &line in terse.lines {
        line.rect.x += offset.x
        line.rect.y += offset.y
    }

    for &group in terse.groups do for &rect in group.rects {
        rect.x += offset.x
        rect.y += offset.y
    }
}

text_of_group :: proc (terse: ^Terse, group_idx: int, allocator := context.allocator) -> string {
    assert(terse != nil)
    assert(group_idx >= 0 && group_idx < len(terse.groups))

    group := terse.groups[group_idx]
    if group.word_count == 0 do return ""

    sb := strings.builder_make(allocator)
    for i in 0..<group.word_count {
        word := &terse.words[i + group.word_start_idx]
        if !word.is_icon {
            fmt.sbprintf(&sb, "%s%s", i > 0 ? " " : "", word.text)
        }
    }

    return strings.to_string(sb)
}

size_of_terse :: proc (terse: ^Terse) -> (total: int) {
    if terse == nil do return

    total = size_of(Terse)

    for word in terse.words {
        total += size_of(word)
    }

    for line in terse.lines {
        total += size_of(line)
    }

    for group in terse.groups {
        total += size_of(group)
        for rect in group.rects {
            total += size_of(rect)
        }
    }

    return
}

// parses very very simple float value, from -9.9 to 9.9 only
// supports absence of optional parts like: X[.0], [0].X
// note: this should be enough and quick, but maybe rework it so it would parse normally,
// e.g. any valid floating point value; check the performance, maybe general parsing is slow (?)
@private
parse_f32 :: proc (text: string) -> f32 {
    digit_before_dot, digit_after_dot: f32

    text := text
    sign := f32(1)
    if text[0] == '-' {
        sign = -1
        text = text[1:]
    }

    if len(text) == 2 && text[0] == '.' {
        // format: ".0", ".1" ... ".9"
        digit_after_dot = f32(text[1]-'0')
    } else if len(text) == 3 && text[1] == '.' {
        // format: "0.0", "0.1", ... "9.9"
        digit_before_dot = f32(text[0]-'0')
        digit_after_dot = f32(text[2]-'0')
    } else if len(text) == 1 {
        // format: "0", "1", ... "9"
        digit_before_dot = f32(text[0]-'0')
    } else {
        fmt.eprintfln("[!] Failed to parse f32 value in \"%v\"", text)
    }

    return sign * (digit_before_dot + digit_after_dot/10)
}

@private
parse_int :: proc (text: string) -> int {
    text := text
    sign := 1
    if text[0] == '-' {
        sign = -1
        text = text[1:]
    }

    m := 1
    result := 0
    #reverse for c in text {
        result += m * int(c-'0')
        m *= 10
    }

    return sign * result
}
