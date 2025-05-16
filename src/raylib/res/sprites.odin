package spacelib_raylib_res

// TODO: add support for 9-patch (and 3-patch) sprites: "arrow.np.png" ("arrow.tpv.png", "arrow.tph.png")

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import "../../core"

Sprite :: struct {
    name    : string,
    texture : string,
    info    : rl.Rectangle,
    // info: union {
    //     rl.Rectangle,
    //     rl.NPatchInfo,
    // },
}

Texture :: struct {
    name: string,
    using texture_rl: rl.Texture,
}

reload_sprites :: proc (res: ^Res) {
    destroy_sprites_and_textures(res)
    gen_atlas_texture(res, "sprites", { 512, 512 }, .TRILINEAR)
}

@private
destroy_sprites_and_textures :: proc (res: ^Res) {
    for _, &sprite in res.sprites {
        delete(sprite.name)
        free(sprite)
    }

    delete(res.sprites)
    res.sprites = nil

    for _, &texture in res.textures {
        rl.UnloadTexture(texture.texture_rl)
        free(texture)
    }

    delete(res.textures)
    res.textures = nil
}

@private
gen_atlas_texture :: proc (res: ^Res, name: string, size: [2] int, filter: rl.TextureFilter) {
    atlas := rl.GenImageColor(i32(size.x), i32(size.y), {})
    gap :: 2
    pos_x, pos_y, max_h := i32(gap), i32(gap), i32(0)

    file_ext :: ".png"
    for file_name in core.map_keys_sorted(res.files, context.temp_allocator) {
        if !strings.ends_with(file_name, file_ext) do continue

        file := res.files[file_name]
        image := rl.LoadImageFromMemory(file_ext, raw_data(file.data), i32(len(file.data)))

        if pos_x+image.width > atlas.width-1 {
            pos_x = gap
            pos_y += gap+max_h
            max_h = 0
        }

        if pos_x+image.width > atlas.width-1 || pos_y+image.height > atlas.height-1 {
            fmt.eprintfln("[!] Generate atlas texture failed: unable to fit \"%s\"", file_name)
        }

        src_rect := rl.Rectangle { 0, 0, f32(image.width), f32(image.height) }
        dst_rect := rl.Rectangle { f32(pos_x), f32(pos_y), f32(image.width), f32(image.height) }
        rl.ImageDraw(&atlas, image, src_rect, dst_rect, rl.WHITE)

        pos_x += image.width + gap
        max_h = max(max_h, image.height)

        rl.UnloadImage(image)

        sprite := new(Sprite)
        sprite.name = strings.clone(file_name[:strings.index_byte(file_name, '.')])
        sprite.texture = name
        sprite.info = dst_rect

        res.sprites[sprite.name] = sprite
    }

    atlas_texture := rl.LoadTextureFromImage(atlas)
    rl.UnloadImage(atlas)

    if filter != .POINT {
        rl.GenTextureMipmaps(&atlas_texture)
        rl.SetTextureFilter(atlas_texture, filter)
    }

    texture := new(Texture)
    texture.name = name
    texture.texture_rl = atlas_texture

    res.textures[texture.name] = texture
}
