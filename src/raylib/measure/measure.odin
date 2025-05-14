package spacelib_raylib_measure

import "core:strings"
import rl "vendor:raylib"
import "../../core"
import "../../terse"

@private Vec2 :: core.Vec2

text :: proc (font: ^terse.Font, text: string) -> Vec2 {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    size := rl.MeasureTextEx((cast (^rl.Font) font.font_ptr)^, cstr, font.height, font.rune_spacing)
    return size
}
