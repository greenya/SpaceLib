package spacelib_terse

import "core:fmt"
import "core:slice"
import "core:strings"
import "../core"
import "../core/stack"

Terse :: struct {
    rect        : Rect,
    rect_input  : Rect,
    scissor     : Rect,
    pad         : Vec2,
    wrap        : bool,
    opacity     : f32,
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

default_escape_rune         :: '\\'
default_code_start_rune     :: '<'
default_code_end_rune       :: '>'
default_command_separator   :: ","
default_args_separator_rune :: ':'
default_fonts_stack_size    :: 16
default_colors_stack_size   :: 16
default_valign              :: Vertical_Alignment.middle
default_align               :: Horizontal_Alignment.center
default_font_name           :: "default"
default_color_name          :: "default"

create :: proc (
    text        : string,
    rect        : Rect,
    query_font  : Query_Font_Proc,
    query_color : Query_Color_Proc,
    scissor     := Rect {},
    opacity     := f32(1),
    allocator   := context.allocator,
) -> ^Terse {
    ensure(query_font != nil)
    ensure(query_color != nil)

    terse := new(Terse, allocator)
    terse.rect = rect
    terse.rect_input = rect
    terse.scissor = scissor
    terse.opacity = opacity
    terse.valign = default_valign
    terse.words.allocator = allocator
    terse.lines.allocator = allocator
    terse.groups.allocator = allocator

    if text == "" {
        terse.rect.w = 0
        terse.rect.h = 0
        return terse
    }

    alpha := f32(1)
    brightness := f32(0)

    fonts_stack: stack.Stack(^Font, default_fonts_stack_size)
    stack.push(&fonts_stack, query_font(default_font_name))
    ensure(stack.top(fonts_stack).measure_text != nil, "Font.measure_text must be set")

    colors_stack: stack.Stack(Color, default_colors_stack_size)
    stack.push(&colors_stack, query_color(default_color_name))

    group: ^Group

    nobreak: struct { active: bool, last_breakable_word_idx: int }

    last_opened_command: enum { none, font, color, group, nobreak }

    cursor: struct { type: enum { text, escape, code }, start: int }
    code, word      : string
    word_is_icon    : bool
    word_icon_scale : Vec2
    word_is_tab     : bool
    word_tab_width  : f32

    for para in strings.split(text, "\n", context.temp_allocator) {
        line := append_line(terse, stack.top(fonts_stack))

        cursor = { .text, 0 }
        for i:=0; i<len(para); i+=1 {
            switch cursor.type {
            case .text:
                switch {
                case para[i] == ' ':
                    word = para[cursor.start:i+1]
                    cursor = { .text, i+1 }
                case para[i] == default_code_start_rune:
                    word = para[cursor.start:i]
                    cursor = { .code, i+1 }
                case para[i] == default_escape_rune:
                    word = para[cursor.start:i]
                    cursor = { .escape, -1 }
                }
            case .escape:
                cursor = { .text, i }
            case .code:
                if para[i] == default_code_end_rune {
                    code = para[cursor.start:i]
                    cursor = { start=i+1, type=.text }
                }
            }

            if i == len(para)-1 && cursor.type == .text && word == "" {
                word = para[cursor.start:i+1]
            }

            if code != "" {
                for &command in strings.split(code, default_command_separator, context.temp_allocator) {
                    if command == "/" do switch last_opened_command {
                    case .none      : panic("Unexpected command \"/\", no command opened previously")
                    case .font      : command = "/font"
                    case .color     : command = "/color"
                    case .group     : command = "/group"
                    case .nobreak   : command = "/nobreak"
                    }

                    switch command {
                    case "left"     : line.align = .left
                    case "center"   : line.align = .center
                    case "right"    : line.align = .right
                    case "wrap"     : terse.wrap = true
                    case "top"      : terse.valign = .top
                    case "middle"   : terse.valign = .middle
                    case "bottom"   : terse.valign = .bottom

                    case "/font":
                        ensure(!stack.is_empty(fonts_stack), "Fonts stack underflow")
                        stack.drop(&fonts_stack)
                        last_opened_command = .none

                    case "/color":
                        ensure(!stack.is_empty(colors_stack), "Colors stack underflow")
                        stack.drop(&colors_stack)
                        last_opened_command = .none

                    case "/group":
                        ensure(group != nil, "No group to close")
                        group = nil
                        last_opened_command = .none

                    case "nobreak":
                        ensure(!nobreak.active, "\"nobreak\" commands cannot be nested")
                        nobreak = { true, len(terse.words)-1 }
                        last_opened_command = .nobreak

                    case "/nobreak":
                        ensure(nobreak.active, "No \"nobreak\" to close")
                        nobreak = {}
                        last_opened_command = .none

                    case:
                        pair_sep_idx := strings.index(command, "=")
                        if pair_sep_idx >= 0 && pair_sep_idx <= len(command)-2 {
                            command_name := command[0:pair_sep_idx]
                            command_value := command[pair_sep_idx+1:]
                            switch command_name {
                            case "alpha":
                                alpha = parse_f32(command_value)

                            case "brightness":
                                brightness = parse_f32(command_value)

                            case "font":
                                ensure(!stack.is_full(fonts_stack), "Fonts stack overflow")
                                font := query_font(command_value)
                                ensure(font.measure_text != nil, "Font.measure_text must be set")
                                stack.push(&fonts_stack, font)
                                line.rect.h = line.word_count > 0 ? max(line.rect.h, font.height) : font.height
                                last_opened_command = .font

                            case "color":
                                ensure(!stack.is_full(colors_stack), "Colors stack overflow")
                                color := command_value[0] == '#' ? core.color_from_hex(command_value) : query_color(command_value)
                                stack.push(&colors_stack, color)
                                last_opened_command = .color

                            case "group":
                                ensure(group == nil, "Groups cannot be nested")
                                group = append_group(terse, command_value)
                                last_opened_command = .group

                            case "icon":
                                assert(word == "")
                                word, word_icon_scale = parse_icon_args(command_value)
                                word_is_icon = true

                            case "tab":
                                word_tab_width = f32(parse_int(command_value)) // todo: use parse_f32() when it can parse any float
                                if line.word_count > 0 {
                                    last_word := &terse.words[line.word_start_idx + line.word_count - 1]
                                    last_word_x2_local := last_word.rect.x + last_word.rect.w - line.rect.x
                                    word_tab_width -= last_word_x2_local
                                }
                                if word_tab_width != 0 do word_is_tab = true

                            case "gap":
                                gap_ratio := parse_f32(command_value)
                                line.gap = gap_ratio * stack.top(fonts_stack).height

                            case "pad":
                                ensure(len(terse.words) == 0 && len(terse.lines) == 1, "Can apply pad only on 1st line with no words measured")
                                terse.pad = parse_vec_int(command_value)
                                terse.lines[0].rect = core.rect_moved(terse.lines[0].rect, terse.pad)
                                terse.rect = core.rect_inflated(terse.rect, -terse.pad)

                            case:
                                fmt.panicf("Unknown command pair \"%v\"", command)
                            }
                        } else {
                            fmt.panicf("Unknown command \"%v\"", command)
                        }
                    }
                }

                code = ""
            }

            if word != "" || word_is_tab {
                font := stack.top(fonts_stack)
                size := word_is_icon\
                    ? word_icon_scale * Vec2 { font.height, font.height }\
                    : word_is_tab\
                        ? Vec2 { word_tab_width, font.height }\
                        : font->measure_text(word)

                line_break_needed := line.rect.w + size.x > terse.rect.w && line.word_count > 0
                if terse.wrap && line_break_needed {
                    line_break_allowed := true
                    nobreak_first_word_idx := -1

                    if nobreak.active {
                        if nobreak.last_breakable_word_idx != len(terse.words)-1 { // does list have words
                            first_word_idx := 1 + nobreak.last_breakable_word_idx
                            if first_word_idx == line.word_start_idx { // start of the line? -- skip append line
                                line_break_allowed = false
                            } else {
                                nobreak_first_word_idx = first_word_idx
                            }
                        }
                    }

                    if line_break_allowed {
                        continue_tab_width := last_line_continue_tab_width(terse)
                        line = append_line(terse, font, nobreak_first_word_idx)
                        if continue_tab_width > 0 {
                            append_word(terse, "", {continue_tab_width,size.y}, font, {}, false, group)
                        }
                    }
                }

                if word != " " || word_is_tab || line_has_printable_words(terse, line) { // skip " " at the start of the line
                    color := stack.top(colors_stack)
                    color = core.brightness(color, brightness)
                    color = core.alpha(color, alpha)
                    append_word(terse, word, size, font, color, word_is_icon, group)
                }

                word = ""
                word_is_icon = false
                word_icon_scale = {}
                word_is_tab = false
                word_tab_width = 0
            }
        }
    }

    apply_last_line_gap(terse)
    for &l in terse.lines do update_line_ending_space(terse, &l)

    last_line := slice.last_ptr(terse.lines[:])
    assert(last_line != nil)

    // apply vertical alignment
    vertical_empty_space := terse.rect.y + terse.rect.h - (last_line.rect.y + last_line.rect.h)
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
                for &w in line_words(terse, &line) do w.rect.y += offset_rect_y
            }
        }
    }

    for &line in terse.lines {
        // apply horizontal alignment
        switch line.align {
        case .left: // already aligned
        case .center, .right:
            offset_rect_x := (terse.rect.w - line.rect.w) / (line.align == .center ? 2 : 1)
            line.rect.x += offset_rect_x
            for &w in line_words(terse, &line) do w.rect.x += offset_rect_x
        }

        // vertically center words in a line in case they have different heights
        for &w in line_words(terse, &line) {
            space := (line.rect.h - w.rect.h)/2
            w.rect.y += space
        }
    }

    // update terse.rect
    first_line := slice.first_ptr(terse.lines[:])
    if first_line != nil {
        terse.rect = first_line.rect
        for line in terse.lines[1:] do core.rect_add_rect(&terse.rect, line.rect)
        terse.rect = core.rect_inflated(terse.rect, terse.pad)
    }

    // generate rects for terse.groups
    for &group in terse.groups {
        prev_line_idx := int(-1)
        for &w in group_words(terse, &group) {
            if w.line_idx != prev_line_idx {
                append(&group.rects, w.rect)
            } else {
                core.rect_add_rect(slice.last_ptr(group.rects[:]), w.rect)
            }
            prev_line_idx = w.line_idx
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
append_line :: proc (terse: ^Terse, font: ^Font, nobreak_first_word_idx := -1) -> ^Line {
    line_rect_y := terse.rect.y
    line_align := default_align

    prev_line := slice.last_ptr(terse.lines[:])
    if prev_line != nil {
        apply_last_line_gap(terse)

        line_rect_y = prev_line.rect.y + prev_line.rect.h + font.line_spacing
        line_align = prev_line.align

        update_line_width(terse, prev_line)
    }

    line := Line {
        rect    = { terse.rect.x, line_rect_y, 0, font.height },
        align   = line_align,
    }

    // move nobreak words from end of last line to start of new line
    if nobreak_first_word_idx >= 0 {
        line.word_start_idx = nobreak_first_word_idx
        line.word_count = len(terse.words) - line.word_start_idx
        assert(prev_line != nil)
        prev_line.word_count -= line.word_count

        word_x_offset := -(terse.words[line.word_start_idx].rect.x - prev_line.rect.x)
        word_y_offset := line.rect.y - prev_line.rect.y
        for &w in line_words(terse, &line) {
            w.rect.x += word_x_offset
            w.rect.y += word_y_offset
        }

        update_line_width(terse, prev_line)
        update_line_width(terse, &line)
    }

    append(&terse.lines, line)
    return slice.last_ptr(terse.lines[:])
}

@private
update_line_width :: proc (terse: ^Terse, line: ^Line) {
    if line.word_count > 0 {
        last_word := &terse.words[line.word_start_idx + line.word_count - 1]
        first_word_x1 := terse.words[line.word_start_idx].rect.x
        last_word_x2 := last_word.rect.x + last_word.rect.w
        line.rect.w = last_word_x2 - first_word_x1
    } else {
        line.rect.w = 0
    }
}

@private
update_line_ending_space :: proc (terse: ^Terse, line: ^Line) {
    if line.word_count > 0 {
        last_word := &terse.words[line.word_start_idx + line.word_count - 1]
        if strings.ends_with(last_word.text, " ") {
            last_word.text = last_word.text[:len(last_word.text)-1]
            size := last_word.font->measure_text(last_word.text)
            line.rect.w -= last_word.rect.w - size.x
            last_word.rect.w = size.x
        }
    }
}

@private
apply_last_line_gap :: proc (terse: ^Terse) {
    if len(terse.lines) < 2 do return // do not apply gap if no lines OR there is only one line

    line := slice.last_ptr(terse.lines[:])
    if line.gap == 0 do return

    line.rect.y += line.gap
    for &w in line_words(terse, line) do w.rect.y += line.gap
}

@private
line_has_printable_words :: proc (terse: ^Terse, line: ^Line) -> bool {
    for w in line_words(terse, line) {
        if len(w.text) > 0 && w.text != " " do return true
    }
    return false
}

@private
last_line_continue_tab_width :: proc (terse: ^Terse) -> f32 {
    // text text text      <tab=x> text text text| <- wrap
    // <---continue_tab_width----> text...       |

    if len(terse.lines) > 0 {
        line := slice.last_ptr(terse.lines[:])
        #reverse for w in line_words(terse, line) {
            if w.text == "" { // TODO: this is ugly, consider adding flags to Word, so its possible to detect tab for sure
                return w.rect.x + w.rect.w - line.rect.x
            }
        }
    }
    return 0
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
