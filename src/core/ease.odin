package spacelib_core

import "core:math/ease"

Ease :: ease.Ease

ease_ratio :: #force_inline proc "contextless" (ratio: $T, easing: Ease) -> T {
    return #force_inline ease.ease(easing, ratio)
}

ease_vec :: proc (from, to: Vec2, ratio: f32, easing: Ease = .Linear) -> Vec2 {
    ratio := easing != .Linear ? #force_inline ease.ease(easing, ratio) : ratio
    return {
        from.x + (to.x - from.x) * ratio,
        from.y + (to.y - from.y) * ratio,
    }
}

ease_rect :: proc (from, to: Rect, ratio: f32, easing := Ease.Linear) -> Rect {
    ratio := easing != .Linear ? #force_inline ease.ease(easing, ratio) : ratio
    return {
        from.x + (to.x - from.x) * ratio,
        from.y + (to.y - from.y) * ratio,
        from.w + (to.w - from.w) * ratio,
        from.h + (to.h - from.h) * ratio,
    }
}

ease_color :: proc (from, to: Color, ratio: f32, easing := Ease.Linear) -> Color {
    ratio := easing != .Linear ? #force_inline ease.ease(easing, ratio) : ratio
    return {
        from[0] + u8(f32(to[0] - from[0]) * ratio),
        from[1] + u8(f32(to[1] - from[1]) * ratio),
        from[2] + u8(f32(to[2] - from[2]) * ratio),
        from[3] + u8(f32(to[3] - from[3]) * ratio),
    }
}
