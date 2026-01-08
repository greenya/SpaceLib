package spacelib_core

// Aspect-ratio aware scaling fit similar to [object-fit in CSS](https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit).
// Used with `fit_size_into_rect()`.
//
// - `contain_*`: resulting `fit_rect` will be fully inside `dst_rect` and some parts
// of the dst will not be covered in case aspect ratios are different.
//
// - `cover_*`: resulting `fit_rect` will be fully covering `dst_rect` and some parts
// of the src will be outside of the dst in case aspect ratios are different.
//
// - `*_start`, `*_center`, `*_end`: the alignment, defines part of dst to stick to.
Rect_Fit :: enum {
    contain_start,
    contain_center,
    contain_end,
    cover_start,
    cover_center,
    cover_end,
}

@require_results
fit_size_into_rect :: proc (src_size: Vec2, dst_rect: Rect, fit: Rect_Fit) -> (fit_rect: Rect, fit_scale: f32) {
    switch fit {
    case .contain_start, .contain_center, .contain_end:
        fit_scale = min(dst_rect.w/src_size.x, dst_rect.h/src_size.y)
    case .cover_start, .cover_center, .cover_end:
        fit_scale = max(dst_rect.w/src_size.x, dst_rect.h/src_size.y)
    }

    fit_rect.w = src_size.x * fit_scale
    fit_rect.h = src_size.y * fit_scale

    switch fit {
    case .contain_start, .cover_start:
        fit_rect.x = dst_rect.x
        fit_rect.y = dst_rect.y
    case .contain_center, .cover_center:
        fit_rect.x = dst_rect.x + (dst_rect.w - fit_rect.w)/2
        fit_rect.y = dst_rect.y + (dst_rect.h - fit_rect.h)/2
    case .contain_end, .cover_end:
        fit_rect.x = dst_rect.x + (dst_rect.w - fit_rect.w)
        fit_rect.y = dst_rect.y + (dst_rect.h - fit_rect.h)
    }

    return
}
