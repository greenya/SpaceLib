package spacelib_raylib_res2

import "core:fmt"
import "core:slice"
import "core:strings"
import rl "vendor:raylib"

import "spacelib:core"

Atlas :: struct {
    texture: Texture,
    sprites: map [string] ^Sprite,
}

@require_results
create_atlas :: proc (
    files       : [] File,
    auto_patch  := false,
    size_limit  := [2] int { 1024, 1024 },
    gap         := 1,
    scale       := f32(1),
    force_pot   := true,
    filter      := rl.TextureFilter.POINT,
) -> ^Atlas {
    assert(gap >= 0)

    atlas := new(Atlas)
    atlas_image := rl.GenImageColor(i32(size_limit.x), i32(size_limit.y), {})
    cursor := Drawing_Cursor { x=i32(gap), y=i32(gap), gap=i32(gap) }
    files_ordered := image_files_ordered_by_height(files, context.temp_allocator)

    if len(files_ordered) == 0 do return atlas

    atlas.sprites = make(map [string] ^Sprite)

    for file in files_ordered {
        file_ext := core.string_suffix_from_slice(file.name, image_file_extensions)
        wrap := strings.contains(file.name, ".wrap.")

        image := rl_load_image_from_bytes(file.data, file_ext)
        defer rl.UnloadImage(image)

        if scale != 1 {
            assert(scale > 0)
            rl.ImageResize(&image, i32(f32(image.width)*scale), i32(f32(image.height)*scale))
        }

        status, image_rect_on_atlas := draw_image_on_image(&cursor, &atlas_image, image, wrap)
        if status != .ok {
            fmt.eprintfln("[!] %s failed: Unable to fit \"%s\": %v", #procedure, file.name, status)
        }

        name := file_name(file.name)
        fmt.assertf(name not_in atlas.sprites, "Duplicated sprite name \"%s\" in the atlas", name)

        sprite := create_sprite({ wrap=wrap, info=image_rect_on_atlas })
        if auto_patch do sprite_auto_patch_from_full_name(sprite, file.name)
        atlas.sprites[name] = sprite
    }

    rl.ImageCrop(&atlas_image, { 0, 0, f32(cursor.used_w), f32(cursor.used_h) })
    if force_pot do rl.ImageToPOT(&atlas_image, {255,0,255,255})

    atlas.texture = rl.LoadTextureFromImage(atlas_image)
    rl.UnloadImage(atlas_image)

    if filter != .POINT {
        rl.GenTextureMipmaps(&atlas.texture)
        rl.SetTextureFilter(atlas.texture, filter)
    }

    for _, sprite in atlas.sprites {
        sprite.texture = atlas.texture
    }

    return atlas
}

destroy_atlas :: proc (atlas: ^Atlas) {
    if atlas == nil do return

    if atlas.texture.id > 0 do rl.UnloadTexture(atlas.texture)

    for _, sprite in atlas.sprites do destroy_sprite(sprite)
    delete(atlas.sprites)

    free(atlas)
}

// Takes any files and returns:
// - only image files (filtered by image_file_extensions)
// - ordered by image height (this improves arrangement of sprites on atlas... but not much to be honest :)
@private
image_files_ordered_by_height :: proc (
    files       : [] File,
    allocator   := context.allocator,
) -> [] File {
    Info :: struct { file: File, image_height: int }
    infos := make([dynamic] Info, context.temp_allocator)

    for file in files {
        file_ext := core.string_suffix_from_slice(file.name, image_file_extensions)
        if file_ext == "" do continue

        image := rl_load_image_from_bytes(file.data, file_ext)
        defer rl.UnloadImage(image)

        append(&infos, Info { file=file, image_height=int(image.height) })
    }

    slice.sort_by(infos[:], less=proc (i1, i2: Info) -> bool {
        return i1.image_height < i2.image_height
    })

    list := make([dynamic] File, len=0, cap=len(infos), allocator=allocator)
    for i in infos do append(&list, i.file)

    return list[:]
}

@private Drawing_Cursor :: struct { x, y, gap, max_row_h, used_w, used_h: i32 }
@private Drawing_Status :: enum { ok, width_overflow, height_overflow }

@private
draw_image_on_image :: proc (
    cursor  : ^Drawing_Cursor,
    target  : ^rl.Image,
    source  : rl.Image,
    wrap    : bool,
) -> (
    status              : Drawing_Status,
    image_rect_on_atlas : Rect,
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

@private
rl_load_image_from_bytes :: proc (bytes: [] byte, file_ext: string) -> rl.Image {
    return rl.LoadImageFromMemory(
        fileType = strings.clone_to_cstring(file_ext, context.temp_allocator),
        fileData = raw_data(bytes),
        dataSize = i32(len(bytes)),
    )
}
