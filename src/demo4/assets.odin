package demo4

import "core:fmt"
import rl "vendor:raylib"

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
    one     = transmute (rl.Color) u32be(0x0d2b45ff),
    two     = transmute (rl.Color) u32be(0x203c56ff),
    three   = transmute (rl.Color) u32be(0x544e68ff),
    four    = transmute (rl.Color) u32be(0x8d697aff),
    five    = transmute (rl.Color) u32be(0xd08159ff),
    six     = transmute (rl.Color) u32be(0xffaa5eff),
    seven   = transmute (rl.Color) u32be(0xffd4a3ff),
    eight   = transmute (rl.Color) u32be(0xffecd6ff),
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
    font: rl.Font,
    size: f32,
    spacing: f32,
} = {
    .anaheim_bold_64 = { file_id=.anaheim_bold_ttf, size=64, spacing=-2 },
    .anaheim_bold_32 = { file_id=.anaheim_bold_ttf, size=32, spacing=0 },
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
    panel_0,
    panel_3,
    panel_9,
}

sprite_assets: [Sprite_ID] struct {
    texture_id: Texture_ID,
    npatch: rl.NPatchInfo,
} = {
    .panel_0 = { npatch={ source={  1,145,48,48}, left=14, top=14, right=14, bottom=14, layout=.NINE_PATCH } },
    .panel_3 = { npatch={ source={148,145,48,48}, left=14, top=14, right=14, bottom=14, layout=.NINE_PATCH } },
    .panel_9 = { npatch={ source={442,145,48,48}, left=14, top=14, right=14, bottom=14, layout=.NINE_PATCH } },
}

load_assets :: proc () {
    for &font in font_assets {
        file := &file_assets[font.file_id]
        file_ext := fmt.ctprintf(".%s", file.type)
        font.font = rl.LoadFontFromMemory(file_ext, raw_data(file.data), i32(len(file.data)), i32(font.size), nil, 0)
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
        rl.UnloadFont(font.font)
        font.font = {}
    }

    for &texture in texture_assets {
        rl.UnloadTexture(texture.texture)
        texture.texture = {}
    }
}
