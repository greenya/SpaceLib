package demo4

import "core:fmt"
import rl "vendor:raylib"
import sl "../spacelib"
import sl_rl "../spacelib/raylib"

colors: struct {
    one,
    two,
    three,
    four,
    five,
    six,
    seven,
    eight: rl.Color,
} = {
    // https://lospec.com/palette-list/gothic-bit
    one     = transmute (rl.Color) u32be(0x0e0e12ff),
    two     = transmute (rl.Color) u32be(0x1a1a24ff),
    three   = transmute (rl.Color) u32be(0x333346ff),
    four    = transmute (rl.Color) u32be(0x535373ff),
    five    = transmute (rl.Color) u32be(0x8080a4ff),
    six     = transmute (rl.Color) u32be(0xa6a6bfff),
    seven   = transmute (rl.Color) u32be(0xc1c1d2ff),
    eight   = transmute (rl.Color) u32be(0xe6e6ecff),
}

File_ID :: enum {
    anaheim_bold_ttf,
    ui_atlas_png,
}

file_assets: [File_ID] struct {
    type: string,
    data: [] u8,
} = {
    .anaheim_bold_ttf   = { "ttf", #load("assets/Anaheim-Bold.ttf") },
    .ui_atlas_png       = { "png", #load("assets/ui_atlas.png") },
}

Font_ID :: enum {
    anaheim_bold_64,
    anaheim_bold_32,
}

font_assets: [Font_ID] struct {
    file_id: File_ID,
    font_rl: rl.Font,
    using info: sl.Font,
} = {
    .anaheim_bold_64 = { file_id=.anaheim_bold_ttf, height=64, letter_spacing=-2, word_spacing=16, line_spacing=0 },
    .anaheim_bold_32 = { file_id=.anaheim_bold_ttf, height=32, letter_spacing=0, word_spacing=8, line_spacing=-4 },
}

Texture_ID :: enum {
    ui_atlas,
}

texture_assets: [Texture_ID] struct {
    file_id: File_ID,
    texture: rl.Texture,
} = {
    .ui_atlas = { file_id=.ui_atlas_png },
}

Sprite_ID :: enum {
    border_17,
    panel_0,
    panel_3,
    panel_4,
    panel_9,
}

sprite_assets: [Sprite_ID] struct {
    texture_id: Texture_ID,
    npatch: rl.NPatchInfo,
} = {
    .border_17  = { npatch={ source={834,  1,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_0    = { npatch={ source={  1,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_3    = { npatch={ source={148,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_4    = { npatch={ source={197,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_9    = { npatch={ source={442,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
}

load_assets :: proc () {
    for &font in font_assets {
        file := &file_assets[font.file_id]
        file_ext := fmt.ctprintf(".%s", file.type)
        font.font_rl = rl.LoadFontFromMemory(file_ext, raw_data(file.data), i32(len(file.data)), i32(font.height), nil, 0)
        font.font_ptr = &font.font_rl
        font.measure_text = sl_rl.measure_text
    }

    for &texture in texture_assets {
        file := &file_assets[texture.file_id]
        file_ext := fmt.ctprintf(".%s", file.type)
        image := rl.LoadImageFromMemory(file_ext, raw_data(file.data), i32(len(file.data)))
        texture.texture = rl.LoadTextureFromImage(image)
        rl.UnloadImage(image)
    }
}

unload_assets :: proc () {
    for &font in font_assets {
        rl.UnloadFont(font.font_rl)
        font.font_rl = {}
    }

    for &texture in texture_assets {
        rl.UnloadTexture(texture.texture)
        texture.texture = {}
    }
}
