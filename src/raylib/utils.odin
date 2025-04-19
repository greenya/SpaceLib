package spacelib_raylib

import "core:strings"
import rl "vendor:raylib"
import sl ".."

font_spacing :: proc (font_size: f32) -> f32 {
    return max(1, font_size / 10)
}

vec3_to_color :: proc (v: sl.Vec3) -> rl.Color {
    return { u8(v.r*255), u8(v.g*255), u8(v.b*255), 255 }
}

measure_text :: proc (font: ^sl.Font, text: string) -> rl.Vector2 {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    size := rl.MeasureTextEx((cast (^rl.Font) font.font_ptr)^, cstr, font.height, font.letter_spacing)
    return size
}
