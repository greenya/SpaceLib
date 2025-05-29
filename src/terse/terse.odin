package spacelib_terse

import "core:fmt"
import "core:slice"
import "core:strings"
import "../core"

@private Vec2 :: core.Vec2
@private Rect :: core.Rect
@private Color :: core.Color

Terse :: struct {
    rect        : Rect,
    rect_input  : Rect,
    wrap        : bool,
    valign      : Vertical_Alignment,
    words       : [dynamic] Word,
    lines       : [dynamic] Line,
    groups      : [dynamic] Group,
}

Line :: struct {
    rect            : Rect,
    align           : Horizontal_Alignment,
    gap             : f32,
    word_start_idx  : int,
    word_count      : int,
}

Word :: struct {
    rect        : Rect,
    text        : string,
    font        : ^Font,
    color       : Color,
    is_icon     : bool,
    in_group    : bool,
    line_idx    : int,
}

Group :: struct {
    name            : string,
    word_start_idx  : int,
    word_count      : int,
    rects           : [dynamic] Rect,
}

Font :: struct {
    font_ptr        : rawptr,
    height          : f32,
    rune_spacing    : f32,
    line_spacing    : f32,
    measure_text    : Measure_Text_Proc,
}

Horizontal_Alignment    :: enum { left, center, right }
Vertical_Alignment      :: enum { top, middle, bottom }

Measure_Text_Proc   :: proc (font: ^Font, text: string) -> Vec2
Query_Font_Proc     :: proc (name: string) -> ^Font
Query_Color_Proc    :: proc (name: string) -> Color

@private default_code_start_rune    :: '<'
@private default_code_end_rune      :: '>'
@private default_fonts_stack_size   :: 8
@private default_colors_stack_size  :: 8
@private default_valign             :: Vertical_Alignment.middle
@private default_align              :: Horizontal_Alignment.center
         default_font_name          :: "default"
         default_color_name         :: "default"

create :: proc (
    text                : string,
    rect                : Rect,
    query_font          : Query_Font_Proc,
    query_color         : Query_Color_Proc,
    allocator           := context.allocator,
    debug_keep_codes    := false,
) -> ^Terse {
    ensure(query_font != nil)
    ensure(query_color != nil)

    terse := new(Terse, allocator)
    terse.rect = rect
    terse.rect_input = rect
    terse.valign = default_valign
    terse.words.allocator = allocator
    terse.lines.allocator = allocator
    terse.groups.allocator = allocator

    if text == "" do return terse

    font := query_font(default_font_name)
    ensure(font.measure_text != nil)
    fonts_stack := [default_fonts_stack_size] ^Font {}
    fonts_stack[0] = font
    fonts_stack_idx := 0

    color := query_color(default_color_name)
    colors_stack := [default_colors_stack_size] Color {}
    colors_stack[0] = color
    colors_stack_idx := 0

    group: ^Group

    cursor: struct { type: enum { text, code }, start: int }
    code, word: string
    word_is_icon: bool
    word_icon_scale: Vec2

    for para in strings.split(text, "\n", context.temp_allocator) {
        line := append_line(terse, font)

        cursor = { type=.text, start=0 }
        for i:=0; i<len(para); i+=1 {
            if para[i] == default_code_start_rune && cursor.type == .text {
                word = para[cursor.start:i]
                cursor = { start=i+1, type=.code }
            }

            if para[i] == default_code_end_rune && cursor.type == .code {
                code = para[cursor.start:i]
                cursor = { start=i+1, type=.text }
            }

            if (para[i] == ' ' || i == len(para)-1) && cursor.type == .text {
                word = para[cursor.start:i+1]
                cursor = { start=i+1, type=.text }
            }

            if code != "" {
                for command in strings.split(code, ",", context.temp_allocator) do switch command {
                case "left"     : line.align = .left
                case "center"   : line.align = .center
                case "right"    : line.align = .right
                case "wrap"     : terse.wrap = true
                case "top"      : terse.valign = .top
                case "middle"   : terse.valign = .middle
                case "bottom"   : terse.valign = .bottom
                case "/font":
                    fonts_stack_idx -= 1
                    ensure(fonts_stack_idx >= 0, "Fonts stack underflow!")
                    font = fonts_stack[fonts_stack_idx]
                case "/color":
                    colors_stack_idx -= 1
                    ensure(colors_stack_idx >= 0, "Colors stack underflow!")
                    color = colors_stack[colors_stack_idx]
                case "/group":
                    ensure(group != nil, "No group to close!")
                    group = nil
                case:
                    pair_sep_idx := strings.index(command, "=")
                    if pair_sep_idx >= 0 && pair_sep_idx <= len(command)-2 {
                        command_name := command[0:pair_sep_idx]
                        command_value := command[pair_sep_idx+1:]
                        switch command_name {
                        case "font":
                            font = query_font(command_value)
                            ensure(font.measure_text != nil)
                            fonts_stack_idx += 1
                            ensure(fonts_stack_idx < len(fonts_stack), "Fonts stack overflow!")
                            fonts_stack[fonts_stack_idx] = font
                            line.rect.h = line.word_count > 0 ? max(line.rect.h, font.height) : font.height
                        case "color":
                            color = command_value[0] == '#' ? core.color_from_hex(command_value) : query_color(command_value)
                            colors_stack_idx += 1
                            ensure(colors_stack_idx < len(colors_stack), "Colors stack overflow!")
                            colors_stack[colors_stack_idx] = color
                        case "icon":
                            assert(word == "")
                            word, word_icon_scale = parse_icon_args(command_value)
                            word_is_icon = true
                        case "group":
                            ensure(group == nil, "Groups cannot be nested!")
                            group = append_group(terse, command_value)
                        case "gap":
                            gap_ratio := parse_f32(command_value)
                            line.gap = gap_ratio * font.height
                        case:
                            fmt.eprintfln("[!] Unexpected command pair \"%v\"", command)
                        }
                    } else {
                        fmt.eprintfln("[!] Unexpected command \"%v\"", command)
                    }
                }

                if debug_keep_codes {
                    b := strings.builder_make(context.temp_allocator)
                    word = fmt.sbprintf(&b, "{{%s}}", code)
                }

                code = ""
            }

            if word != "" {
                size := word_is_icon\
                    ? word_icon_scale * Vec2 { font.height, font.height }\
                    : font->measure_text(word)

                if terse.wrap && line.rect.w + size.x > rect.w && line.word_count > 0 {
                    line = append_line(terse, font)
                }

                append_word(terse, word, size, font, color, word_is_icon, group)

                word = ""
                word_is_icon = false
                word_icon_scale = 0
            }
        }
    }

    apply_last_line_gap(terse)

    last_line := slice.last_ptr(terse.lines[:])
    assert(last_line != nil)

    // apply vertical alignment
    vertical_empty_space := rect.y + rect.h - (last_line.rect.y + last_line.rect.h)
    if vertical_empty_space > 0 {
        offset_rect_y := f32(-1)

        switch terse.valign {
        case .top: // already aligned
        case .middle: offset_rect_y = vertical_empty_space/2
        case .bottom: offset_rect_y = vertical_empty_space
        }

        if offset_rect_y > 0 {
            for &line in terse.lines {
                line.rect.y += offset_rect_y
                for i in 0..<line.word_count {
                    word := &terse.words[line.word_start_idx + i]
                    word.rect.y += offset_rect_y
                }
            }
        }
    }

    for &line in terse.lines {
        // apply horizontal alignment
        switch line.align {
        case .left: // already aligned
        case .center, .right:
            offset_rect_x := (rect.w - line.rect.w) / (line.align == .center ? 2 : 1)
            line.rect.x += offset_rect_x
            for i in 0..<line.word_count {
                word := &terse.words[line.word_start_idx + i]
                word.rect.x += offset_rect_x
            }
        }

        // vertically center words in a line in case they have different heights
        line_height := line.rect.h
        for i in 0..<line.word_count {
            word := &terse.words[line.word_start_idx + i]
            space := (line_height - word.rect.h)/2
            word.rect.y += space
        }
    }

    // generate rects for terse.groups
    for &group in terse.groups {
        prev_line_idx := int(-1)
        for i in 0..<group.word_count {
            word := &terse.words[group.word_start_idx + i]
            if word.line_idx != prev_line_idx {
                append(&group.rects, word.rect)
            } else {
                core.rect_add_rect(slice.last_ptr(group.rects[:]), word.rect)
            }
            prev_line_idx = word.line_idx
        }
    }

    // calculate terse.rect
    first_line := slice.first_ptr(terse.lines[:])
    if first_line != nil {
        terse.rect = first_line.rect
        for line in terse.lines[1:] {
            core.rect_add_rect(&terse.rect, line.rect)
        }
    }

    return terse
}

destroy :: proc (terse: ^Terse) {
    if terse == nil do return

    for group in terse.groups do delete(group.rects)
    delete(terse.groups)
    delete(terse.lines)
    delete(terse.words)

    free(terse)
}

@private
append_line :: proc (terse: ^Terse, font: ^Font) -> ^Line {
    line_rect_y := terse.rect.y
    line_align := default_align

    prev_line := slice.last_ptr(terse.lines[:])
    if prev_line != nil {
        apply_last_line_gap(terse)

        line_rect_y = prev_line.rect.y + prev_line.rect.h + font.line_spacing
        line_align = prev_line.align

        // re-measure last word of last line in case it ends with space
        last_word := slice.last_ptr(terse.words[:])
        if last_word != nil && strings.ends_with(last_word.text, " ") {
            last_word.text = last_word.text[:len(last_word.text)-1]
            size := font->measure_text(last_word.text)
            prev_line.rect.w -= last_word.rect.w - size.x
            last_word.rect.w = size.x
        }
    }

    line := Line {
        rect    = { terse.rect.x, line_rect_y, 0, font.height },
        align   = line_align,
    }

    append(&terse.lines, line)
    return slice.last_ptr(terse.lines[:])
}

@private
apply_last_line_gap :: proc (terse: ^Terse) {
    if len(terse.lines) < 2 do return // do not apply gap if no lines OR there is only one line

    line := slice.last_ptr(terse.lines[:])
    if line.gap == 0 do return

    line.rect.y += line.gap
    for i in 0..<line.word_count {
        word := &terse.words[line.word_start_idx + i]
        word.rect.y += line.gap
    }
}

@private
append_group :: proc (terse: ^Terse, name: string) -> ^Group {
    group := Group { name=name }
    group.rects.allocator = terse.groups.allocator
    append(&terse.groups, group)
    return slice.last_ptr(terse.groups[:])
}

@private
append_word :: proc (
    terse   : ^Terse,
    text    : string,
    size    : Vec2,
    font    : ^Font,
    color   : Color,
    is_icon : bool,
    group   : ^Group,
) {
    line := slice.last_ptr(terse.lines[:])
    assert(line != nil)

    word := Word {
        rect        = { line.rect.x+line.rect.w, line.rect.y, size.x, size.y },
        text        = text,
        font        = font,
        color       = color,
        is_icon     = is_icon,
        in_group    = group != nil,
        // idx         = len(terse.words), // len value as we are about to add this word now
        line_idx    = len(terse.lines) - 1,
    }

    append(&terse.words, word)
    line.word_count += 1
    if line.word_count == 1 do line.word_start_idx = len(terse.words)-1 // word.idx

    line.rect.w += size.x
    line.rect.h = max(line.rect.h, size.y)

    if group != nil {
        group.word_count += 1
        if group.word_count == 1 do group.word_start_idx = len(terse.words)-1 // word.idx
    }
}

@private
parse_icon_args :: proc (text: string) -> (name: string, scale: Vec2) {
    name = text
    scale = {1,1}

    pair_sep_idx := strings.index(text, ":")
    if pair_sep_idx >= 0 && pair_sep_idx <= len(text)-2 {
        name = text[0:pair_sep_idx]
        scale = parse_vec(text[pair_sep_idx+1:])
    }

    return
}

@private
parse_vec :: proc (text: string) -> Vec2 {
    pair_sep_idx := strings.index(text, ":")
    if pair_sep_idx >= 0 && pair_sep_idx <= len(text)-2 {
        return { parse_f32(text[0:pair_sep_idx]), parse_f32(text[pair_sep_idx+1:]) }
    } else {
        return parse_f32(text)
    }
}

// this should be enough and quick, but maybe rework it so it would parse normally, e.g.
// any floating point value; but check the performance, maybe general parsing is slow (?)
@private
parse_f32 :: proc (text: string) -> f32 {
    digit_before_dot, digit_after_dot: f32

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

    return digit_before_dot + digit_after_dot/10
}
