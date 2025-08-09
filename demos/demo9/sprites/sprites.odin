package sprites

import "base:runtime"
import "core:fmt"
import "core:slice"
import "core:strings"
import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:raylib/env"

@private Rect :: core.Rect
@private File :: runtime.Load_Directory_File

Sprite :: struct {
    name: string,
    wrap: bool,
    tex : ^rl.Texture,
    info: union { Rect, rl.NPatchInfo },
}

@private textures: [dynamic] ^rl.Texture
@private sprites: map [string] ^Sprite

get_textures :: #force_inline proc () -> [] ^rl.Texture { return textures[:] }

create :: proc (scale := f32(1), filter := rl.TextureFilter.BILINEAR) {
    assert(len(textures) == 0)
    assert(len(sprites) == 0)

    gen_atlas(#load_directory("./"), filter=filter, sprites_scale=scale)
    // fmt.println("textures", textures)
    // fmt.println("sprites", sprites)
}

destroy :: proc () {
    for _, sprite in sprites {
        delete(sprite.name)
        free(sprite)
    }
    delete(sprites)
    sprites = {}

    for tex in textures {
        rl.UnloadTexture(tex^)
        free(tex)
    }
    delete(textures)
    textures = {}
}

get :: #force_inline proc (name: string) -> ^Sprite {
    fmt.assertf(name in sprites, "Unknown sprite: \"%s\"", name)
    return sprites[name]
}

// TODO: move stuff below to spacelib/raylib
// with Texture and Sprite definition i guess and should return generated texture and sprites (?)
// ?: maybe the "res" package should be removed and we keep general loading/unloading procs
// ?: for sprites and fonts only

@private Drawing_Cursor :: struct { x, y, gap, max_row_h, used_w, used_h: i32 }
@private Drawing_Status :: enum { ok, width_overflow, height_overflow }

@private
gen_atlas :: proc (
    files           : [] File,
    file_extensions := [] string { ".png", ".jpg", ".jpeg" },
    name_format     := "%s",
    size_limit      := [2] int { 1024, 1024 },
    sprites_gap     := 1,
    sprites_scale   := f32(1),
    force_pot       := true,
    filter          := rl.TextureFilter.POINT,
) {
    atlas := rl.GenImageColor(i32(size_limit.x), i32(size_limit.y), {})
    cursor := Drawing_Cursor {
        x   = i32(sprites_gap),
        y   = i32(sprites_gap),
        gap = i32(sprites_gap),
    }

    new_sprites := make([dynamic] ^Sprite)
    defer delete(new_sprites)

    for file in get_image_files_ordered_by_height(files, file_extensions, context.temp_allocator) {
        file_ext := core.string_suffix_from_slice(file.name, file_extensions)
        wrap := strings.contains(file.name, ".wrap.")

        image := env.load_image_from_bytes(file_ext, file.data)
        defer env.unload_image(image)

        if sprites_scale != 1 {
        assert(sprites_scale > 0 && sprites_scale < 1)
            rl.ImageResize(&image, i32(f32(image.width)*sprites_scale), i32(f32(image.height)*sprites_scale))
        }

        status, image_rect_on_atlas := draw_image_on_image(&cursor, &atlas, image, wrap)
        if status != .ok {
            fmt.eprintfln("[!] %s failed: Unable to fit \"%s\": %v", #procedure, file.name, status)
        }

        sprite := new(Sprite)
        sprite.name = fmt.aprintf(name_format, file.name[:strings.index_byte(file.name, '.')])
        sprite.wrap = wrap
        sprite.info = image_rect_on_atlas
        append(&new_sprites, sprite)
    }

    rl.ImageCrop(&atlas, { 0, 0, f32(cursor.used_w), f32(cursor.used_h) })
    if force_pot do rl.ImageToPOT(&atlas, {255,0,255,255})

    atlas_texture := rl.LoadTextureFromImage(atlas)
    rl.UnloadImage(atlas)

    if filter != .POINT {
        rl.GenTextureMipmaps(&atlas_texture)
        rl.SetTextureFilter(atlas_texture, filter)
    }

    tex := new(rl.Texture)
    tex^ = atlas_texture
    append(&textures, tex)

    for s in new_sprites {
        s.tex = tex
        sprites[s.name] = s
    }
}

// Takes any files and returns:
// - only image files (filtered by file_extensions)
// - ordered by image height (this improves arrangement of sprites on atlas... but not much to be honest :)
@private
get_image_files_ordered_by_height :: proc (
    files           : [] File,
    file_extensions : [] string,
    allocator       := context.allocator,
) -> [] File {
    Info :: struct { file: File, image_height: int }
    infos := make([dynamic] Info, context.temp_allocator)

    for file in files {
        file_ext := core.string_suffix_from_slice(file.name, file_extensions)
        if file_ext == "" do continue

        image := env.load_image_from_bytes(file_ext, file.data)
        defer env.unload_image(image)

        append(&infos, Info { file=file, image_height=int(image.height) })
    }

    slice.sort_by(infos[:], less=proc (i1, i2: Info) -> bool {
        return i1.image_height < i2.image_height
    })

    list := make([dynamic] File, len=0, cap=len(infos), allocator=allocator)
    for i in infos do append(&list, i.file)

    return list[:]
}

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
