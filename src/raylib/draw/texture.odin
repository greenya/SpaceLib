package spacelib_raylib_draw

import "core:math"
import rl "vendor:raylib"
import "../../core"

// https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit
Texture_Fit :: enum {
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

// extra alignment for .contain and .cover only
Texture_Fit_Align :: enum {
    center,
    start,
    end,
}

texture :: proc (
    tex         : rl.Texture,
    src         : Rect,
    dst         : Rect,
    fit         := Texture_Fit.fill,
    fit_align   := Texture_Fit_Align.center,
    tint        := core.white,
) {
    src := src
    dst := dst

    if fit != .fill {
        fit_src_to_dst(&src, &dst, fit, fit_align)
    }

    src_rl := transmute (rl.Rectangle) src
    dst_rl := transmute (rl.Rectangle) dst
    tint_rl := rl.Color(tint)
    rl.DrawTexturePro(tex, src_rl, dst_rl, {}, 0, tint_rl)
}

texture_full :: proc (
    tex     : rl.Texture,
    dst     : Rect,
    tint    := core.white,
) {
    src_rl := rl.Rectangle { 0, 0, f32(tex.width), f32(tex.height) }
    dst_rl := transmute (rl.Rectangle) dst
    tint_rl := rl.Color(tint)
    rl.DrawTexturePro(tex, src_rl, dst_rl, {}, 0, tint_rl)
}

texture_rot :: proc (
    tex         : rl.Texture,
    src         : Rect,
    dst         : Rect,
    origin_uv   := Vec2 {},
    rot_rad     := f32(0),
    tint        := core.white,
) {
    src_rl := transmute (rl.Rectangle) src
    dst_rl := transmute (rl.Rectangle) dst
    origin := Vec2 { origin_uv.x * src.w, origin_uv.y * src.h }
    rot_deg := 90 + math.to_degrees(rot_rad)
    tint_rl := rl.Color(tint)
    rl.DrawTexturePro(tex, src_rl, dst_rl, origin, rot_deg, tint_rl)
}

texture_wrap :: proc (
    tex     : rl.Texture,
    src     : Rect,
    dst     : Rect,
    tint    := core.white,
) {
    is_whole_tex_used := src.x == 0 && src.y == 0 && i32(src.w) == tex.width && i32(src.h) == tex.height
    if is_whole_tex_used {
        texture(tex, Rect { 0, 0, dst.w, dst.h }, dst, tint=tint)
        return
    }

    tint_rl := rl.Color(tint)

    for dy := f32(0); dy < dst.h; dy += src.h {
        for dx := f32(0); dx < dst.w; dx += src.w {
            tile_w, tile_h := src.w, src.h
            if dx + tile_w > dst.w do tile_w = dst.w-dx
            if dy + tile_h > dst.h do tile_h = dst.h-dy

            rl.DrawTexturePro(
                tex,
                rl.Rectangle { src.x, src.y, tile_w, tile_h },
                rl.Rectangle { dst.x+dx, dst.y+dy, tile_w, tile_h },
                {}, 0, tint_rl,
            )
        }
    }
}

// TODO: change "rot_deg" to "rot_rad"
texture_npatch :: proc (
    tex     : rl.Texture,
    info    : rl.NPatchInfo,
    dst     : Rect,
    origin  := Vec2 {},
    rot_deg := f32(0),
    tint    := core.white,
) {
    dst_rl := transmute (rl.Rectangle) dst
    tint_rl := rl.Color(tint)
    rl.DrawTextureNPatch(tex, info, dst_rl, origin, rot_deg, tint_rl)
}

@private
fit_src_to_dst :: #force_inline proc (src, dst: ^Rect, fit: Texture_Fit, fit_align: Texture_Fit_Align) {
    if src.w < 1 || src.h < 1 || dst.w < 1 || dst.h < 1 do return

    switch fit {
    case .fill:
        // nothing to do

    case .contain:
        src_aspect := src.w/src.h
        dst_aspect := dst.w/dst.h
        if dst_aspect > src_aspect {
            dst_w := dst.w / dst_aspect
            switch fit_align {
            case .center    : dst.x += (dst.w-dst_w)/2
            case .start     : // already aligned
            case .end       : dst.x += dst.w-dst_w
            }
            dst.w = dst_w
        } else {
            dst_h := dst.h * dst_aspect
            switch fit_align {
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
            switch fit_align {
            case .center    : src.x += (src.w-src_w)/2
            case .start     : // already aligned
            case .end       : src.x += src.w-src_w
            }
            src.w = src_w
        } else {
            src_h := src.h / dst_aspect
            switch fit_align {
            case .center    : src.y += (src.h-src_h)/2
            case .start     : // already aligned
            case .end       : src.y += src.h-src_h
            }
            src.h = src_h
        }

    case .none:
        dst_center := core.rect_center(dst^)
        src_proj := core.rect_from_center(dst_center, { src.w, src.h })
        dst_proj := core.rect_intersection(dst^, src_proj)

        proj_dh := (src.h-dst_proj.h)/2
        proj_dx := (src.w-dst_proj.w)/2
        dst^ = core.rect_inflated(dst_proj, {proj_dx,proj_dh})

        off_w_half_neg := min(0, (dst_proj.w-src.w)/2)
        off_h_half_neg := min(0, (dst_proj.h-src.h)/2)
        if off_w_half_neg < 0 || off_h_half_neg < 0 {
            off_size := Vec2 { off_w_half_neg, off_h_half_neg }
            src^ = core.rect_inflated(src^, off_size)
            dst^ = core.rect_inflated(dst^, off_size)
        }
    }
}
