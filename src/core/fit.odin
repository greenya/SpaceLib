package spacelib_core

Fit_Strategy :: enum {
    contain_start,
    contain_center,
    contain_end,
    cover_start,
    cover_center,
    cover_end,
}

// Aspect-ratio aware scaling fit similar to [object-fit in CSS](https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit).
// - `src_size` Source size, for example render target texture size, e.g. {320,180}
// - `dest_rect` Destination area, for example current screen rect, e.g. {0,0,1000,600}
// - `fit` Strategy:
//      - `contain_*`: resulting `fit_rect` will be fully inside `dest_rect` and some parts
//        of the dest will not be covered in case aspect ratios are different.
//      - `cover_*`: resulting `fit_rect` will be fully covering `dest_rect` and some parts
//        of the src will be outside of the dest in case aspect ratios are different.
//      - `*_start`, `*_center`, `*_end`: the alignment, defines part of dest to stick to.
@require_results
fit_size_into_rect :: proc (src_size: Vec2, dest_rect: Rect, fit: Fit_Strategy) -> (fit_rect: Rect, fit_scale: f32) {
    switch fit {
    case .contain_start, .contain_center, .contain_end:
        fit_scale = min(dest_rect.w/src_size.x, dest_rect.h/src_size.y)
    case .cover_start, .cover_center, .cover_end:
        fit_scale = max(dest_rect.w/src_size.x, dest_rect.h/src_size.y)
    }

    fit_rect.w = src_size.x * fit_scale
    fit_rect.h = src_size.y * fit_scale

    switch fit {
    case .contain_start, .cover_start:
        fit_rect.x = dest_rect.x
        fit_rect.y = dest_rect.y
    case .contain_center, .cover_center:
        fit_rect.x = dest_rect.x + (dest_rect.w - fit_rect.w)/2
        fit_rect.y = dest_rect.y + (dest_rect.h - fit_rect.h)/2
    case .contain_end, .cover_end:
        fit_rect.x = dest_rect.x + (dest_rect.w - fit_rect.w)
        fit_rect.y = dest_rect.y + (dest_rect.h - fit_rect.h)
    }

    return
}
