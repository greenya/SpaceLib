package spacelib_raylib_res

import "core:encoding/json"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import "../../core"

@private default_sprites_json_file_name :: "sprites.json"
@private default_sprites_texture_name   :: "sprites"
@private default_sprite_file_ext_list   :: [] string { ".png" }

Sprite :: struct {
    name    : string,
    texture : string,
    wrap    : bool,
    info    : union {
        Rect,
        rl.NPatchInfo,
    },
}

Texture :: struct {
    name: string,
    using texture_rl: rl.Texture,
}

load_sprites :: proc (
    res: ^Res,
    texture_size_limit  := [2] int { 1024, 1024 },
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
                source  = transmute (rl.Rectangle) sprite.info.(Rect),
                top     = i32(js.nine_patch.top),
                bottom  = i32(js.nine_patch.bottom),
                left    = i32(js.nine_patch.left),
                right   = i32(js.nine_patch.right),
            }
        }

        if js.nine_patch_all != 0 {
            sprite.info = rl.NPatchInfo {
                layout  = .NINE_PATCH,
                source  = transmute (rl.Rectangle) sprite.info.(Rect),
                top     = i32(js.nine_patch_all),
                bottom  = i32(js.nine_patch_all),
                left    = i32(js.nine_patch_all),
                right   = i32(js.nine_patch_all),
            }
        }

        if js.three_patch_horizontal != {} {
            sprite.info = rl.NPatchInfo {
                layout  = .THREE_PATCH_HORIZONTAL,
                source  = transmute (rl.Rectangle) sprite.info.(Rect),
                left    = i32(js.three_patch_horizontal.left),
                right   = i32(js.three_patch_horizontal.right),
            }
        }

        if js.three_patch_horizontal_all != 0 {
            sprite.info = rl.NPatchInfo {
                layout  = .THREE_PATCH_HORIZONTAL,
                source  = transmute (rl.Rectangle) sprite.info.(Rect),
                left    = i32(js.three_patch_horizontal_all),
                right   = i32(js.three_patch_horizontal_all),
            }
        }

        if js.three_patch_vertical != {} {
            sprite.info = rl.NPatchInfo {
                layout  = .THREE_PATCH_VERTICAL,
                source  = transmute (rl.Rectangle) sprite.info.(Rect),
                top     = i32(js.three_patch_vertical.top),
                bottom  = i32(js.three_patch_vertical.bottom),
            }
        }

        if js.three_patch_vertical_all != 0 {
            sprite.info = rl.NPatchInfo {
                layout  = .THREE_PATCH_VERTICAL,
                source  = transmute (rl.Rectangle) sprite.info.(Rect),
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

@private Drawing_Cursor :: struct { x, y, gap, max_row_h, used_w, used_h: i32 }
@private Drawing_Status :: enum { ok, width_overflow, height_overflow }

@private
gen_atlas_texture :: proc (res: ^Res, name: string, size_limit: [2] int, gap: int, force_pot: bool, filter: rl.TextureFilter) {
    atlas := rl.GenImageColor(i32(size_limit.x), i32(size_limit.y), {})
    cursor := Drawing_Cursor { x=i32(gap), y=i32(gap), gap=i32(gap) }

    for file_name in core.map_keys_sorted(res.files, context.temp_allocator) {
        file_ext := core.string_suffix_from_slice(file_name, default_sprite_file_ext_list)
        if file_ext == "" do continue

        wrap := strings.contains(file_name, ".wrap.")

        file := res.files[file_name]
        file_ext_cstr := strings.clone_to_cstring(file_ext, context.temp_allocator)
        image := rl.LoadImageFromMemory(file_ext_cstr, raw_data(file.data), i32(len(file.data)))

        status, image_rect_on_atlas := draw_image_on_image(&cursor, &atlas, image, wrap)
        if status != .ok {
            fmt.eprintfln("[!] Generate atlas texture failed: Unable to fit \"%s\": %v", file_name, status)
        }

        rl.UnloadImage(image)

        sprite := new(Sprite)
        sprite.name = strings.clone(file_name[:strings.index_byte(file_name, '.')])
        sprite.texture = name
        sprite.wrap = wrap
        sprite.info = image_rect_on_atlas

        res.sprites[sprite.name] = sprite
    }

    rl.ImageCrop(&atlas, { 0, 0, f32(cursor.used_w), f32(cursor.used_h) })
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

@private
draw_image_on_image :: proc (
    cursor: ^Drawing_Cursor,
    target: ^rl.Image,
    source: rl.Image,
    wrap: bool,
) -> (
    status: Drawing_Status,
    image_rect_on_atlas: Rect,
) {
    if cursor.x + source.width + cursor.gap > target.width {
        cursor.x = cursor.gap
        cursor.y += cursor.gap + cursor.max_row_h
        cursor.max_row_h = 0
    }

    if cursor.x + source.width + cursor.gap > target.width {
        return .width_overflow, {}
    }

    if cursor.y + source.height + cursor.gap > target.height {
        return .height_overflow, {}
    }

    src_rect := rl.Rectangle { 0, 0, f32(source.width), f32(source.height) }
    dst_rect := rl.Rectangle { f32(cursor.x), f32(cursor.y), f32(source.width), f32(source.height) }

    if wrap {
        // checker rect lines {{{
        // wrap_rect := dst_rect
        // wrap_rect.width += 2
        // wrap_rect.height += 2
        // rl.ImageDrawRectangleLines(target, wrap_rect, 1, {255,0,255,255})
        // }}}

        dst_rect.x += 1
        dst_rect.y += 1

        // top line
        rl.ImageDraw(target, source,
            {0,0,src_rect.width,1},
            {dst_rect.x,dst_rect.y-1,dst_rect.width,1},
            rl.WHITE,
        )
        // bottom line
        rl.ImageDraw(target, source,
            {0,src_rect.height-1,src_rect.width,1},
            {dst_rect.x,dst_rect.y+dst_rect.height,dst_rect.width,1},
            rl.WHITE,
        )
        // left line
        rl.ImageDraw(target, source,
            {0,0,1,src_rect.height},
            {dst_rect.x-1,dst_rect.y,1,dst_rect.height},
            rl.WHITE,
        )
        // right line
        rl.ImageDraw(target, source,
            {src_rect.width-1,0,1,src_rect.height},
            {dst_rect.x+dst_rect.width,dst_rect.y,1,dst_rect.height},
            rl.WHITE,
        )
    }

    rl.ImageDraw(target, source, src_rect, dst_rect, rl.WHITE)

    cursor.x += source.width + cursor.gap + (wrap?2:0)
    cursor.max_row_h = max(cursor.max_row_h, source.height+(wrap?2:0))
    cursor.used_w = max(cursor.used_w, cursor.x)
    cursor.used_h = cursor.y + cursor.max_row_h + cursor.gap

    return .ok, transmute (Rect) dst_rect
}
