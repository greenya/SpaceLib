package demo5

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:measured_text"
import rl_sl "spacelib:raylib"
import "spacelib:ui"

// ----------------
// ---- colors ----
// ----------------

Color_ID :: enum {
    black,
    gray,
    white,
    brown,
    salmon,
    peach,
    apricot,
    navy,
    teal,
    cyan,
    forest,
    green,
    olive,
    gold,
    maroon,
    red,
}

Color :: struct {
    name: string,
    rgba: ui.Color,
}

// https://lospec.com/palette-list/possessioner-pc-98
colors := [Color_ID] Color {
    .black      = { "black",     transmute (ui.Color) u32be((0x000000<<8)|0xff) }, // #000000
    .gray       = { "gray",      transmute (ui.Color) u32be((0xbababa<<8)|0xff) }, // #bababa
    .white      = { "white",     transmute (ui.Color) u32be((0xfefefe<<8)|0xff) }, // #fefefe
    .brown      = { "brown",     transmute (ui.Color) u32be((0x894523<<8)|0xff) }, // #894523
    .salmon     = { "salmon",    transmute (ui.Color) u32be((0xcd6754<<8)|0xff) }, // #cd6754
    .peach      = { "peach",     transmute (ui.Color) u32be((0xef9889<<8)|0xff) }, // #ef9889
    .apricot    = { "apricot",   transmute (ui.Color) u32be((0xfebaab<<8)|0xff) }, // #febaab
    .navy       = { "navy",      transmute (ui.Color) u32be((0x013267<<8)|0xff) }, // #013267
    .teal       = { "teal",      transmute (ui.Color) u32be((0x237689<<8)|0xff) }, // #237689
    .cyan       = { "cyan",      transmute (ui.Color) u32be((0x23abba<<8)|0xff) }, // #23abba
    .forest     = { "forest",    transmute (ui.Color) u32be((0x457645<<8)|0xff) }, // #457645
    .green      = { "green",     transmute (ui.Color) u32be((0x239845<<8)|0xff) }, // #239845
    .olive      = { "olive",     transmute (ui.Color) u32be((0x9cba8c<<8)|0xff) }, // #9cba8c
    .gold       = { "gold",      transmute (ui.Color) u32be((0xfecd01<<8)|0xff) }, // #fecd01
    .maroon     = { "maroon",    transmute (ui.Color) u32be((0x730031<<8)|0xff) }, // #730031
    .red        = { "red",       transmute (ui.Color) u32be((0xef0101<<8)|0xff) }, // #ef0101
}

// ---------------
// ---- files ----
// ---------------

File_ID :: enum {
    manrope_bold_ttf,
    manrope_regular_ttf,
    righteous_regular_ttf,
    roboto_mono_regular_ttf,
    icons_png,
}

File :: struct {
    type: string,
    data: [] u8,
}

files: [File_ID] File = {
    .manrope_bold_ttf       = { "ttf", #load("assets/Manrope-Bold.ttf") },
    .manrope_regular_ttf    = { "ttf", #load("assets/Manrope-Regular.ttf") },
    .righteous_regular_ttf  = { "ttf", #load("assets/Righteous-Regular.ttf") },
    .roboto_mono_regular_ttf= { "ttf", #load("assets/RobotoMono-Regular.ttf") },
    .icons_png              = { "png", #load("assets/icons.png") },
}

// ---------------
// ---- fonts ----
// ---------------

Font_ID :: enum {
    body,
    body_bold,
    body_code,
    header,
}

Font :: struct {
    name            : string,
    file_id         : File_ID,
    font_rl         : rl.Font,
    using font_mt   : measured_text.Font,
}

fonts: [Font_ID] Font = {
    .body       = { name="body",        file_id=.manrope_regular_ttf,       height=32, letter_spacing=0, line_spacing=-4 },
    .body_bold  = { name="body_bold",   file_id=.manrope_bold_ttf,          height=32, letter_spacing=0, line_spacing=-4 },
    .body_code  = { name="body_code",   file_id=.roboto_mono_regular_ttf,   height=32, letter_spacing=0, line_spacing=-4 },
    .header     = { name="header",      file_id=.righteous_regular_ttf,     height=80, letter_spacing=0, line_spacing=-20 },
}

font_default := &fonts[.body]

// ----------------------------
// ---- textures & sprites ----
// ----------------------------

Texture_ID :: enum {
    icons,
}

Texture :: struct {
    file_id: File_ID,
    texture: rl.Texture,
}

textures: [Texture_ID] Texture = {
    .icons = { file_id=.icons_png },
}

Sprite_ID :: enum {
    icon_fire,
    icon_coins,
}

Sprite :: struct {
    name        : string,
    texture_id  : Texture_ID,
    info: union {
        rl.Rectangle,
        rl.NPatchInfo,
    },
}

sprites: [Sprite_ID] Sprite = {
    .icon_fire  = { name="fire",    texture_id=.icons, info=rl.Rectangle {  0,  0,128,128} },
    .icon_coins = { name="coins",   texture_id=.icons, info=rl.Rectangle {128,  0,128,128} },
}

// ---------------
// ---- procs ----
// ---------------

assets_load :: proc () {
    for &font in fonts {
        file := &files[font.file_id]
        file_ext := fmt.ctprintf(".%s", file.type)
        font.font_rl = rl.LoadFontFromMemory(file_ext, raw_data(file.data), i32(len(file.data)), i32(font.height), nil, 0)
        font.font_ptr = &font.font_rl
        font.measure_text = rl_sl.measure_text2
    }

    for &texture in textures {
        file := &files[texture.file_id]
        file_ext := fmt.ctprintf(".%s", file.type)
        image := rl.LoadImageFromMemory(file_ext, raw_data(file.data), i32(len(file.data)))
        texture.texture = rl.LoadTextureFromImage(image)
        rl.UnloadImage(image)
    }
}

assets_unload :: proc () {
    for &font in fonts {
        rl.UnloadFont(font.font_rl)
        font.font_rl = {}
    }

    for &texture in textures {
        rl.UnloadTexture(texture.texture)
        texture.texture = {}
    }
}
