package spacelib_raylib_res2

import "core:fmt"
import "core:strconv"
import rl "vendor:raylib"

Sprite :: struct {
    wrap    : bool,
    texture : Texture,
    info    : union { Rect, Patch },
}

Texture         :: rl.Texture
Patch           :: rl.NPatchInfo
Patch_Layout    :: rl.NPatchLayout

@require_results
create_sprite :: proc (init: Sprite) -> ^Sprite {
    sprite := new(Sprite)
    sprite^ = init
    return sprite
}

destroy_sprite :: proc (sprite: ^Sprite) {
    if sprite == nil do return
    free(sprite)
}

sprite_to_patch :: proc (
    sprite      : ^Sprite,
    layout      : Patch_Layout,
    all         := i32(0),
    left        := i32(-1),
    right       := i32(-1),
    top         := i32(-1),
    bottom      := i32(-1),
    new_rect    := Rect {},
) {
    rect_rl: rl.Rectangle
    switch info in sprite.info {
    case Rect   : rect_rl = transmute (rl.Rectangle) info
    case Patch  : rect_rl = info.source
    }

    if new_rect != {} {
        rect_rl = transmute (rl.Rectangle) new_rect
    }

    sprite.info = Patch {
        layout  = layout,
        source  = rect_rl,
        left    = left >= 0 ? left : all,
        right   = right >= 0 ? right : all,
        top     = top >= 0 ? top : all,
        bottom  = bottom >= 0 ? bottom : all,
    }
}

@private
sprite_auto_patch_from_full_name :: proc (sprite: ^Sprite, full_name: string) {
    tags := file_tags(full_name, context.temp_allocator)
    if len(tags) == 0 do return

    patch: Patch
    defer if patch != {} {
        switch info in sprite.info {
        case Rect   : patch.source = transmute (rl.Rectangle) info
        case Patch  : patch.source = info.source
        }
        sprite.info = patch
    }

    for tag in tags {
        if len(tag) < 2 do continue

        switch {
        case tag == "pn"   : patch.layout = .NINE_PATCH
        case tag == "ph"   : patch.layout = .THREE_PATCH_HORIZONTAL
        case tag == "pv"   : patch.layout = .THREE_PATCH_VERTICAL

        case tag[0] == 'a':
            val, ok := strconv.parse_int(tag[1:], base=10)
            fmt.assertf(ok, "Failed to parse_int() in file tag \"%s\" in \"%s\"", tag, full_name)
            patch.left      = i32(val)
            patch.right     = i32(val)
            patch.top       = i32(val)
            patch.bottom    = i32(val)

        case tag[0] == 'l':
            val, ok := strconv.parse_int(tag[1:], base=10)
            fmt.assertf(ok, "Failed to parse_int() in file tag \"%s\" in \"%s\"", tag, full_name)
            patch.left = i32(val)

        case tag[0] == 'r':
            val, ok := strconv.parse_int(tag[1:], base=10)
            fmt.assertf(ok, "Failed to parse_int() in file tag \"%s\" in \"%s\"", tag, full_name)
            patch.right = i32(val)

        case tag[0] == 't':
            val, ok := strconv.parse_int(tag[1:], base=10)
            fmt.assertf(ok, "Failed to parse_int() in file tag \"%s\" in \"%s\"", tag, full_name)
            patch.top = i32(val)

        case tag[0] == 'b':
            val, ok := strconv.parse_int(tag[1:], base=10)
            fmt.assertf(ok, "Failed to parse_int() in file tag \"%s\" in \"%s\"", tag, full_name)
            patch.bottom = i32(val)
        }
    }
}
