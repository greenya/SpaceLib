package spacelib

import "core:math"
import "core:math/linalg"
import "core:math/rand"

Vec2 :: [2] f32
Vec3 :: [3] f32
Rect :: struct { x, y, w, h: f32 }

rect_center :: proc (r: Rect) -> Vec2 {
    return { r.x + r.w/2, r.y + r.h/2 }
}

rect_inflated :: proc (r: Rect, v: Vec2) -> Rect {
    return { r.x - v.x, r.y - v.y, r.w + 2*v.x, r.h + 2*v.y }
}

rect_moved :: proc (r: Rect, v: Vec2) -> Rect {
    return { r.x + v.x, r.y + v.y, r.w, r.h }
}

rect_from_center :: proc (v: Vec2, size: Vec2) -> Rect {
    return { v.x-size.x/2, v.y-size.y/2, size.x, size.y }
}

rect_add_rect :: proc (r: ^Rect, o: Rect) {
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

clamp_pos_to_rect :: proc (v: Vec2, r: Rect) -> Vec2 {
    return { clamp(v.x, r.x, r.x + r.w), clamp(v.y, r.y, r.y + r.h) }
}

clamp_ratio :: proc (value, minimum, maximum: $T) -> T where intrinsics.type_is_float(T) {
    return clamp((value - minimum) / (maximum - minimum), 0.0, 1.0)
}

is_consumed :: proc (flag: ^bool) -> bool {
    if !flag^ do return false
    flag^ = false
    return true
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

pos_orbited_around_pos :: proc (pos, orbit_pos: Vec2, speed, dt: f32, is_clockwise := true) -> (new_pos: Vec2) {
    radius := linalg.distance(orbit_pos, pos)
    angle := linalg.atan2(pos.y-orbit_pos.y, pos.x-orbit_pos.x)
    angular_vel := speed / radius
    new_angle := is_clockwise\
        ? angle + angular_vel * dt\
        : -angle + angular_vel * dt
    new_x := orbit_pos.x + radius * math.cos(new_angle)
    new_y := orbit_pos.y + radius * math.sin(new_angle)
    return { new_x, new_y }
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
