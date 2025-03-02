package spacelib

import rl "vendor:raylib"

Font :: struct {
    obj     : rl.Font,
    size    : f32,
    spacing : f32,
}

add_font_from_bytes :: proc (ui: ^UI, data: [] u8, size: f32, spacing := f32(0)) -> ^Font {
    obj := rl.LoadFontFromMemory(".ttf", raw_data(data), i32(len(data)), i32(size), nil, 0)
    font := new(Font)
    font^ = { obj=obj, size=size, spacing=spacing }
    append(&ui.fonts, font)
    return font
}
