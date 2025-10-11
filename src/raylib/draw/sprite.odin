package spacelib_raylib_draw

import "../../core"
import "../res"

@private Sprite :: res.Sprite
@private Patch :: res.Patch

sprite :: proc (spr: ^Sprite, rect: Rect, tint := core.white) {
    switch info in spr.info {
    case Rect   : if spr.wrap   do texture_wrap     (spr.texture, rect, info, tint=tint)
                  else          do texture          (spr.texture, rect, info, tint=tint)
    case Patch  :                  texture_patch    (spr.texture, rect, info, tint=tint)
    }
}
