package spacelib_core

import "base:intrinsics"
import "core:math"
import "core:math/ease"
import "core:math/linalg"
import "core:math/rand"
import "core:slice"
_ :: slice

Vec2 :: [2] f32
Vec3 :: [3] f32
Rect :: struct { x, y, w, h: f32 }
Color :: [4] u8

rect_center :: #force_inline proc (r: Rect) -> Vec2 {
    return { r.x + r.w/2, r.y + r.h/2 }
}

rect_half_left :: #force_inline proc (r: Rect) -> Rect {
    return { r.x, r.y, r.w/2, r.h }
}

rect_half_right :: #force_inline proc (r: Rect) -> Rect {
    return { r.x+r.w/2, r.y, r.w/2, r.h }
}

rect_half_top :: #force_inline proc (r: Rect) -> Rect {
    return { r.x, r.y, r.w, r.h/2 }
}

rect_half_bottom :: #force_inline proc (r: Rect) -> Rect {
    return { r.x, r.y+r.h/2, r.w, r.h/2 }
}

rect_line_bottom :: #force_inline proc (r: Rect, thick: f32) -> Rect {
    return { r.x, r.y+r.h-thick, r.w, thick }
}

rect_inflated :: #force_inline proc (r: Rect, size: Vec2) -> Rect {
    return { r.x - size.x, r.y - size.y, r.w + 2*size.x, r.h + 2*size.y }
}

rect_moved :: #force_inline proc (r: Rect, v: Vec2) -> Rect {
    return { r.x + v.x, r.y + v.y, r.w, r.h }
}

rect_from_center :: #force_inline proc (v: Vec2, size: Vec2) -> Rect {
    return { v.x-size.x/2, v.y-size.y/2, size.x, size.y }
}

rect_add_rect :: #force_inline proc (r: ^Rect, o: Rect) {
    if o.x < r.x {
        r.w += r.x - o.x
        r.x = o.x
    }

    if o.y < r.y {
        r.h += r.y - o.y
        r.y = o.y
    }

    dx := o.x+o.w - (r.x+r.w)
    if dx > 0 do r.w += dx

    dy := o.y+o.h - (r.y+r.h)
    if dy > 0 do r.h += dy
}

rect_intersection :: #force_inline proc (a: Rect, b: Rect) -> Rect {
    x1 := max(a.x, b.x)
    x2 := min(a.x+a.w, b.x+b.w)
    if x2 > x1 {
        y1 := max(a.y, b.y)
        y2 := min(a.y+a.h, b.y+b.h)
        if y2 > y1 {
            return { x1, y1, x2-x1, y2-y1 }
        }
    }
    return {}
}

vec_in_rect :: #force_inline proc (vec: Vec2, r: Rect) -> bool {
    return r.x < vec.x && r.x+r.w > vec.x && r.y < vec.y && r.y+r.h > vec.y
}

clamp_vec_to_rect :: #force_inline proc (vec: Vec2, r: Rect) -> Vec2 {
    return { clamp(vec.x, r.x, r.x + r.w), clamp(vec.y, r.y, r.y + r.h) }
}

clamp_ratio :: #force_inline proc (value, minimum, maximum: $T) -> T where intrinsics.type_is_float(T) {
    return clamp((value - minimum) / (maximum - minimum), 0.0, 1.0)
}

ease_ratio :: #force_inline proc "contextless" (ratio: $T, easing: ease.Ease) -> T {
    return ease.ease(easing, ratio)
}

ease_vec :: proc (from, to: Vec2, ratio: f32, easing: ease.Ease = .Linear) -> Vec2 {
    ratio := easing != .Linear ? ease.ease(easing, ratio) : ratio
    return {
        from.x + (to.x - from.x) * ratio,
        from.y + (to.y - from.y) * ratio,
    }
}

ease_rect :: proc (from, to: Rect, ratio: f32, easing := ease.Ease.Linear) -> Rect {
    ratio := easing != .Linear ? ease.ease(easing, ratio) : ratio
    return {
        from.x + (to.x - from.x) * ratio,
        from.y + (to.y - from.y) * ratio,
        from.w + (to.w - from.w) * ratio,
        from.h + (to.h - from.h) * ratio,
    }
}

ease_color :: proc (from, to: Color, ratio: f32, easing := ease.Ease.Linear) -> Color {
    ratio := easing != .Linear ? ease.ease(easing, ratio) : ratio
    return {
        from[0] + u8(f32(to[0] - from[0]) * ratio),
        from[1] + u8(f32(to[1] - from[1]) * ratio),
        from[2] + u8(f32(to[2] - from[2]) * ratio),
        from[3] + u8(f32(to[3] - from[3]) * ratio),
    }
}

random_vec_in_rect :: proc (rect: Rect) -> Vec2 {
    return { rect.x + rect.w*rand.float32(), rect.y + rect.h*rand.float32() }
}

random_vec_in_ring :: proc (inner_radius, outer_radius: f32) -> Vec2 {
    dir := linalg.normalize0(Vec2 { rand.float32()*2 - 1, rand.float32()*2 - 1 })
    return dir * rand.float32_range(inner_radius, outer_radius)
}

vec3_to_color :: #force_inline proc (vec: Vec3) -> Color {
    return { u8(vec.r*255), u8(vec.g*255), u8(vec.b*255), 255 }
}

vec_moved_towards_vec :: proc (current_vec, target_vec: Vec2, speed, dt: f32) -> (new_vec: Vec2) {
    dir := linalg.normalize0(target_vec - current_vec)
    return current_vec + dir * speed * dt
}

vec_orbited_around_vec :: proc (vec, center_vec: Vec2, speed, dt: f32, is_clockwise := true) -> (new_vec: Vec2) {
    radius := linalg.distance(center_vec, vec)
    angle := linalg.atan2(vec.y-center_vec.y, vec.x-center_vec.x)
    angular_vel := speed / radius
    new_angle := is_clockwise\
        ?  angle + angular_vel * dt\
        : -angle + angular_vel * dt
    new_x := center_vec.x + radius * math.cos(new_angle)
    new_y := center_vec.y + radius * math.sin(new_angle)
    return { new_x, new_y }
}

scale_target_size :: proc (screen: Vec2, target: Vec2) -> (scale: f32, render: Rect) {
    scale = min(screen.x/target.x, screen.y/target.y)
    render_w, render_h := target.x*scale, target.y*scale
    render = {
        (screen.x - render_w)/2,
        (screen.y - render_h)/2,
        render_w,
        render_h,
    }
    return
}

map_keys_sorted :: proc (m: $M/map[$K]$V, allocator := context.allocator) -> [] string {
    keys, _ := slice.map_keys(m, context.temp_allocator)
    slice.sort(keys)
    return keys
}

is_consumed :: #force_inline proc (flag: ^bool) -> bool {
    if !flag^ do return false
    flag^ = false
    return true
}

// Supports: #rgb, #rrggbb, #rrggbbaa
color_from_hex :: proc (text: string) -> Color {
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
        g := char_to_u8(text[1]); g |= g<<4
        b := char_to_u8(text[1]); b |= b<<4
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

extract_hrs_mins_secs_from_total_seconds :: proc (time_total_sec: f32) -> (hrs: int, mins: int, secs: int) {
    if time_total_sec < 0 do return 0, 0, 0

    total_sec := int(time_total_sec)
    hrs, total_sec      = total_sec/3600, total_sec%3600
    mins, total_sec     = total_sec/60, total_sec%60
    secs                = total_sec
    return
}
