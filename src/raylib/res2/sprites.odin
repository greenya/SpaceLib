package spacelib_raylib_res2

import rl "vendor:raylib"

Sprite :: struct {
    wrap    : bool,
    texture : Texture,
    info    : union { Rect, NPatch },
}

Texture :: rl.Texture
NPatch  :: rl.NPatchInfo

create_sprite :: proc (init: Sprite) -> ^Sprite {
    sprite := new(Sprite)
    sprite^ = init
    return sprite
}

destroy_sprite :: proc (sprite: ^Sprite) {
    if sprite == nil do return
    free(sprite)
}

destroy_texture :: proc (texture: Texture) {
    rl.UnloadTexture(texture)
}
