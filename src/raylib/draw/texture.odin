package spacelib_raylib_draw

import rl "vendor:raylib"
import "../../core"

texture :: proc (tex: rl.Texture, src, dst: Rect, origin := Vec2 {}, rot_degree := f32(0), tint := core.white) {
    src_rl := transmute (rl.Rectangle) src
    dst_rl := transmute (rl.Rectangle) dst
    tint_rl := rl.Color(tint)
    rl.DrawTexturePro(tex, src_rl, dst_rl, origin, rot_degree, tint_rl)
}

texture_wrap :: proc (tex: rl.Texture, src, dst: Rect, tint := core.white) {
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

texture_npatch :: proc (tex: rl.Texture, info: rl.NPatchInfo, dst: Rect, origin := Vec2 {}, rot_degree := f32(0), tint := Color {255,255,255,255}) {
    dst_rl := transmute (rl.Rectangle) dst
    tint_rl := rl.Color(tint)
    rl.DrawTextureNPatch(tex, info, dst_rl, origin, rot_degree, tint_rl)
}
