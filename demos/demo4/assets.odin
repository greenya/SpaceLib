package demo4

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:ui"
import sl_rl "spacelib:raylib"

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
    sheet_white1x_png,
}

File :: struct {
    type: string,
    data: [] u8,
}

file_assets: [File_ID] File = {
    .anaheim_bold_ttf   = { "ttf", #load("assets/Anaheim-Bold.ttf") },
    .ui_atlas_png       = { "png", #load("assets/ui_atlas.png") },
    .sheet_white1x_png  = { "png", #load("assets/sheet_white1x.png") },
}

Font_ID :: enum {
    anaheim_bold_64,
    anaheim_bold_32,
}

Font :: struct {
    file_id: File_ID,
    font_rl: rl.Font,
    using font_sl: ui.Font,
}

font_assets: [Font_ID] Font = {
    .anaheim_bold_64 = { file_id=.anaheim_bold_ttf, height=64, letter_spacing=-2, word_spacing=16, line_spacing=-8 },
    .anaheim_bold_32 = { file_id=.anaheim_bold_ttf, height=32, letter_spacing=0, word_spacing=8, line_spacing=-4 },
}

Texture_ID :: enum {
    ui_atlas,
    sheet_white1x,
}

Texture :: struct {
    file_id: File_ID,
    texture: rl.Texture,
}

texture_assets: [Texture_ID] Texture = {
    .ui_atlas       = { file_id=.ui_atlas_png },
    .sheet_white1x  = { file_id=.sheet_white1x_png },
}

Sprite_ID :: enum {
    border_17,
    panel_0,
    panel_3,
    panel_4,
    panel_9,
    panel_15,
    icon_up,
    icon_down,
    icon_stop,
}

Sprite :: struct {
    texture_id: Texture_ID,
    info: union {
        rl.Rectangle,
        rl.NPatchInfo,
    },
}

sprite_assets: [Sprite_ID] Sprite = {
    .border_17  = { texture_id=.ui_atlas, info=rl.NPatchInfo { source={834,  1,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_0    = { texture_id=.ui_atlas, info=rl.NPatchInfo { source={  1,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_3    = { texture_id=.ui_atlas, info=rl.NPatchInfo { source={148,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_4    = { texture_id=.ui_atlas, info=rl.NPatchInfo { source={197,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_9    = { texture_id=.ui_atlas, info=rl.NPatchInfo { source={442,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_15   = { texture_id=.ui_atlas, info=rl.NPatchInfo { source={736,  1,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .icon_up    = { texture_id=.sheet_white1x, info=rl.Rectangle {100, 50,50,50} },
    .icon_down  = { texture_id=.sheet_white1x, info=rl.Rectangle {400,300,50,50} },
    .icon_stop  = { texture_id=.sheet_white1x, info=rl.Rectangle {100,400,50,50} },
}

assets_load :: proc () {
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

assets_unload :: proc () {
    for &font in font_assets {
        rl.UnloadFont(font.font_rl)
        font.font_rl = {}
    }

    for &texture in texture_assets {
        rl.UnloadTexture(texture.texture)
        texture.texture = {}
    }
}
