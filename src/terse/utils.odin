package spacelib_terse

import "core:fmt"
import "core:slice"
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
}

text_escaped :: proc (text: string, allocator := context.allocator) -> (result: string, was_allocation: bool) {
    old := strings.builder_make(context.temp_allocator)
    fmt.sbprint(&old, default_code_start_rune)

    new := strings.builder_make(context.temp_allocator)
    fmt.sbprint(&new, default_escape_rune, default_code_start_rune, sep="")

    return strings.replace_all(text, strings.to_string(old), strings.to_string(new), allocator)
}

group_text :: proc (group: Group, allocator := context.allocator) -> string {
    if len(group.words) == 0 do return ""

    sb := strings.builder_make(allocator)
    for word, i in group.words {
        if !word.is_icon {
            fmt.sbprintf(&sb, "%s%s", i > 0 ? " " : "", word.text)
        }
    }

    return strings.to_string(sb)
}

group_rects :: proc (group: Group, allocator := context.allocator) -> [] Rect {
    result := make([dynamic] Rect, allocator=allocator)

    prev_line_idx := int(-1)
    for w in group.words {
        if w.line_idx != prev_line_idx  do append(&result, w.rect)
        else                            do core.rect_grow(slice.last_ptr(result[:]), w.rect)
        prev_line_idx = w.line_idx
    }

    return result[:]
}

group_hit :: proc (terse: ^Terse, pos: Vec2) -> ^Group {
    assert(terse != nil)
    for &g in terse.groups {
        for r in group_rects(g, context.temp_allocator) {
            if core.vec_in_rect(pos, r) do return &g
        }
    }
    return nil
}

size_of_terse :: proc (terse: ^Terse) -> (total: int) {
    if terse == nil do return

    total = size_of(Terse)
    total += size_of(Word) * len(terse.words)
    total += size_of(Line) * len(terse.lines)
    total += size_of(Group) * len(terse.groups)

    return
}

@private
builder_line_words :: #force_inline proc (builder: Builder, line: Line) -> [] Word {
    if line._word_count > 0 {
        low := line._word_start_idx
        high := line._word_start_idx + line._word_count
        return builder.words_arr[low:high]
    } else {
        return nil
    }
}

@private
builder_group_words :: #force_inline proc (builder: Builder, group: Group) -> [] Word {
    if group._word_count > 0 {
        low := group._word_start_idx
        high := group._word_start_idx + group._word_count
        return builder.words_arr[low:high]
    } else {
        return nil
    }
}

@private
parse_icon_args :: proc (text: string) -> (name: string, scale: Vec2) {
    name = text
    scale = {1,1}

    pair_sep_idx := strings.index_rune(text, default_args_separator_rune)
    if pair_sep_idx >= 0 && pair_sep_idx <= len(text)-2 {
        name = text[0:pair_sep_idx]
        scale = parse_vec(text[pair_sep_idx+1:])
    }

    return
}

@private
parse_vec :: proc (text: string) -> Vec2 {
    pair_sep_idx := strings.index_rune(text, default_args_separator_rune)
    if pair_sep_idx >= 0 && pair_sep_idx <= len(text)-2 {
        return { parse_f32(text[0:pair_sep_idx]), parse_f32(text[pair_sep_idx+1:]) }
    } else {
        return parse_f32(text)
    }
}

@private
parse_vec_int :: proc (text: string) -> Vec2 {
    pair_sep_idx := strings.index_rune(text, default_args_separator_rune)
    if pair_sep_idx >= 0 && pair_sep_idx <= len(text)-2 {
        return { f32(parse_int(text[0:pair_sep_idx])), f32(parse_int(text[pair_sep_idx+1:])) }
    } else {
        return f32(parse_int(text))
    }
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
