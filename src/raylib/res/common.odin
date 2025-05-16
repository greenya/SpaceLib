package spacelib_raylib_res

import "core:fmt"
import "../../core"

print_resources :: proc (res: ^Res) {
    fmt.println("-------- Resources --------")

    fmt.printfln("Files (%i):", len(res.files))
    for name in core.map_keys_sorted(res.files, context.temp_allocator) {
        fmt.printfln("- %s (%i bytes)", name, len(res.files[name].data))
    }

    fmt.printfln("Fonts (%i):", len(res.fonts))
    for name in core.map_keys_sorted(res.fonts, context.temp_allocator) {
        fmt.printfln("- %s (%v px)", name, res.fonts[name].height)
    }

    fmt.printfln("Textures (%i):", len(res.textures))
    for name in core.map_keys_sorted(res.textures, context.temp_allocator) {
        fmt.printfln("- %s (%vx%v px)", name, res.textures[name].width, res.textures[name].height)
    }

    fmt.printfln("Sprites (%i):", len(res.sprites))
    for name in core.map_keys_sorted(res.sprites, context.temp_allocator) {
        fmt.printfln("- %s (%vx%v px)", name, res.sprites[name].info.width, res.sprites[name].info.height)
    }

    fmt.println("---------------------------")
}
