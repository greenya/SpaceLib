package spacelib_raylib_res

import "core:fmt"
import rl "vendor:raylib"
import "../../core"

@private Vec2 :: core.Vec2
@private Rect :: core.Rect

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

Print_Filter :: enum {
    files,
    colors,
    fonts,
    textures,
    sprites,
    music,
    sounds,
}

print :: proc (res: ^Res, filter: bit_set [Print_Filter] = ~{}) {
    context.allocator = context.temp_allocator
    fmt.println("-------- Resources --------")

    if filter == {} do fmt.println("[!] Filter is empty")

    if .files in filter {
        fmt.printfln("Files (%i):", len(res.files))
        for name in core.map_keys_sorted(res.files) {
            fmt.printfln("- %s (%i bytes)", name, len(res.files[name].data))
        }
    }

    if .colors in filter {
        fmt.printfln("Colors (%i):", len(res.colors))
        for name in core.map_keys_sorted(res.colors) {
            fmt.printfln("- %s (%s)", name, core.color_to_hex(res.colors[name]))
        }
    }

    if .fonts in filter {
        fmt.printfln("Fonts (%i):", len(res.fonts))
        for name in core.map_keys_sorted(res.fonts) {
            fmt.printfln("- %s (%v px)", name, res.fonts[name].height)
        }
    }

    if .textures in filter {
        fmt.printfln("Textures (%i):", len(res.textures))
        for name in core.map_keys_sorted(res.textures) {
            fmt.printfln("- %s (%vx%v px)", name, res.textures[name].width, res.textures[name].height)
        }
    }

    if .sprites in filter {
        fmt.printfln("Sprites (%i):", len(res.sprites))
        for name in core.map_keys_sorted(res.sprites) {
            switch info in res.sprites[name].info {
            case Rect:
                wrap_text := res.sprites[name].wrap ? ", wrap" : ""
                fmt.printfln("- %s (%vx%v px%s)", name, info.w, info.h, wrap_text)
            case rl.NPatchInfo:
                fmt.printfln("- %s (%vx%v px, %v)", name, info.source.width, info.source.height, info.layout)
            }
        }
    }

    if .music in filter {
        fmt.printfln("Music (%i):", len(res.music))
        for name in core.map_keys_sorted(res.music) {
            music := res.music[name]
            fmt.printfln("- %s (%.3f sec, looping: %v)", name, rl.GetMusicTimeLength(music), music.looping)
        }
    }

    if .sounds in filter {
        fmt.printfln("Sounds (%i):", len(res.sounds))
        for name in core.map_keys_sorted(res.sounds) {
            fmt.printfln("- %s", name)
        }
    }

    fmt.println("---------------------------")
}
