package demo9_fonts

import rl "vendor:raylib"
import "spacelib:terse"
import "spacelib:raylib/measure"

Font :: struct {
    using font_tr   : terse.Font,
    font_rl         : rl.Font,
}

default: ^Font
text_4l: ^Font
text_4r: ^Font
text_4m: ^Font
text_6l: ^Font
text_8l: ^Font

create :: proc () {
    text_4l = create_font_from_data(#load("Kanit-Light.ttf"), height=28, line_spacing_ratio=-.25, filter=.BILINEAR)
    text_4r = create_font_from_data(#load("Kanit-Regular.ttf"), height=28, line_spacing_ratio=-.25, filter=.BILINEAR)
    text_4m = create_font_from_data(#load("Kanit-Medium.ttf"), height=28, line_spacing_ratio=-.25, filter=.BILINEAR)
    text_6l = create_font_from_data(#load("Kanit-Light.ttf"), height=46, line_spacing_ratio=-.25, filter=.BILINEAR)
    text_8l = create_font_from_data(#load("Kanit-Light.ttf"), height=82, line_spacing_ratio=-.25, filter=.BILINEAR)
    default = create_font_default(scale=2)
}

destroy :: proc () {
    destroy_font(default, should_unload_font=false)
    destroy_font(text_4l)
    destroy_font(text_4r)
    destroy_font(text_4m)
    destroy_font(text_6l)
    destroy_font(text_8l)
}

get :: #force_inline proc (name: string) -> ^Font {
    switch name {
    case "text_4l"  : return text_4l
    case "text_4r"  : return text_4r
    case "text_4m"  : return text_4m
    case "text_6l"  : return text_6l
    case "text_8l"  : return text_8l
    case            : return default
    }
}

@private
create_font_default :: proc (scale := f32(1)) -> ^Font {
    font_rl := rl.GetFontDefault()
    font_height := scale * f32(font_rl.baseSize)
    font := new(Font)
    font^ = {
        height          = font_height,
        rune_spacing    = font_height/10,
        line_spacing    = 0,
        measure_text    = measure.text,
        font_rl         = font_rl,
    }
    font.font_ptr = &font.font_rl
    return font
}

@private
create_font_from_data :: proc (
    data                : [] byte,
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
        font_rl         = rl.LoadFontFromMemory(".ttf", raw_data(data), i32(len(data)), i32(height), nil, 0),
    }
    font.font_ptr = &font.font_rl

    if filter != .POINT {
        rl.GenTextureMipmaps(&font.font_rl.texture)
        rl.SetTextureFilter(font.font_rl.texture, filter)
    }

    return font
}

@private
destroy_font :: proc (font: ^Font, should_unload_font := true) {
    if should_unload_font do rl.UnloadFont(font.font_rl)
    free(font)
}
