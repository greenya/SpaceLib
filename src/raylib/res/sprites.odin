package spacelib_raylib_res

import "core:encoding/json"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import "../../core"

@private default_sprites_json_file_name :: "sprites.json"
@private default_sprites_texture_name   :: "sprites"

Sprite :: struct {
    name    : string,
    texture : string,
    info    : union {
        rl.Rectangle,
        rl.NPatchInfo,
    },
}

Texture :: struct {
    name: string,
    using texture_rl: rl.Texture,
}

load_sprites :: proc (
    res: ^Res,
    texture_size_limit  := [2] int { 512, 2048 },
    texture_sprites_gap := 1,
    texture_force_pot   := true,
    texture_filter      := rl.TextureFilter.POINT,
) {
    assert(default_sprites_texture_name not_in res.textures)
    assert(len(res.sprites) == 0)

    gen_atlas_texture(
        res,
        default_sprites_texture_name,
        texture_size_limit,
        texture_sprites_gap,
        texture_force_pot,
        texture_filter,
    )

    json_file_name := default_sprites_json_file_name
    if json_file_name not_in res.files {
        return
    }

    json_file := res.files[json_file_name]

    json_sprites: [] struct {
        name                        : string,
        nine_patch                  : struct { top, bottom, left, right: f32 },
        nine_patch_all              : f32,
        three_patch_horizontal      : struct { left, right: f32 },
        three_patch_horizontal_all  : f32,
        three_patch_vertical        : struct { top, bottom: f32 },
        three_patch_vertical_all    : f32,
    }

    err := json.unmarshal_any(json_file.data, &json_sprites, allocator=context.temp_allocator)
    ensure(err == nil)

    for js in json_sprites {
        fmt.assertf(js.name in res.sprites, "Sprite \"%s\" not found.", js.name)
        sprite := res.sprites[js.name]

        if js.nine_patch != {} {
            sprite.info = rl.NPatchInfo {
                layout  = .NINE_PATCH,
                source  = sprite.info.(rl.Rectangle),
                top     = i32(js.nine_patch.top),
                bottom  = i32(js.nine_patch.bottom),
                left    = i32(js.nine_patch.left),
                right   = i32(js.nine_patch.right),
            }
        }

        if js.nine_patch_all != 0 {
            sprite.info = rl.NPatchInfo {
                layout  = .NINE_PATCH,
                source  = sprite.info.(rl.Rectangle),
                top     = i32(js.nine_patch_all),
                bottom  = i32(js.nine_patch_all),
                left    = i32(js.nine_patch_all),
                right   = i32(js.nine_patch_all),
            }
        }

        if js.three_patch_horizontal != {} {
            sprite.info = rl.NPatchInfo {
                layout  = .THREE_PATCH_HORIZONTAL,
                source  = sprite.info.(rl.Rectangle),
                left    = i32(js.three_patch_horizontal.left),
                right   = i32(js.three_patch_horizontal.right),
            }
        }

        if js.three_patch_horizontal_all != 0 {
            sprite.info = rl.NPatchInfo {
                layout  = .THREE_PATCH_HORIZONTAL,
                source  = sprite.info.(rl.Rectangle),
                left    = i32(js.three_patch_horizontal_all),
                right   = i32(js.three_patch_horizontal_all),
            }
        }

        if js.three_patch_vertical != {} {
            sprite.info = rl.NPatchInfo {
                layout  = .THREE_PATCH_VERTICAL,
                source  = sprite.info.(rl.Rectangle),
                top     = i32(js.three_patch_vertical.top),
                bottom  = i32(js.three_patch_vertical.bottom),
            }
        }

        if js.three_patch_vertical_all != 0 {
            sprite.info = rl.NPatchInfo {
                layout  = .THREE_PATCH_VERTICAL,
                source  = sprite.info.(rl.Rectangle),
                top     = i32(js.three_patch_vertical_all),
                bottom  = i32(js.three_patch_vertical_all),
            }
        }
    }
}

@private
destroy_sprites_and_textures :: proc (res: ^Res) {
    for _, sprite in res.sprites {
        delete(sprite.name)
        free(sprite)
    }

    delete(res.sprites)
    res.sprites = nil

    for _, texture in res.textures {
        rl.UnloadTexture(texture.texture_rl)
        free(texture)
    }

    delete(res.textures)
    res.textures = nil
}

@private
gen_atlas_texture :: proc (res: ^Res, name: string, size_limit: [2] int, gap: int, force_pot: bool, filter: rl.TextureFilter) {
    atlas := rl.GenImageColor(i32(size_limit.x), i32(size_limit.y), {})
    gap := i32(gap)
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

    rl.ImageCrop(&atlas, { 0, 0, f32(atlas.width), f32(pos_y+max_h+gap) })
    if force_pot do rl.ImageToPOT(&atlas, {255,0,255,255})

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
