package spacelib_raylib_res2

import "core:strings"
import rl "vendor:raylib"

import "../../terse"

Font :: struct {
    using font_tr   : terse.Font,
    font_rl         : rl.Font,
}

@require_results
create_font_from_default :: proc (height := f32(-1)) -> ^Font {
    font_rl := rl.GetFontDefault()
    return create_font_from_rl_font(font_rl,
        height          = height > 0 ? height : f32(font_rl.baseSize),
        rune_spacing    = .1,
    )
}

@require_results
create_font_from_data :: proc (
    data            : [] byte,
    height          : f32,
    rune_spacing    := f32(0),
    line_spacing    := f32(0),
    filter          := rl.TextureFilter.POINT,
) -> ^Font {
    font_rl := rl.LoadFontFromMemory(".ttf", raw_data(data), i32(len(data)), i32(height), nil, 0)
    return create_font_from_rl_font(font_rl,
        height          = height,
        rune_spacing    = rune_spacing,
        line_spacing    = line_spacing,
        filter          = filter,
    )
}

@require_results
create_font_from_rl_font :: proc (
    font_rl         : rl.Font,
    height          : f32,
    rune_spacing    := f32(0),
    line_spacing    := f32(0),
    filter          := rl.TextureFilter.POINT,
) -> ^Font {
    font := new(Font)
    font^ = {
        height          = height,
        rune_spacing    = height * rune_spacing,
        line_spacing    = height * line_spacing,
        measure_text    = measure_text,
        font_rl         = font_rl,
    }
    font.font_ptr = &font.font_rl

    if filter != .POINT {
        rl.GenTextureMipmaps(&font.font_rl.texture)
        rl.SetTextureFilter(font.font_rl.texture, filter)
    }

    return font
}

destroy_font :: proc (font: ^Font, should_unload_rl_font := true) {
    if font == nil do return
    if should_unload_rl_font do rl.UnloadFont(font.font_rl)
    free(font)
}

@require_results
measure_text_for_rl_font :: proc (font: rl.Font, height, rune_spacing: f32, text: string) -> [2] f32 {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    return rl.MeasureTextEx(font, cstr, height, rune_spacing)
}

@require_results
measure_text_for_tr_font :: proc (font: ^terse.Font, text: string) -> [2] f32 {
    cstr := strings.clone_to_cstring(text, context.temp_allocator)
    return rl.MeasureTextEx((cast (^rl.Font) font.font_ptr)^, cstr, font.height, font.rune_spacing)
}

measure_text :: proc {
    measure_text_for_tr_font,
    measure_text_for_rl_font,
}
