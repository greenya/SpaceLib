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

    fmt.println("---------------------------")
}
