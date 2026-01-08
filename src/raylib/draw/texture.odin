package spacelib_raylib_draw

import "core:math"
import rl "vendor:raylib"
import "../../core"

texture :: proc (
    tex     : rl.Texture,
    dst     : Rect,
    src     : Rect,
    tint    := core.white,
) {
    dst_rl := transmute (rl.Rectangle) dst
    src_rl := transmute (rl.Rectangle) src
    tint_rl := rl.Color(tint)
    rl.DrawTexturePro(tex, src_rl, dst_rl, {}, 0, tint_rl)
}

texture_fit :: proc (
    tex     : rl.Texture,
    dst     : Rect,
    src     : Rect,
    fit     : core.Rect_Fit,
    tint    := core.white,
) {
    fit_rect, _ := core.fit_size_into_rect({src.w,src.h}, dst, fit)
    dst_rl := transmute (rl.Rectangle) fit_rect
    src_rl := transmute (rl.Rectangle) src
    tint_rl := rl.Color(tint)
    rl.DrawTexturePro(tex, src_rl, dst_rl, {}, 0, tint_rl)
}

texture_rot :: proc (
    tex         : rl.Texture,
    dst         : Rect,
    src         : Rect,
    origin_uv   := Vec2 {},
    rot_rad     := f32(0),
    tint        := core.white,
) {
    dst_rl := transmute (rl.Rectangle) dst
    src_rl := transmute (rl.Rectangle) src
    origin := Vec2 { origin_uv.x * dst.w, origin_uv.y * abs(dst.h) } // abs() for possible render target texture flipped h
    dst_rl.x += origin.x
    dst_rl.y += origin.y
    rot_deg := math.to_degrees(rot_rad)
    tint_rl := rl.Color(tint)
    rl.DrawTexturePro(tex, src_rl, dst_rl, origin, rot_deg, tint_rl)
}

texture_wrap :: proc (
    tex     : rl.Texture,
    dst     : Rect,
    src     : Rect,
    tint    := core.white,
) {
    is_whole_tex_used := src.x == 0 && src.y == 0 && i32(src.w) == tex.width && i32(src.h) == tex.height
    if is_whole_tex_used {
        texture(tex, dst, Rect { 0, 0, dst.w, dst.h }, tint=tint)
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

texture_patch :: proc (
    tex     : rl.Texture,
    dst     : Rect,
    info    : rl.NPatchInfo,
    origin  := Vec2 {},
    rot_rad := f32(0),
    tint    := core.white,
) {
    dst_rl := transmute (rl.Rectangle) dst
    rot_deg := 90 + math.to_degrees(rot_rad)
    tint_rl := rl.Color(tint)
    rl.DrawTextureNPatch(tex, info, dst_rl, origin, rot_deg, tint_rl)
}

texture_all :: proc (
    tex         : rl.Texture,
    dst         : Rect,
    flip_src_h  := false,
    tint        := core.white,
) {
    dst_rl := transmute (rl.Rectangle) dst
    src_rl := rl.Rectangle { 0, 0, f32(tex.width), f32(tex.height) }
    if flip_src_h do src_rl.height = -src_rl.height
    tint_rl := rl.Color(tint)
    rl.DrawTexturePro(tex, src_rl, dst_rl, {}, 0, tint_rl)
}
