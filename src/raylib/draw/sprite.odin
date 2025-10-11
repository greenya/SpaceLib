package spacelib_raylib_draw

import "../../core"
import "../res"

@private Sprite :: res.Sprite
@private Patch :: res.Patch

sprite :: proc (spr: ^Sprite, rect: Rect, flip_src_w := false, tint := core.white) {
    switch info in spr.info {
    case Rect:
        if spr.wrap {
            texture_wrap(spr.texture, rect, info, tint=tint)
        } else {
            i := info
            if flip_src_w do i.w = -i.w
            texture(spr.texture, rect, i, tint=tint)
        }
    case Patch:
        texture_patch(spr.texture, rect, info, tint=tint)
    }
}
