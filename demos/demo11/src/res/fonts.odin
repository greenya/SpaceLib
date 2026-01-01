package res

import "core:fmt"
import "spacelib:core"
import "spacelib:raylib/res"

Font_ID :: enum {
    default,
    text_4r,
    text_6r,
}

@private fonts      : [Font_ID] ^res.Font
@private font_names : map [string] Font_ID

// @private
create_fonts :: proc (use_my_bytes: [] byte = nil) {
    assert(font_names == nil)
    font_names = core.map_enum_names_to_values(Font_ID)

    lustria_regular_bytes := #load(ASSETS_PATH + "/Lustria-Regular.ttf")
    bytes := use_my_bytes != nil ? use_my_bytes : lustria_regular_bytes

    assert(fonts == {})
    for id in Font_ID do switch id {
    case .default   : fonts[id] = res.create_font_from_default(height=20)
    case .text_4r   : fonts[id] = res.create_font_from_data(bytes, height=28)
    case .text_6r   : fonts[id] = res.create_font_from_data(bytes, height=48)
    }
}

// @private
destroy_fonts :: proc () {
    delete(font_names)
    font_names = nil

    for font, id in fonts do res.destroy_font(font, should_unload_rl_font = id!=.default)
    fonts = {}
}

font :: #force_inline proc (id: Font_ID) -> ^res.Font {
    return fonts[id]
}

font_by_name :: #force_inline proc (name: string) -> ^res.Font {
    fmt.assertf(name in font_names, "Unknown font \"%s\"", name)
    return font(font_names[name])
}
