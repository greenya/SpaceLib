package spacelib_core

import "base:intrinsics"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

Vec2 :: [2] f32
Vec3 :: [3] f32
Rect :: struct { x, y, w, h: f32 }

rect_xywh :: #force_inline proc (r: Rect) -> (x, y, w, h: f32) { return r.x, r.y, r.w, r.h }
rect_ltrb :: #force_inline proc (r: Rect) -> (left, top, right, bottom: f32) { return r.x, r.y, r.x+r.w, r.y+r.h }

rect_top_left       :: #force_inline proc (r: Rect) -> Vec2 { return { r.x, r.y } }
rect_top            :: #force_inline proc (r: Rect) -> Vec2 { return { r.x+r.w/2, r.y } }
rect_top_right      :: #force_inline proc (r: Rect) -> Vec2 { return { r.x+r.w, r.y } }
rect_left           :: #force_inline proc (r: Rect) -> Vec2 { return { r.x, r.y+r.h/2 } }
rect_center         :: #force_inline proc (r: Rect) -> Vec2 { return { r.x+r.w/2, r.y+r.h/2 } }
rect_right          :: #force_inline proc (r: Rect) -> Vec2 { return { r.x+r.w, r.y+r.h/2 } }
rect_bottom_left    :: #force_inline proc (r: Rect) -> Vec2 { return { r.x, r.y + r.h } }
rect_bottom         :: #force_inline proc (r: Rect) -> Vec2 { return { r.x+r.w/2, r.y + r.h } }
rect_bottom_right   :: #force_inline proc (r: Rect) -> Vec2 { return { r.x+r.w, r.y+r.h } }

rect_half_left      :: #force_inline proc (r: Rect) -> Rect { return { r.x, r.y, r.w/2, r.h } }
rect_half_right     :: #force_inline proc (r: Rect) -> Rect { return { r.x+r.w/2, r.y, r.w/2, r.h } }
rect_half_top       :: #force_inline proc (r: Rect) -> Rect { return { r.x, r.y, r.w, r.h/2 } }
rect_half_bottom    :: #force_inline proc (r: Rect) -> Rect { return { r.x, r.y+r.h/2, r.w, r.h/2 } }

rect_bar_top                :: #force_inline proc (r: Rect, thick: f32) -> Rect { return { r.x, r.y, r.w, thick } }
rect_bar_bottom             :: #force_inline proc (r: Rect, thick: f32) -> Rect { return { r.x, r.y+r.h-thick, r.w, thick } }
rect_bar_left               :: #force_inline proc (r: Rect, thick: f32) -> Rect { return { r.x, r.y, thick, r.h } }
rect_bar_right              :: #force_inline proc (r: Rect, thick: f32) -> Rect { return { r.x+r.w-thick, r.y, thick, r.h } }
rect_bar_center_horizontal  :: #force_inline proc (r: Rect, thick: f32) -> Rect { return { r.x, r.y+(r.h-thick)/2, r.w, thick } }
rect_bar_center_vertical    :: #force_inline proc (r: Rect, thick: f32) -> Rect { return { r.x+(r.w-thick)/2, r.y, thick, r.h } }

rect_move :: #force_inline proc (r: ^Rect, v: Vec2) {
    r.x += v.x
    r.y += v.y
}

rect_moved :: #force_inline proc (r: Rect, v: Vec2) -> Rect {
    return { r.x+v.x, r.y+v.y, r.w, r.h }
}

rect_inflate :: #force_inline proc (r: ^Rect, size: Vec2) {
    r.x -= size.x
    r.y -= size.y
    r.w += 2*size.x
    r.h += 2*size.y
}

rect_inflated :: #force_inline proc (r: Rect, size: Vec2) -> Rect {
    return { r.x-size.x, r.y-size.y, r.w+2*size.x, r.h+2*size.y }
}

rect_padded :: #force_inline proc (r: Rect, left, right, top, bottom: f32) -> Rect {
    return { r.x+left, r.y+top, r.w-left-right, r.h-top-bottom }
}

rect_padded_horizontal :: #force_inline proc (r: Rect, left, right: f32) -> Rect {
    return { r.x+left, r.y, r.w-left-right, r.h }
}

rect_padded_vertical :: #force_inline proc (r: Rect, top, bottom: f32) -> Rect {
    return { r.x, r.y+top, r.w, r.h-top-bottom }
}

// `r` is treated as `1x1` area, where `top_left_ratio` and `bottom_right_ratio` are
// essentially coordinates on that area (similar to texture uv coordinates);
// examples:
// - `0,1` -- whole rect (same input rect)
// - `{0,.5},{.5,1}` -- bottom left quarter of the rect
// - `.333,.667` -- middle 1/9 of the rect, if we imagine 3x3 rect
rect_fraction :: #force_inline proc (r: Rect, top_left_ratio, bottom_right_ratio: Vec2) -> Rect {
    dx1 := r.w * top_left_ratio.x
    dy1 := r.h * top_left_ratio.y
    dx2 := r.w * bottom_right_ratio.x
    dy2 := r.h * bottom_right_ratio.y
    return { r.x+dx1, r.y+dy1, dx2-dx1, dy2-dy1 }
}

rect_fraction_horizontal :: #force_inline proc (r: Rect, left_ratio, right_ratio: f32) -> Rect {
    dx1 := r.w * left_ratio
    dx2 := r.w * right_ratio
    return { r.x+dx1, r.y, dx2-dx1, r.h }
}

rect_fraction_vertical :: #force_inline proc (r: Rect, top_ratio, bottom_ratio: f32) -> Rect {
    dy1 := r.h * top_ratio
    dy2 := r.h * bottom_ratio
    return { r.x, r.y+dy1, r.w, dy2-dy1 }
}

rect_scaled :: #force_inline proc (r: Rect, scale: Vec2) -> Rect {
    w := r.w * scale.x
    h := r.h * scale.y
    dx := (r.w-w)/2
    dy := (r.h-h)/2
    return { r.x+dx, r.y+dy, w, h }
}

rect_scaled_top_left    :: #force_inline proc (r: Rect, s: Vec2) -> Rect { return { r.x, r.y, r.w*s.x, r.h*s.y } }
rect_scaled_top_right   :: #force_inline proc (r: Rect, s: Vec2) -> Rect { return { r.x+r.w*(1-s.x), r.y, r.w*s.x, r.h*s.y } }
rect_scaled_bottom_left :: #force_inline proc (r: Rect, s: Vec2) -> Rect { return { r.x, r.y+r.h*(1-s.y), r.w*s.x, r.h*s.y } }
rect_scaled_bottom_right:: #force_inline proc (r: Rect, s: Vec2) -> Rect { return { r.x+r.w*(1-s.x), r.y+r.h*(1-s.y), r.w*s.x, r.h*s.y } }

rect_from_size      :: #force_inline proc (size: Vec2)          -> Rect { return { 0, 0, size.x, size.y } }
rect_from_center    :: #force_inline proc (v: Vec2, size: Vec2) -> Rect { return { v.x-size.x/2, v.y-size.y/2, size.x, size.y } }
rect_from_top_left  :: #force_inline proc (v: Vec2, size: Vec2) -> Rect { return { v.x, v.y, size.x, size.y } }

rect_grow :: #force_inline proc (r: ^Rect, o: Rect) {
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
    if x2 >= x1 {
        y1 := max(a.y, b.y)
        y2 := min(a.y+a.h, b.y+b.h)
        if y2 >= y1 {
            return { x1, y1, x2-x1, y2-y1 }
        }
    }
    return {}
}

rects_intersect :: #force_inline proc (a: Rect, b: Rect) -> bool {
    x1 := max(a.x, b.x)
    x2 := min(a.x+a.w, b.x+b.w)
    if x2 >= x1 {
        y1 := max(a.y, b.y)
        y2 := min(a.y+a.h, b.y+b.h)
        if y2 >= y1 {
            return true
        }
    }
    return false
}

rect_offset_into_view :: proc (r: Rect, v: Rect) -> (offset: Vec2) {
    if r.w <= v.w {
        r_x2 := r.x + r.w
        v_x2 := v.x + v.w
        if r.x < v.x        do offset.x = v.x - r.x
        else if r_x2 > v_x2 do offset.x = v_x2 - r_x2
    }

    if r.h <= v.h {
        r_y2 := r.y + r.h
        v_y2 := v.y + v.h
        if r.y < v.y        do offset.y = v.y - r.y
        else if r_y2 > v_y2 do offset.y = v_y2 - r_y2
    }

    return
}

rect_equal_approx :: #force_inline proc (a: Rect, b: Rect, e: f32) -> bool {
    return abs(a.x-b.x)<e && abs(a.y-b.y)<e && abs(a.w-b.w)<e && abs(a.h-b.h)<e
}

vec_equal_approx :: #force_inline proc (a: Vec2, b: Vec2, e: f32) -> bool {
    return abs(a.x-b.x)<e && abs(a.y-b.y)<e
}

vec_zero_approx :: #force_inline proc (a: Vec2, e: f32) -> bool {
    return abs(a.x)<e && abs(a.y)<e
}

vec_in_rect :: #force_inline proc (vec: Vec2, r: Rect) -> bool {
    return r.x<vec.x && r.x+r.w>vec.x && r.y<vec.y && r.y+r.h>vec.y
}

vec_in_ring :: #force_inline proc (vec: Vec2, center: Vec2, inner_radius, outer_radius, start_rad, end_rad: f32) -> bool {
    dir := vec - center

    dist := math.hypot(dir.x, dir.y)
    if dist < inner_radius || dist > outer_radius {
        return false
    }

    ang := math.atan2(-dir.y, dir.x) // "-Y" because Y axis grows down
    ang = norm(ang)
    s := norm(start_rad)
    e := norm(end_rad)

    return s <= e\
        ? s <= ang && ang <= e\
        : ang >= s || ang <= e

    norm :: proc (a: f32) -> f32 {
        a := a
        for a < 0           do a += 2*math.PI
        for a >= 2*math.PI  do a -= 2*math.PI
        return a
    }
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

random_vec_sway :: #force_inline proc (dir: Vec2, sway_side_rad: f32) -> Vec2 {
    if sway_side_rad == 0 do return dir
    assert(sway_side_rad > 0)
    d := rand.float32_range(-sway_side_rad, +sway_side_rad)
    cos_d := math.cos(d)
    sin_d := math.sin(d)
    return {
        dir.x*cos_d - dir.y*sin_d,
        dir.x*sin_d + dir.y*cos_d,
    }
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

vec_on_rotated_rect :: #force_inline proc (rect: Rect, origin_uv: Vec2, rot_rad: f32, target_uv: Vec2) -> Vec2 {
    ox, oy := origin_uv.x, origin_uv.y
    u, v := target_uv.x, target_uv.y

    px := u * rect.w
    py := v * rect.h
    oxp := ox * rect.w
    oyp := oy * rect.h

    rx := px - oxp
    ry := py - oyp

    cos_a := math.cos(-rot_rad)
    sin_a := math.sin(-rot_rad)
    rpx := rx * cos_a - ry * sin_a
    rpy := rx * sin_a + ry * cos_a

    wx := rect.x + oxp + rpx
    wy := rect.y + oyp + rpy
    return { wx, wy }
}

// Returns angle in radians between -PI to PI, where 0 is {1,0}.
//
// Note: This is close to `core:math/linalg.angle_between(vec, {1,0})`, which returns
//       the smallest angle and result is never full circle, but a semi-circle, e.g. from 0 to PI.
vec_angle :: #force_inline proc (vec: Vec2) -> f32 {
    return math.atan2(-vec.y, vec.x)
}

lines_intersection :: proc (start1, end1, start2, end2: Vec2) -> (pos: Vec2, ok: bool) {
    r := end1 - start1
    s := end2 - start2
    rxs := linalg.cross(r, s)

    if abs(rxs) < .000001 do return

    qp := start2 - start1
    t := linalg.cross(qp, s) / rxs
    u := linalg.cross(qp, r) / rxs

    if t<0 || t>1 || u<0 || u>1 do return

    return start1 + r*t, true
}

fit_target_size :: #force_inline proc (screen_size: Vec2, target_size: Vec2) -> (render_scale: f32, render_rect: Rect) {
    render_scale = min(screen_size.x/target_size.x, screen_size.y/target_size.y)
    render_w, render_h := target_size.x*render_scale, target_size.y*render_scale
    return render_scale, {
        (screen_size.x - render_w)/2,
        (screen_size.y - render_h)/2,
        render_w,
        render_h,
    }
}
