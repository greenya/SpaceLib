package fonts

import "core:fmt"
import "spacelib:core"
import "spacelib:raylib/res"

// --------------------------------------------------------
// ID format: name_[size][weight][style]
// --------------------------------------------------------
// Each part is a single character
// - size   : "1".."9" = abstract size; we can only say which is bigger (5 bigger than 4), but we cannot say on how much
// - weight : "t"=thin "l"=light, "r"=regular, "m"=medium, "b"=bold
// - style  : [optional] not set for normal, "i"=italic,
//            maybe u=underlined, not sure, maybe this should be an extra hint when rendering text as we can just draw
//            the line and we don't need extra font object to store for this separate style; and italic+underlined will
//            just work, no need to think about "iu", a two characters code
// --------------------------------------------------------
// P.S.: this is just an idea for recognizing the font by just looking at its ID,
// but technically the font ID can be anything, e.g. there is nothing that actually parses this format or relies on it
// --------------------------------------------------------

ID :: enum {
    default,
    text_4l,
    text_4r,
    text_4m,
    text_5m,
    text_6l,
    text_8l,
}

Font :: res.Font

@private fonts: [ID] ^Font
@private names: map [string] ID

create :: proc (scale := f32(1)) {
    assert(names == nil)
    names = core.map_enum_names_to_values(ID)

    kanit_light_data    := #load("Kanit-Light.ttf")
    kanit_regular_data  := #load("Kanit-Regular.ttf")
    kanit_medium_data   := #load("Kanit-Medium.ttf")

    assert(fonts == {})
    for id in ID do switch id {
    case .default: fonts[id] = res.create_font_from_default(height=20)
    case .text_4l: fonts[id] = res.create_font_from_data(kanit_light_data, height=28*scale, line_spacing=-.25, filter=.BILINEAR)
    case .text_4r: fonts[id] = res.create_font_from_data(kanit_regular_data, height=28*scale, line_spacing=-.25, filter=.BILINEAR)
    case .text_4m: fonts[id] = res.create_font_from_data(kanit_medium_data, height=28*scale, line_spacing=-.25, filter=.BILINEAR)
    case .text_5m: fonts[id] = res.create_font_from_data(kanit_medium_data, height=34*scale, line_spacing=-.25, filter=.BILINEAR)
    case .text_6l: fonts[id] = res.create_font_from_data(kanit_light_data, height=46*scale, line_spacing=-.25, filter=.BILINEAR)
    case .text_8l: fonts[id] = res.create_font_from_data(kanit_light_data, height=82*scale, line_spacing=-.25, filter=.BILINEAR)
    }
}

destroy :: proc () {
    delete(names)
    names = nil

    for font, id in fonts do res.destroy_font(font, should_unload_rl_font = id!=.default)
    fonts = {}
}

get :: #force_inline proc (id: ID) -> ^Font {
    return fonts[id]
}

get_by_name :: #force_inline proc (name: string) -> ^Font {
    fmt.assertf(name in names, "Unknown font \"%s\"", name)
    return get(names[name])
}
