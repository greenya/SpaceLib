package sprites

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:raylib/res"

@private atlas: ^res.Atlas

texture :: proc () -> rl.Texture { return atlas.texture }

create :: proc (scale := f32(1), filter := rl.TextureFilter.BILINEAR) {
    assert(atlas == nil)
    atlas = res.gen_atlas_from_files(
        files   = #load_directory("./"),
        scale   = scale,
        filter  = filter,
    )
}

destroy :: proc () {
    res.destroy_atlas(atlas)
    atlas = nil
}

get :: proc (name: string) -> ^res.Sprite {
    fmt.assertf(name in atlas.sprites, "Unknown sprite: \"%s\"", name)
    return atlas.sprites[name]
}
