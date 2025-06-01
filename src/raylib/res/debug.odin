package spacelib_raylib_res

import "core:fmt"
import rl "vendor:raylib"
import "../../core"
import "../draw"

@private Vec2 :: core.Vec2
@private Rect :: core.Rect

debug_draw_texture :: proc (res: ^Res, name: string, pos: Vec2, scale := f32(1)) {
    assert(name in res.textures)

    tex := res.textures[name]
    rect := Rect { pos.x, pos.y, f32(tex.width)*scale, f32(tex.height)*scale }
    rl.DrawTextureEx(tex.texture_rl, pos, 0, scale, rl.WHITE)

    br_color := core.Color {255,255,0,255}
    tx_color := core.Color {0,0,0,255}
    text := fmt.tprintf("%s: %ix%i // mipmaps: %i", name, tex.width, tex.height, tex.mipmaps)

    draw.rect_lines(rect, 1, br_color)
    draw.rect(core.rect_moved(core.rect_line_top(rect, 14), {0,-14}), br_color)
    draw.text(text, pos+{4,-11}, rl.GetFontDefault(), 10, 1, tx_color)
}
