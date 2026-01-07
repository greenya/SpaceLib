package spacelib_terse

import "core:fmt"
import "core:slice"
import "core:strings"
import "../core"

Terse :: struct {
    text        : string,
    text_cloned : bool,
    rect        : Rect,
    rect_input  : Rect,
    pad         : Vec2,
    wrap        : bool,
    valign      : Vertical_Alignment,
    words       : [] Word,
    lines       : [] Line,
    groups      : [] Group,
}

Line :: struct {
    rect            : Rect,
    align           : Horizontal_Alignment,
    gap             : f32,
    words           : [] Word,
    _word_start_idx : int,
    _word_count     : int,
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
    words           : [] Word,
    _word_start_idx : int,
    _word_count     : int,
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

@private
Builder :: struct {
    terse       : ^Terse,
    words_arr   : [dynamic] Word,
    lines_arr   : [dynamic] Line,
    groups_arr  : [dynamic] Group,
}

Measure_Text_Proc   :: proc (font: ^Font, text: string) -> Vec2
Query_Font_Proc     :: proc (name: string) -> ^Font
Query_Color_Proc    :: proc (name: string) -> Color

query_font : Query_Font_Proc
query_color: Query_Color_Proc

create :: proc (text: string, rect: Rect, should_clone_text := true, allocator := context.allocator) -> ^Terse {
    ensure(query_font != nil)
    ensure(query_color != nil)

    builder: Builder
    builder.terse = new(Terse, allocator)
    builder.terse.rect = rect
    builder.terse.rect_input = rect
    builder.terse.valign = default_valign

    if text == "" {
        builder.terse.rect.w = 0
        builder.terse.rect.h = 0
        return builder.terse
    }

    text := text
    if should_clone_text {
        builder.terse.text = strings.clone(text, allocator=allocator)
        builder.terse.text_cloned = true
        text = builder.terse.text
    } else {
        builder.terse.text = text
    }

    builder.words_arr.allocator = allocator
    builder.lines_arr.allocator = allocator
    builder.groups_arr.allocator = allocator

    alpha := f32(1)
    brightness := f32(0)

    fonts_stack: core.Stack(^Font, default_fonts_stack_size)
    core.stack_push(&fonts_stack, query_font(default_font_name))
    ensure(core.stack_top(fonts_stack).measure_text != nil, "Font.measure_text must be set")

    colors_stack: core.Stack(Color, default_colors_stack_size)
    core.stack_push(&colors_stack, query_color(default_color_name))

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
        line := append_line(&builder, core.stack_top(fonts_stack))

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
                    case "wrap"     : builder.terse.wrap = true
                    case "top"      : builder.terse.valign = .top
                    case "middle"   : builder.terse.valign = .middle
                    case "bottom"   : builder.terse.valign = .bottom

                    case "/font", "/f":
                        ensure(!core.stack_is_empty(fonts_stack), "Fonts stack underflow")
                        core.stack_drop(&fonts_stack)
                        last_opened_command = .none

                    case "/color", "/c":
                        ensure(!core.stack_is_empty(colors_stack), "Colors stack underflow")
                        core.stack_drop(&colors_stack)
                        last_opened_command = .none

                    case "/group":
                        ensure(group != nil, "No group to close")
                        group = nil
                        last_opened_command = .none

                    case "nobreak":
                        ensure(!nobreak.active, "\"nobreak\" commands cannot be nested")
                        nobreak = { true, len(builder.words_arr)-1 }
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

                            case "font", "f":
                                ensure(!core.stack_is_full(fonts_stack), "Fonts stack overflow")
                                font := query_font(command_value)
                                ensure(font.measure_text != nil, "Font.measure_text must be set")
                                core.stack_push(&fonts_stack, font)
                                line.rect.h = line._word_count > 0 ? max(line.rect.h, font.height) : font.height
                                last_opened_command = .font

                            case "color", "c":
                                ensure(!core.stack_is_full(colors_stack), "Colors stack overflow")
                                color := command_value[0] == '#' ? core.color_from_hex(command_value) : query_color(command_value)
                                core.stack_push(&colors_stack, color)
                                last_opened_command = .color

                            case "group":
                                ensure(group == nil, "Groups cannot be nested")
                                group = append_group(&builder, command_value)
                                last_opened_command = .group

                            case "icon":
                                assert(word == "")
                                word, word_icon_scale = parse_icon_args(command_value)
                                word_is_icon = true

                            case "tab":
                                word_tab_width = f32(parse_int(command_value)) // todo: use parse_f32() when it can parse any float
                                if line._word_count > 0 {
                                    last_word := &builder.words_arr[line._word_start_idx + line._word_count - 1]
                                    last_word_x2_local := last_word.rect.x + last_word.rect.w - line.rect.x
                                    word_tab_width -= last_word_x2_local
                                }
                                if word_tab_width != 0 do word_is_tab = true

                            case "gap":
                                gap_ratio := parse_f32(command_value)
                                line.gap = gap_ratio * core.stack_top(fonts_stack).height

                            case "pad":
                                ensure(len(builder.words_arr) == 0 && len(builder.lines_arr) == 1, "Can apply pad only on 1st line with no words measured")
                                builder.terse.pad = parse_vec_int(command_value)
                                builder.lines_arr[0].rect = core.rect_moved(builder.lines_arr[0].rect, builder.terse.pad)
                                core.rect_inflate(&builder.terse.rect, -builder.terse.pad)

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
                font := core.stack_top(fonts_stack)
                size := word_is_icon\
                    ? word_icon_scale * Vec2 { font.height, font.height }\
                    : word_is_tab\
                        ? Vec2 { word_tab_width, font.height }\
                        : font->measure_text(word)

                line_break_needed := line.rect.w + size.x > builder.terse.rect.w && line._word_count > 0
                if builder.terse.wrap && line_break_needed {
                    line_break_allowed := true
                    nobreak_first_word_idx := -1

                    if nobreak.active {
                        if nobreak.last_breakable_word_idx != len(builder.words_arr)-1 { // does list have words
                            first_word_idx := 1 + nobreak.last_breakable_word_idx
                            if first_word_idx == line._word_start_idx { // start of the line? -- skip append line
                                line_break_allowed = false
                            } else {
                                nobreak_first_word_idx = first_word_idx
                            }
                        }
                    }

                    if line_break_allowed {
                        continue_tab_width := last_line_continue_tab_width(builder)
                        line = append_line(&builder, font, nobreak_first_word_idx)
                        if continue_tab_width > 0 {
                            append_word(&builder, "", {continue_tab_width,size.y}, font, {}, false, group)
                        }
                    }
                }

                if word != " " || word_is_tab || line_has_printable_words(builder, line^) { // skip " " at the start of the line
                    color := core.stack_top(colors_stack)
                    color = core.brightness(color, brightness)
                    color = core.alpha(color, alpha)
                    append_word(&builder, word, size, font, color, word_is_icon, group)
                }

                word = ""
                word_is_icon = false
                word_icon_scale = {}
                word_is_tab = false
                word_tab_width = 0
            }
        }
    }

    apply_last_line_gap(builder)
    for &l in builder.lines_arr do update_line_ending_space(&builder, &l)

    last_line := slice.last_ptr(builder.lines_arr[:])
    assert(last_line != nil)

    // apply vertical alignment
    vertical_empty_space := builder.terse.rect.y + builder.terse.rect.h - (last_line.rect.y + last_line.rect.h)
    if vertical_empty_space > 0 || !builder.terse.wrap {
        // for negative empty space, we apply vertical alignment only for non-wrapping text (one-liners);
        // for wrapping text it will be aligned to the top
        offset_rect_y: f32

        switch builder.terse.valign {
        case .top: // already aligned
        case .middle: offset_rect_y = vertical_empty_space/2
        case .bottom: offset_rect_y = vertical_empty_space
        }

        if offset_rect_y != 0 do for &line in builder.lines_arr {
            line.rect.y += offset_rect_y
            for &w in builder_line_words(builder, line) do w.rect.y += offset_rect_y
        }
    }

    for &line in builder.lines_arr {
        // apply horizontal alignment
        switch line.align {
        case .left: // already aligned
        case .center, .right:
            offset_rect_x := (builder.terse.rect.w - line.rect.w) / (line.align == .center ? 2 : 1)
            line.rect.x += offset_rect_x
            for &w in builder_line_words(builder, line) do w.rect.x += offset_rect_x
        }

        // vertically center words in a line in case they have different heights
        for &w in builder_line_words(builder, line) {
            space := (line.rect.h - w.rect.h)/2
            w.rect.y += space
        }
    }

    // update full rect
    first_line := slice.first_ptr(builder.lines_arr[:])
    if first_line != nil {
        builder.terse.rect = first_line.rect
        for line in builder.lines_arr[1:] do core.rect_grow(&builder.terse.rect, line.rect)
        core.rect_inflate(&builder.terse.rect, builder.terse.pad)
    }

    // prepare slices and return the terse

    shrink(&builder.words_arr)
    builder.terse.words = builder.words_arr[:]

    shrink(&builder.lines_arr)
    builder.terse.lines = builder.lines_arr[:]
    for &l in builder.terse.lines do l.words = builder_line_words(builder, l)

    shrink(&builder.groups_arr)
    builder.terse.groups = builder.groups_arr[:]
    for &g in builder.terse.groups do g.words = builder_group_words(builder, g)

    return builder.terse
}

destroy :: proc (terse: ^Terse) {
    if terse == nil do return

    if terse.text_cloned do delete(terse.text)
    delete(terse.groups)
    delete(terse.lines)
    delete(terse.words)

    free(terse)
}

@private
append_line :: proc (builder: ^Builder, font: ^Font, nobreak_first_word_idx := -1) -> ^Line {
    line_rect_y := builder.terse.rect.y
    line_align := default_align

    prev_line := slice.last_ptr(builder.lines_arr[:])
    if prev_line != nil {
        apply_last_line_gap(builder^)

        line_rect_y = prev_line.rect.y + prev_line.rect.h + font.line_spacing
        line_align = prev_line.align

        update_line_width(builder^, prev_line)
    }

    line := Line {
        rect    = { builder.terse.rect.x, line_rect_y, 0, font.height },
        align   = line_align,
    }

    // move nobreak words from end of last line to start of new line
    if nobreak_first_word_idx >= 0 {
        line._word_start_idx = nobreak_first_word_idx
        line._word_count = len(builder.words_arr) - line._word_start_idx
        assert(prev_line != nil)
        prev_line._word_count -= line._word_count

        word_x_offset := -(builder.words_arr[line._word_start_idx].rect.x - prev_line.rect.x)
        word_y_offset := line.rect.y - prev_line.rect.y
        for &w in builder_line_words(builder^, line) {
            w.rect.x += word_x_offset
            w.rect.y += word_y_offset
        }

        update_line_width(builder^, prev_line)
        update_line_width(builder^, &line)
    }

    append(&builder.lines_arr, line)
    return slice.last_ptr(builder.lines_arr[:])
}

@private
update_line_width :: proc (builder: Builder, line: ^Line) {
    if line._word_count > 0 {
        last_word := &builder.words_arr[line._word_start_idx + line._word_count - 1]
        first_word_x1 := builder.words_arr[line._word_start_idx].rect.x
        last_word_x2 := last_word.rect.x + last_word.rect.w
        line.rect.w = last_word_x2 - first_word_x1
    } else {
        line.rect.w = 0
    }
}

@private
update_line_ending_space :: proc (builder: ^Builder, line: ^Line) {
    if line._word_count == 0 do return

    last_word := &builder.words_arr[line._word_start_idx + line._word_count - 1]
    if strings.ends_with(last_word.text, " ") {
        last_word.text = last_word.text[:len(last_word.text)-1]
        size := last_word.font->measure_text(last_word.text)
        line.rect.w -= last_word.rect.w - size.x
        last_word.rect.w = size.x
    }
}

@private
apply_last_line_gap :: proc (builder: Builder) {
    if len(builder.lines_arr) < 2 do return // do not apply gap if no lines OR there is only one line

    line := slice.last_ptr(builder.lines_arr[:])
    if line.gap == 0 do return

    line.rect.y += line.gap
    for &w in builder_line_words(builder, line^) do w.rect.y += line.gap
}

@private
line_has_printable_words :: proc (builder: Builder, line: Line) -> bool {
    for w in builder_line_words(builder, line) {
        if len(w.text) > 0 && w.text != " " do return true
    }
    return false
}

@private
last_line_continue_tab_width :: proc (builder: Builder) -> f32 {
    // text text text      <tab=x> text text text| <- wrap
    // <---continue_tab_width----> text...       |

    if len(builder.lines_arr) > 0 {
        line := slice.last_ptr(builder.lines_arr[:])
        #reverse for w in builder_line_words(builder, line^) {
            if w.text == "" { // TODO: this is ugly, consider adding flags to Word, so its possible to detect tab for sure
                return w.rect.x + w.rect.w - line.rect.x
            }
        }
    }
    return 0
}

@private
append_group :: proc (builder: ^Builder, name: string) -> ^Group {
    group := Group { name=name }
    append(&builder.groups_arr, group)
    return slice.last_ptr(builder.groups_arr[:])
}

@private
append_word :: proc (
    builder : ^Builder,
    text    : string,
    size    : Vec2,
    font    : ^Font,
    color   : Color,
    is_icon : bool,
    group   : ^Group,
) {
    line := slice.last_ptr(builder.lines_arr[:])
    assert(line != nil)

    word := Word {
        rect        = { line.rect.x+line.rect.w, line.rect.y, size.x, size.y },
        text        = text,
        font        = font,
        color       = color,
        is_icon     = is_icon,
        in_group    = group != nil,
        line_idx    = len(builder.lines_arr) - 1,
    }

    append(&builder.words_arr, word)
    line._word_count += 1
    if line._word_count == 1 do line._word_start_idx = len(builder.words_arr) - 1

    line.rect.w += size.x
    line.rect.h = max(line.rect.h, size.y)

    if group != nil {
        group._word_count += 1
        if group._word_count == 1 do group._word_start_idx = len(builder.words_arr) - 1
    }
}
