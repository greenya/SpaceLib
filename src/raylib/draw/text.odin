package spacelib_raylib_draw

import "core:strings"
import rl "vendor:raylib"
import "../../terse"

@private
text_by_rl_font :: #force_inline proc (
    str             : string,
    pos             : Vec2,
    align           : Vec2,
    font            : rl.Font,
    font_size       : f32,
    font_spacing    : f32,
    tint            : Color,
) -> (actual_pos: Vec2) {
    cstr := strings.clone_to_cstring(str, context.temp_allocator)
    size := rl.MeasureTextEx(font, cstr, font_size, font_spacing)
    actual_pos = pos - size * align
    tint_rl := rl.Color(tint)
    rl.DrawTextEx(font, cstr, actual_pos, font_size, font_spacing, tint_rl)
    return
}

@private
text_by_tr_font :: #force_inline proc (
    str     : string,
    pos     : Vec2,
    align   : Vec2,
    font    : ^terse.Font,
    tint    : Color,
) -> (actual_pos: Vec2) {
    font_rl := (cast (^rl.Font) font.font_ptr)^
    return text_by_rl_font(str, pos, align, font_rl, font.height, font.rune_spacing, tint)
}

// `align` - alignment point ratio, examples:
// - `0` top left
// - `.5` center
// - `1` bottom right
// - `{.5,0}` top center
// - `{0,1}` bottom left
text :: proc {
    text_by_tr_font,
    text_by_rl_font,
}

terse :: proc (t: ^terse.Terse, draw_icon_proc: proc (word: ^terse.Word) = nil) {
    for &word in t.words {
        if word.is_icon {
            if draw_icon_proc != nil do draw_icon_proc(&word)
            else                     do rect_lines(word.rect, 2, word.color)
        } else {
            text(word.text, { word.rect.x, word.rect.y }, 0, word.font, word.color)
        }
    }
}
