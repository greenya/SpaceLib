package spacelib_raylib_res

import "core:fmt"
import rl "vendor:raylib"
import "../../core"

Res :: struct {
    files       : map [string] File,
    colors      : map [string] ^Color,
    fonts       : map [string] ^Font,
    textures    : map [string] ^Texture,
    sprites     : map [string] ^Sprite,
    sounds      : map [string] ^Sound,
    music       : map [string] ^Music,
}

create :: proc () -> ^Res {
    res := new(Res)
    return res
}

destroy :: proc (res: ^Res) {
    delete(res.files)
    destroy_colors(res)
    destroy_fonts(res)
    destroy_sprites_and_textures(res)
    destroy_sounds_and_music(res)
    free(res)
}

print :: proc (res: ^Res) {
    context.allocator = context.temp_allocator
    fmt.println("-------- Resources --------")

    fmt.printfln("Files (%i):", len(res.files))
    for name in core.map_keys_sorted(res.files) {
        fmt.printfln("- %s (%i bytes)", name, len(res.files[name].data))
    }

    fmt.printfln("Colors (%i):", len(res.colors))
    for name in core.map_keys_sorted(res.colors) {
        fmt.printfln("- %s (%s)", name, core.color_to_hex(res.colors[name]))
    }

    fmt.printfln("Fonts (%i):", len(res.fonts))
    for name in core.map_keys_sorted(res.fonts) {
        fmt.printfln("- %s (%v px)", name, res.fonts[name].height)
    }

    fmt.printfln("Textures (%i):", len(res.textures))
    for name in core.map_keys_sorted(res.textures) {
        fmt.printfln("- %s (%vx%v px)", name, res.textures[name].width, res.textures[name].height)
    }

    fmt.printfln("Sprites (%i):", len(res.sprites))
    for name in core.map_keys_sorted(res.sprites) {
        switch info in res.sprites[name].info {
        case rl.Rectangle:
            fmt.printfln("- %s (%vx%v px)", name, info.width, info.height)
        case rl.NPatchInfo:
            fmt.printfln("- %s (%vx%v px, %v)", name, info.source.width, info.source.height, info.layout)
        }
    }

    fmt.printfln("Sounds (%i):", len(res.sounds))
    for name in core.map_keys_sorted(res.sounds) {
        fmt.printfln("- %s", name)
    }

    fmt.println("---------------------------")
}
