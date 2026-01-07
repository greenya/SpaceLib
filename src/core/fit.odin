package spacelib_core

// Similar to https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit
Rect_Fit :: enum {
    // aspect-ratio unaware scaling fit:
    // - src fills dst
    fill,

    // aspect-ratio aware scaling fit:
    // - whole src will be shown inside dst
    // - the align defines part of dst to stick to
    contain,

    // aspect-ratio aware scaling fit:
    // - whole dst gets covered by src
    // - the align defines which part of src should stay in dst (will not be truncated)
    cover,

    // aspect-ratio aware unscaling fit:
    // - src placed in the center of dst
    // - src parts get truncated when outside of dst
    none,
}

// Extra alignment for `.contain` and `.cover` only
Rect_Fit_Align :: enum {
    center,
    start,
    end,
}

fit_rect_src_into_dst :: #force_inline proc (src, dst: ^Rect, fit: Rect_Fit, align := Rect_Fit_Align.center) {
    if src.w<1 || src.h<1 || dst.w<1 || dst.h<1 do return

    switch fit {
    case .fill:
        // nothing to do

    case .contain:
        src_aspect := src.w/src.h
        dst_aspect := dst.w/dst.h
        if dst_aspect > src_aspect {
            dst_w := dst.w / dst_aspect
            switch align {
            case .center    : dst.x += (dst.w-dst_w)/2
            case .start     : // already aligned
            case .end       : dst.x += dst.w-dst_w
            }
            dst.w = dst_w
        } else {
            dst_h := dst.h * dst_aspect
            switch align {
            case .center    : dst.y += (dst.h-dst_h)/2
            case .start     : // already aligned
            case .end       : dst.y += dst.h-dst_h
            }
            dst.h = dst_h
        }

    case .cover:
        src_aspect := src.w/src.h
        dst_aspect := dst.w/dst.h
        if src_aspect > dst_aspect {
            src_w := src.w * dst_aspect
            switch align {
            case .center    : src.x += (src.w-src_w)/2
            case .start     : // already aligned
            case .end       : src.x += src.w-src_w
            }
            src.w = src_w
        } else {
            src_h := src.h / dst_aspect
            switch align {
            case .center    : src.y += (src.h-src_h)/2
            case .start     : // already aligned
            case .end       : src.y += src.h-src_h
            }
            src.h = src_h
        }

    case .none:
        dst_center := rect_center(dst^)
        src_proj := rect_from_center(dst_center, { src.w, src.h })
        dst_proj := rect_intersection(dst^, src_proj)

        proj_dh := (src.h-dst_proj.h)/2
        proj_dx := (src.w-dst_proj.w)/2
        dst^ = rect_inflated(dst_proj, {proj_dx,proj_dh})

        off_w_half_neg := min(0, (dst_proj.w-src.w)/2)
        off_h_half_neg := min(0, (dst_proj.h-src.h)/2)
        if off_w_half_neg < 0 || off_h_half_neg < 0 {
            off_size := Vec2 { off_w_half_neg, off_h_half_neg }
            src^ = rect_inflated(src^, off_size)
            dst^ = rect_inflated(dst^, off_size)
        }
    }
}

// renamed from fit_target_size()
//
// TODO: remove, it as it should be easily achievable with:
//
//      new_src_rect := fit_rect_to_rect(
//          src={0,0,target_size.x,target_size.y},
//          dst={0,0,screen_size.x,screen_size.y},
//          fit=.contain,
//          align=.center,
//      )
//
// or keep as a shortcut.
fit_size_into_rect :: proc (src_size: Vec2, dst_rect: Rect) -> (fit_rect: Rect, fit_scale: f32) {
    fit_scale = min(dst_rect.w/src_size.x, dst_rect.h/src_size.y)
    fit_w := src_size.x * fit_scale
    fit_h := src_size.y * fit_scale
    fit_rect = {
        dst_rect.x + (dst_rect.w - fit_w)/2,
        dst_rect.y + (dst_rect.h - fit_h)/2,
        fit_w,
        fit_h,
    }
    return
}
