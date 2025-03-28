package spacelib_raylib

import rl "vendor:raylib"
import sl ".."

font_spacing :: proc (font_size: f32) -> f32 {
    return max(1, font_size / 10)
}

vec3_to_color :: proc (v: sl.Vec3) -> rl.Color {
    return { u8(v.r*255), u8(v.g*255), u8(v.b*255), 255 }
}
