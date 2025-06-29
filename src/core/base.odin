package spacelib_core

import "base:intrinsics"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

Vec2 :: [2] f32
Vec3 :: [3] f32
Rect :: struct { x, y, w, h: f32 }

rect_top_left       :: #force_inline proc (r: Rect) -> Vec2 { return { r.x, r.y } }
rect_top            :: #force_inline proc (r: Rect) -> Vec2 { return { r.x + r.w/2, r.y } }
rect_top_right      :: #force_inline proc (r: Rect) -> Vec2 { return { r.x + r.w, r.y } }
rect_left           :: #force_inline proc (r: Rect) -> Vec2 { return { r.x, r.y + r.h/2 } }
rect_center         :: #force_inline proc (r: Rect) -> Vec2 { return { r.x + r.w/2, r.y + r.h/2 } }
rect_right          :: #force_inline proc (r: Rect) -> Vec2 { return { r.x + r.w, r.y + r.h/2 } }
rect_bottom_left    :: #force_inline proc (r: Rect) -> Vec2 { return { r.x, r.y + r.h } }
rect_bottom         :: #force_inline proc (r: Rect) -> Vec2 { return { r.x + r.w/2, r.y + r.h } }
rect_bottom_right   :: #force_inline proc (r: Rect) -> Vec2 { return { r.x + r.w, r.y + r.h } }

rect_half_left      :: #force_inline proc (r: Rect) -> Rect { return { r.x, r.y, r.w/2, r.h } }
rect_half_right     :: #force_inline proc (r: Rect) -> Rect { return { r.x+r.w/2, r.y, r.w/2, r.h } }
rect_half_top       :: #force_inline proc (r: Rect) -> Rect { return { r.x, r.y, r.w, r.h/2 } }
rect_half_bottom    :: #force_inline proc (r: Rect) -> Rect { return { r.x, r.y+r.h/2, r.w, r.h/2 } }

rect_line_top       :: #force_inline proc (r: Rect, thick: f32) -> Rect { return { r.x, r.y, r.w, thick } }
rect_line_bottom    :: #force_inline proc (r: Rect, thick: f32) -> Rect { return { r.x, r.y+r.h-thick, r.w, thick } }
rect_line_left      :: #force_inline proc (r: Rect, thick: f32) -> Rect { return { r.x, r.y, thick, r.h } }
rect_line_right     :: #force_inline proc (r: Rect, thick: f32) -> Rect { return { r.x+r.w-thick, r.y, thick, r.h } }

rect_inflated :: #force_inline proc (r: Rect, size: Vec2) -> Rect {
    return { r.x - size.x, r.y - size.y, r.w + 2*size.x, r.h + 2*size.y }
}

rect_moved :: #force_inline proc (r: Rect, v: Vec2) -> Rect {
    return { r.x + v.x, r.y + v.y, r.w, r.h }
}

rect_scaled_from_center :: #force_inline proc (r: Rect, scale: Vec2) -> Rect {
    w := r.w * scale.x
    h := r.h * scale.y
    return { r.x+w/2, r.y+h/2, w, h }
}

rect_scaled_from_top_left :: #force_inline proc (r: Rect, scale: Vec2) -> Rect {
    return { r.x, r.y, r.w*scale.x, r.h*scale.y }
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

rect_equal_approx :: #force_inline proc (a: Rect, b: Rect, e := f32(.5)) -> bool {
    return abs(a.x-b.x)<e && abs(a.y-b.y)<e && abs(a.w-b.w)<e && abs(a.h-b.h)<e
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

clamp_ratio_span :: #force_inline proc (value, minimum, span: $T) -> T where intrinsics.type_is_float(T) {
    return clamp((value - minimum) / span, 0.0, 1.0)
}

random_vec_in_rect :: #force_inline proc (rect: Rect) -> Vec2 {
    return { rect.x + rect.w*rand.float32(), rect.y + rect.h*rand.float32() }
}

random_vec_in_ring :: #force_inline proc (inner_radius, outer_radius: f32) -> Vec2 {
    dir := linalg.normalize0(Vec2 { rand.float32()*2 - 1, rand.float32()*2 - 1 })
    return dir * rand.float32_range(inner_radius, outer_radius)
}

vec_on_circle :: #force_inline proc (radius, angle_rad: f32) -> Vec2 {
    return { radius * math.cos(angle_rad), radius * math.sin(angle_rad) }
}

vec_moved_towards_vec :: #force_inline proc (current_vec, target_vec: Vec2, speed, dt: f32) -> (new_vec: Vec2) {
    dir := linalg.normalize0(target_vec - current_vec)
    return current_vec + dir * speed * dt
}

vec_orbited_around_vec :: #force_inline proc (vec, center_vec: Vec2, speed, dt: f32, is_clockwise := true) -> (new_vec: Vec2) {
    radius := linalg.distance(center_vec, vec)
    angle := linalg.atan2(vec.y-center_vec.y, vec.x-center_vec.x)
    angular_vel := speed / radius
    new_angle := is_clockwise\
        ?  angle + angular_vel * dt\
        : -angle + angular_vel * dt
    return center_vec + vec_on_circle(radius, new_angle)
}

fit_target_size :: #force_inline proc (screen: Vec2, target: Vec2) -> (scale: f32, render: Rect) {
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
