package spacelib

import "core:slice"
import "core:strings"

Font :: struct {
    font_ptr: rawptr,
    height: f32,
    letter_spacing: f32,
    word_spacing: f32,
    line_spacing: f32,
    measure_text: Measure_Text_Proc,
}

Measure_Text_Proc :: proc (font: ^Font, text: string) -> Vec2

Measured_Text :: struct {
    rect: Rect,
    lines: [dynamic] Measured_Line,
}

Measured_Line :: struct {
    rect: Rect,
    words: [dynamic] Measured_Word,
}

Measured_Word :: struct {
    rect: Rect,
    text: string,
}

Text_Alignment :: struct {
    horizontal  : enum { top, center, bottom },
    vertical    : enum { left, center, right },
}

measure_text_rect :: proc (text: string, rect: Rect, font: ^Font, align := Text_Alignment {.center,.center}, allocator := context.allocator) -> ^Measured_Text {
    measure_text := new(Measured_Text, allocator)

    loop: for para in strings.split(text, "\n", context.temp_allocator) {
        line := _append_measured_line(&measure_text.lines, rect, font)

        for word in strings.split(para, " ", context.temp_allocator) {
            word_cstr := strings.clone_to_cstring(word, context.temp_allocator)
            word_size := font->measure_text(word)
            word_prefix_spacing := len(line.words) > 0 ? font.word_spacing : 0

            if line.rect.w + word_prefix_spacing + word_size.x > rect.w {
                line = _append_measured_line(&measure_text.lines, rect, font)
            } else {
                line.rect.w += word_prefix_spacing
            }

            append(&line.words, Measured_Word { rect={line.rect.x+line.rect.w,line.rect.y,word_size.x,word_size.y}, text=word })
            line.rect.w += word_size.x
        }
    }

    last_line := slice.last_ptr(measure_text.lines[:])
    if last_line == nil {
        return measure_text
    }

    horizontal_empty_space := rect.y + rect.h - (last_line.rect.y + last_line.rect.h)
    if horizontal_empty_space > 0 {
        offset_rect_y := f32(-1)

        switch align.horizontal {
        case .top: // already aligned
        case .center: offset_rect_y = horizontal_empty_space/2
        case .bottom: offset_rect_y = horizontal_empty_space
        }

        if offset_rect_y > 0 {
            for &line in measure_text.lines {
                line.rect.y += offset_rect_y
                for &word in line.words do word.rect.y += offset_rect_y
            }
        }
    }

    switch align.vertical {
    case .left: // already aligned
    case .center, .right:
        for &line in measure_text.lines {
            offset_rect_x := (rect.w - line.rect.w) / (align.vertical == .center ? 2 : 1)
            line.rect.x += offset_rect_x
            for &word in line.words do word.rect.x += offset_rect_x
        }
    }

    first_line := slice.first_ptr(measure_text.lines[:])
    if first_line != nil {
        measure_text.rect = first_line.rect
        for line in measure_text.lines[1:] {
            rect_add_rect(&measure_text.rect, line.rect)
        }
    }

    return measure_text
}

destroy_measured_text :: proc (mt: ^Measured_Text) {
    for line in mt.lines do delete(line.words)
    delete(mt.lines)
    free(mt)
}

@(private)
_append_measured_line :: proc (lines: ^[dynamic] Measured_Line, rect: Rect, font: ^Font) -> ^Measured_Line {
    rect_y := rect.y

    count := len(lines)
    if count > 0 {
        last_line_rect := &lines[count-1].rect
        rect_y = last_line_rect.y + last_line_rect.h + font.line_spacing
    }

    append(lines, Measured_Line { rect={rect.x,rect_y,0,font.height} })
    return slice.last_ptr(lines[:])
}
