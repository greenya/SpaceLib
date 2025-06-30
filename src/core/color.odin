package spacelib_core

import "core:fmt"
import "core:math"

Color :: [4] u8

white   :: Color {255,255,255,255}
yellow  :: Color {255,255,0,255}
aqua    :: Color {0,255,255,255}
magenta :: Color {255,0,255,255}
red     :: Color {255,0,0,255}
green   :: Color {0,255,0,255}
blue    :: Color {0,0,255,255}
black   :: Color {0,0,0,255}

vec3_to_color :: #force_inline proc (vec: Vec3) -> Color {
    return { u8(vec.r*255), u8(vec.g*255), u8(vec.b*255), 255 }
}

// Supports: #rgb, #rrggbb, #rrggbbaa
color_from_hex :: proc (text: string) -> Color {
    assert(len(text) > 0 && text[0] == '#')

    char_to_u8 :: proc (c: byte) -> u8 {
        if c>='0' && c<='9' do return c-'0'
        if c>='A' && c<='F' do return c-'A'+10
        if c>='a' && c<='f' do return c-'a'+10
        return 0
    }

    char_pair_to_u8 :: proc (c1, c2: byte) -> u8 {
        return char_to_u8(c1) << 4 | char_to_u8(c2)
    }

    switch len(text) {
    case 4: // #rgb
        r := char_to_u8(text[1]); r |= r<<4
        g := char_to_u8(text[2]); g |= g<<4
        b := char_to_u8(text[3]); b |= b<<4
        return {r,g,b,255}
    case 7: // #rrggbb
        r := char_pair_to_u8(text[1], text[2])
        g := char_pair_to_u8(text[3], text[4])
        b := char_pair_to_u8(text[5], text[6])
        return {r,g,b,255}
    case 9: // #rrggbbaa
        r := char_pair_to_u8(text[1], text[2])
        g := char_pair_to_u8(text[3], text[4])
        b := char_pair_to_u8(text[5], text[6])
        a := char_pair_to_u8(text[7], text[8])
        return {r,g,b,a}
    case:
        return {255,0,255,254}
    }
}

// Returns: #rrggbbaa or #rrggbb (when alpha is 0xff)
color_to_hex :: proc (c: Color, allocator := context.allocator) -> string {
    if c.a != 0xff  do return fmt.aprintf("#%02x%02x%02x%02x", c.r, c.g, c.b, c.a, allocator=allocator)
    else            do return fmt.aprintf("#%02x%02x%02x", c.r, c.g, c.b, allocator=allocator)
}

alpha :: #force_inline proc (c: Color, ratio: f32) -> Color {
    c := c
    c.a = u8(f32(c.a)*ratio)
    return c
}

brightness :: #force_inline proc (c: Color, factor: f32) -> Color {
    r, g, b := f32(c.r), f32(c.g), f32(c.b)
    if factor > 0 {
        return {
            u8(r + (255-r)*factor),
            u8(g + (255-g)*factor),
            u8(b + (255-b)*factor),
            c.a,
        }
    } else {
        factor_plus_1 := factor + 1
        return {
            u8(r*factor_plus_1),
            u8(g*factor_plus_1),
            u8(b*factor_plus_1),
            c.a,
        }
    }
}

// https://iquilezles.org/articles/palettes/
palette :: proc (t: f32, a, b, c, d: Vec3) -> Vec3 {
    cos_arr := Vec3 {
        math.cos(6.283185 * (c.r * t + d.r)),
        math.cos(6.283185 * (c.g * t + d.g)),
        math.cos(6.283185 * (c.b * t + d.b)),
    }
    return a + b*cos_arr
}
