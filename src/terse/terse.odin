package spacelib_terse

// TODO: rework "color" and "font" to be stack-based, e.g. {color=a}...{/color}
// TODO: add support for named groups, e.g. {group=title}...{/group}; Text.groups should be dynamic array (or map?)
// TODO: add support for extra top gap for a line, e.g. {gap=0} should set gap for current line, default value is 0, the value is not transferred to next line (e.g. new line starts with gap=0)
// TODO: [?] maybe rework "icon" so its size is not Vec2 {font_height,font_height} but is returned by Query_Block_Proc (and rename "icon" to "block")
// TODO: add support for optional icon size: {icon=title^1.75}, should use 1.75*font.height for icon size

import "core:fmt"
import "core:slice"
import "core:strings"
import "../core"

@(private) Vec2 :: core.Vec2
@(private) Rect :: core.Rect
@(private) Color :: core.Color

Text :: struct {
    rect        : Rect,
    rect_input  : Rect,
    valign      : Vertical_Alignment,
    lines       : [dynamic] Line,
}

Line :: struct {
    rect    : Rect,
    align   : Horizontal_Alignment,
    words   : [dynamic] Word,
}

Word :: struct {
    rect    : Rect,
    text    : string,
    font    : ^Font,
    color   : Color,
    is_icon : bool,
}

Font :: struct {
    font_ptr        : rawptr,
    height          : f32,
    letter_spacing  : f32,
    line_spacing    : f32,
    measure_text    : Measure_Text_Proc,
}

Horizontal_Alignment    :: enum { left, center, right }
Vertical_Alignment      :: enum { top, middle, bottom }

Measure_Text_Proc   :: proc (font: ^Font, text: string) -> Vec2
Query_Font_Proc     :: proc (name: string) -> ^Font
Query_Color_Proc    :: proc (name: string) -> Color

@(private) default_valign   :: Vertical_Alignment.middle
@(private) default_align    :: Horizontal_Alignment.center
@(private) default_font     :: ""
@(private) default_color    :: ""

create :: proc (
    str             : string,
    rect            : Rect,
    query_font      : Query_Font_Proc,
    query_color     : Query_Color_Proc,
    allocator       := context.allocator,
    debug_keep_codes:= false,
) -> ^Text {
    text := new(Text, allocator)
    text.rect = rect
    text.rect_input = rect
    text.valign = default_valign
    text.lines.allocator = allocator

    if str == "" do return text

    font: ^Font = query_font(default_font)
    color: Color = query_color(default_color)
    wrapping_allowed := rect.w > 0

    cursor: struct { type: enum { text, code }, start: int }
    code, word, icon: string

    for para in strings.split(str, "\n", context.temp_allocator) {
        line := _append_line(text, font)

        cursor = { type=.text, start=0 }
        for i:=0; i<len(para); i+=1 {
            if para[i] == '{' && cursor.type == .text {
                word = para[cursor.start:i]
                cursor = { start=i+1, type=.code }
            }

            if para[i] == '}' && cursor.type == .code {
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
                case "top"      : text.valign = .top
                case "middle"   : text.valign = .middle
                case "bottom"   : text.valign = .bottom
                case:
                    pair_sep_index := strings.index(command, "=")
                    if pair_sep_index >= 0 && pair_sep_index <= len(command)-2 {
                        command_name := command[0:pair_sep_index]
                        command_value := command[pair_sep_index+1:]
                        switch command_name {
                        case "color":
                            color = query_color(command_value)
                        case "font":
                            font = query_font(command_value)
                            line.rect.h = len(line.words) > 0 ? max(line.rect.h, font.height) : font.height
                        case "icon":
                            icon = command_value
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
                word_size := font->measure_text(word)

                if wrapping_allowed && line.rect.w + word_size.x > rect.w && len(line.words) > 0 {
                    line = _append_line(text, font)
                }

                word_rect := Rect { line.rect.x+line.rect.w, line.rect.y, word_size.x, word_size.y }
                append(&line.words, Word { rect=word_rect, text=word, font=font, color=color })
                line.rect.w += word_size.x

                word = ""
            }

            if icon != "" {
                icon_size := Vec2 { font.height, font.height }

                if wrapping_allowed && line.rect.w + icon_size.x > rect.w && len(line.words) > 0 {
                    line = _append_line(text, font)
                }

                word_rect := Rect { line.rect.x+line.rect.w, line.rect.y, icon_size.x, icon_size.y }
                append(&line.words, Word { rect=word_rect, text=icon, font=font, color=color, is_icon=true })
                line.rect.w += icon_size.x
                line.rect.h = len(line.words) > 0 ? max(line.rect.h, icon_size.y) : font.height

                icon = ""
            }
        }
    }

    last_line := slice.last_ptr(text.lines[:])
    assert(last_line != nil)

    // apply vertical alignment
    vertical_empty_space := rect.y + rect.h - (last_line.rect.y + last_line.rect.h)
    if vertical_empty_space > 0 {
        offset_rect_y := f32(-1)

        switch text.valign {
        case .top: // already aligned
        case .middle: offset_rect_y = vertical_empty_space/2
        case .bottom: offset_rect_y = vertical_empty_space
        }

        if offset_rect_y > 0 {
            for &line in text.lines {
                line.rect.y += offset_rect_y
                for &word in line.words do word.rect.y += offset_rect_y
            }
        }
    }

    for &line in text.lines {
        // apply horizontal alignment
        switch line.align {
        case .left: // already aligned
        case .center, .right:
            offset_rect_x := (rect.w - line.rect.w) / (line.align == .center ? 2 : 1)
            line.rect.x += offset_rect_x
            for &word in line.words do word.rect.x += offset_rect_x
        }

        // vertically center words in a line in case they have different heights
        max_word_height := f32(-1)
        for &word in line.words do if max_word_height < word.rect.h do max_word_height = word.rect.h
        for &word in line.words {
            space := (max_word_height - word.rect.h)/2
            word.rect.y += space
        }
    }

    // calculate text.rect
    first_line := slice.first_ptr(text.lines[:])
    if first_line != nil {
        text.rect = first_line.rect
        for line in text.lines[1:] {
            core.rect_add_rect(&text.rect, line.rect)
        }
    }

    return text
}

destroy :: proc (text: ^Text) {
    if text == nil do return
    for line in text.lines do delete(line.words)
    delete(text.lines)
    free(text)
}

@(private)
_append_line :: proc (text: ^Text, font: ^Font) -> ^Line {
    line_rect_y := text.rect.y
    line_align := default_align

    prev_line := slice.last_ptr(text.lines[:])
    if prev_line != nil {
        line_rect_y = prev_line.rect.y + prev_line.rect.h + font.line_spacing
        line_align = prev_line.align

        // re-measure last word of last line in case it ends with space
        last_word := slice.last_ptr(prev_line.words[:])
        if last_word != nil && strings.ends_with(last_word.text, " ") {
            last_word.text = last_word.text[:len(last_word.text)-1]
            size := font->measure_text(last_word.text)
            prev_line.rect.w -= last_word.rect.w - size.x
            last_word.rect.w = size.x
        }
    }

    append(&text.lines, Line {})
    line := slice.last_ptr(text.lines[:])
    line.rect = { text.rect.x, line_rect_y, 0, font.height }
    line.align = line_align
    line.words.allocator = text.lines.allocator

    return line
}
