package spacelib_raylib_res

import "core:encoding/json"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import "../../terse"
import "../../raylib/measure"

@private default_fonts_json_file_name :: "fonts.json"

Font :: struct {
    name            : string,
    file            : string,
    font_rl         : rl.Font,
    using font_tr   : terse.Font,
}

load_fonts :: proc (res: ^Res, scale := f32(1), default_font_extra_scale := f32(2)) {
    assert(len(res.fonts) == 0)

    json_file_name := default_fonts_json_file_name
    fmt.assertf(json_file_name in res.files, "File \"%s\" not found.", json_file_name)
    json_file := res.files[json_file_name]

    json_fonts: [] struct {
        name                : string,
        file                : string,
        height              : f32,
        rune_spacing        : f32,
        rune_spacing_ratio  : f32,
        line_spacing        : f32,
        line_spacing_ratio  : f32,
    }

    err := json.unmarshal_any(json_file.data, &json_fonts, allocator=context.temp_allocator)
    ensure(err == nil)

    for jf in json_fonts {
        fmt.assertf(jf.file in res.files, "File \"%s\" not found.", jf.file)
        file := res.files[jf.file]

        font := new(Font)
        font^ = {
            name            = strings.clone(jf.name),
            file            = file.name,
            height          = jf.height         * scale,
            rune_spacing    = jf.rune_spacing   * scale,
            line_spacing    = jf.line_spacing   * scale,
            measure_text    = measure.text,
        }

        if jf.rune_spacing_ratio != 0 do font.rune_spacing = jf.rune_spacing_ratio * font.height
        if jf.line_spacing_ratio != 0 do font.line_spacing = jf.line_spacing_ratio * font.height

        load_font_data(res, font)
        res.fonts[font.name] = font
    }

    if terse.default_font_name not_in res.fonts {
        add_font(res, terse.default_font_name, rl.GetFontDefault(), scale * default_font_extra_scale)
    }
}

add_font :: proc (res: ^Res, name: string, font_rl: rl.Font, scale_factor := f32(1)) {
    font_height_base := f32(font_rl.baseSize)
    font_height := font_height_base * scale_factor

    font := new(Font)
    font^ = {
        name            = name,
        height          = font_height,
        rune_spacing    = font_height/10,
        font_rl         = font_rl,
        measure_text    = measure.text,
    }

    font.font_ptr = &font.font_rl
    res.fonts[font.name] = font
}

@private
destroy_fonts :: proc (res: ^Res) {
    for _, font in res.fonts {
        if font.file != "" { // check if this font is loaded by us
            rl.UnloadFont(font.font_rl)
            delete(font.name)
        }
        free(font)
    }

    delete(res.fonts)
    res.fonts = nil
}

@private
load_font_data :: proc (res: ^Res, font: ^Font) {
    file := res.files[font.file]

    file_name_last_dot_idx := strings.last_index_byte(file.name, '.')
    file_ext := file.name[file_name_last_dot_idx:]
    file_ext_cstr := strings.clone_to_cstring(file_ext, context.temp_allocator)

    font.font_rl = rl.LoadFontFromMemory(file_ext_cstr, raw_data(file.data), i32(len(file.data)), i32(font.height), nil, 0)
    font.font_ptr = &font.font_rl
}
