package fonts

import "base:intrinsics"
import "core:fmt"
import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:terse"
import "spacelib:raylib/measure"

// --------------------------------------------------------
// ID format: name_[size][weight][style]
// --------------------------------------------------------
// Each part is a single character
// - size   : "1".."9" = abstract size; we can only say which is bigger (5 bigger then 4), but we cannot say on how much
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
    text_6l,
    text_8l,
}

Font :: struct {
    using font_tr   : terse.Font,
    font_rl         : rl.Font,
}

@private fonts: [ID] ^Font
@private names: map [string] ID

create :: proc () {
    assert(names == nil)
    names = core.map_enum_names_to_values(ID)

    for id in ID do switch id {
    case .default: fonts[id] = create_font_from_default(scale=2)
    case .text_4l: fonts[id] = create_font_from_data(#load("Kanit-Light.ttf"), height=28, line_spacing_ratio=-.25, filter=.BILINEAR)
    case .text_4r: fonts[id] = create_font_from_data(#load("Kanit-Regular.ttf"), height=28, line_spacing_ratio=-.25, filter=.BILINEAR)
    case .text_4m: fonts[id] = create_font_from_data(#load("Kanit-Medium.ttf"), height=28, line_spacing_ratio=-.25, filter=.BILINEAR)
    case .text_6l: fonts[id] = create_font_from_data(#load("Kanit-Light.ttf"), height=46, line_spacing_ratio=-.25, filter=.BILINEAR)
    case .text_8l: fonts[id] = create_font_from_data(#load("Kanit-Light.ttf"), height=82, line_spacing_ratio=-.25, filter=.BILINEAR)
    }
}

destroy :: proc () {
    delete(names)
    for font, id in fonts do destroy_font(font, should_unload_rl_font = id!=.default)
}

get :: #force_inline proc (id: ID) -> ^Font {
    return fonts[id]
}

get_by_name :: #force_inline proc (name: string) -> ^Font {
    fmt.assertf(name in names, "Unknown font \"%s\"", name)
    return get(names[name])
}

@private
create_font_from_default :: proc (scale := f32(1)) -> ^Font {
    font_rl := rl.GetFontDefault()
    return create_font_from_rl_font(font_rl,
        height              = scale * f32(font_rl.baseSize),
        rune_spacing_ratio  = .1,
    )
}

@private
create_font_from_data :: proc (
    data                : [] byte,
    height              : f32,
    rune_spacing_ratio  := f32(0),
    line_spacing_ratio  := f32(0),
    filter              := rl.TextureFilter.POINT,
) -> ^Font {
    font_rl := rl.LoadFontFromMemory(".ttf", raw_data(data), i32(len(data)), i32(height), nil, 0)
    return create_font_from_rl_font(font_rl,
        height              = height,
        rune_spacing_ratio  = rune_spacing_ratio,
        line_spacing_ratio  = line_spacing_ratio,
        filter              = filter,
    )
}

@private
create_font_from_rl_font :: proc (
    font_rl             : rl.Font,
    height              : f32,
    rune_spacing_ratio  := f32(0),
    line_spacing_ratio  := f32(0),
    filter              := rl.TextureFilter.POINT,
) -> ^Font {
    font := new(Font)
    font^ = {
        height          = height,
        rune_spacing    = height * rune_spacing_ratio,
        line_spacing    = height * line_spacing_ratio,
        measure_text    = measure.text,
        font_rl         = font_rl,
    }
    font.font_ptr = &font.font_rl

    if filter != .POINT {
        rl.GenTextureMipmaps(&font.font_rl.texture)
        rl.SetTextureFilter(font.font_rl.texture, filter)
    }

    return font
}

@private
destroy_font :: proc (font: ^Font, should_unload_rl_font := true) {
    if should_unload_rl_font do rl.UnloadFont(font.font_rl)
    free(font)
}
