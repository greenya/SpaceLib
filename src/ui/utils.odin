package spacelib_ui

import "base:intrinsics"
import "core:math"
import "core:math/ease"
import "core:math/linalg"
import "core:math/rand"

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

pos_in_rect :: #force_inline proc (pos: Vec2, r: Rect) -> bool {
    return r.x < pos.x && r.x+r.w > pos.x && r.y < pos.y && r.y+r.h > pos.y
}

clamp_pos_to_rect :: #force_inline proc (pos: Vec2, r: Rect) -> Vec2 {
    return { clamp(pos.x, r.x, r.x + r.w), clamp(pos.y, r.y, r.y + r.h) }
}

clamp_ratio :: #force_inline proc (value, minimum, maximum: $T) -> T where intrinsics.type_is_float(T) {
    return clamp((value - minimum) / (maximum - minimum), 0.0, 1.0)
}

ease_ratio :: #force_inline proc "contextless" (ratio: $T, easing: ease.Ease) -> T {
    return ease.ease(easing, ratio)
}

ease_pos :: proc (from, to: Vec2, ratio: f32, easing: ease.Ease = .Linear) -> Vec2 {
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

random_pos_in_rect :: proc (rect: Rect) -> Vec2 {
    return { rect.x + rect.w*rand.float32(), rect.y + rect.h*rand.float32() }
}

random_pos_in_ring :: proc (inner_radius, outer_radius: f32) -> Vec2 {
    dir := linalg.normalize0(Vec2 { rand.float32()*2 - 1, rand.float32()*2 - 1 })
    return dir * rand.float32_range(inner_radius, outer_radius)
}

pos_moved_towards_pos :: proc (pos, target_pos: Vec2, speed, dt: f32) -> (new_pos: Vec2) {
    dir := linalg.normalize0(target_pos - pos)
    return pos + dir * speed * dt
}

pos_orbited_around_pos :: proc (pos, orbit_pos: Vec2, speed, dt: f32, is_clockwise := true) -> (new_orbit_pos: Vec2) {
    radius := linalg.distance(orbit_pos, pos)
    angle := linalg.atan2(pos.y-orbit_pos.y, pos.x-orbit_pos.x)
    angular_vel := speed / radius
    new_angle := is_clockwise\
        ?  angle + angular_vel * dt\
        : -angle + angular_vel * dt
    new_x := orbit_pos.x + radius * math.cos(new_angle)
    new_y := orbit_pos.y + radius * math.sin(new_angle)
    return { new_x, new_y }
}

is_consumed :: #force_inline proc (flag: ^bool) -> bool {
    if !flag^ do return false
    flag^ = false
    return true
}

alpha :: #force_inline proc (c: Color, alpha_ratio: f32) -> Color {
    c := c
    c.a = u8(f32(c.a)*alpha_ratio)
    return c
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
