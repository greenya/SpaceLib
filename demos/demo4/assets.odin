package demo4

import "core:fmt"
import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:terse"
import "spacelib:raylib/measure"

// ----------------
// ---- colors ----
// ----------------

Color_ID :: enum {
    white,
    black,
    undefined,
    c1,
    c2,
    c3,
    c4,
    c5,
    c6,
    c7,
    c8,
}

Color :: struct {
    name: string,
    val : core.Color,
}

colors := [Color_ID] Color {
    .white      = { "white",        transmute (core.Color) u32be((0xffffff<<8)|0xff) }, // #ffffff
    .black      = { "black",        transmute (core.Color) u32be((0x000000<<8)|0xff) }, // #000000
    .undefined  = { "undefined",    transmute (core.Color) u32be((0xff00ff<<8)|0xff) }, // #ff00ff
    // https://lospec.com/palette-list/gothic-bit
    .c1         = { "c1",           transmute (core.Color) u32be((0x0e0e12<<8)|0xff) }, // #0e0e12
    .c2         = { "c2",           transmute (core.Color) u32be((0x1a1a24<<8)|0xff) }, // #1a1a24
    .c3         = { "c3",           transmute (core.Color) u32be((0x333346<<8)|0xff) }, // #333346
    .c4         = { "c4",           transmute (core.Color) u32be((0x535373<<8)|0xff) }, // #535373
    .c5         = { "c5",           transmute (core.Color) u32be((0x8080a4<<8)|0xff) }, // #8080a4
    .c6         = { "c6",           transmute (core.Color) u32be((0xa6a6bf<<8)|0xff) }, // #a6a6bf
    .c7         = { "c7",           transmute (core.Color) u32be((0xc1c1d2<<8)|0xff) }, // #c1c1d2
    .c8         = { "c8",           transmute (core.Color) u32be((0xe6e6ec<<8)|0xff) }, // #e6e6ec
}

// ---------------
// ---- files ----
// ---------------

File_ID :: enum {
    anaheim_bold_ttf,
    ui_atlas_png,
    sheet_white2x_png,
}

File :: struct {
    type: string,
    data: [] u8,
}

files: [File_ID] File = {
    .anaheim_bold_ttf   = { "ttf", #load("assets/Anaheim-Bold.ttf") },
    .ui_atlas_png       = { "png", #load("assets/ui_atlas.png") },
    .sheet_white2x_png  = { "png", #load("assets/sheet_white2x.png") },
}

// ---------------
// ---- fonts ----
// ---------------

Font_ID :: enum {
    anaheim_bold_64,
    anaheim_bold_32,
}

Font :: struct {
    name            : string,
    file_id         : File_ID,
    font_rl         : rl.Font,
    using font_tr   : terse.Font,
}

fonts: [Font_ID] Font = {
    .anaheim_bold_64 = { name="anaheim_huge", file_id=.anaheim_bold_ttf, height=64, letter_spacing=-2, line_spacing=-8 },
    .anaheim_bold_32 = { name="anaheim_normal", file_id=.anaheim_bold_ttf, height=32, letter_spacing=0, line_spacing=-4 },
}

// ----------------------------
// ---- textures & sprites ----
// ----------------------------

Texture_ID :: enum {
    ui_atlas,
    sheet_white2x,
}

Texture :: struct {
    file_id: File_ID,
    texture_rl: rl.Texture,
}

textures: [Texture_ID] Texture = {
    .ui_atlas       = { file_id=.ui_atlas_png },
    .sheet_white2x  = { file_id=.sheet_white2x_png },
}

Sprite_ID :: enum {
    border_15,
    border_17,
    panel_0,
    panel_3,
    panel_4,
    panel_9,
    panel_15,
    icon_up,
    icon_down,
    icon_stop,
    icon_nav,
    icon_check,
    icon_cog,
    icon_exit,
    icon_info,
    icon_question,
    icon_play,
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
    .border_15      = { name="border_15",   texture_id=.ui_atlas, info=rl.NPatchInfo { source={736,  1,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .border_17      = {                     texture_id=.ui_atlas, info=rl.NPatchInfo { source={834,  1,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_0        = {                     texture_id=.ui_atlas, info=rl.NPatchInfo { source={  1,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_3        = {                     texture_id=.ui_atlas, info=rl.NPatchInfo { source={148,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_4        = {                     texture_id=.ui_atlas, info=rl.NPatchInfo { source={197,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_9        = {                     texture_id=.ui_atlas, info=rl.NPatchInfo { source={442,145,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .panel_15       = {                     texture_id=.ui_atlas, info=rl.NPatchInfo { source={736,  1,48,48}, left=16, top=16, right=16, bottom=16, layout=.NINE_PATCH } },
    .icon_up        = { name="up",          texture_id=.sheet_white2x, info=rl.Rectangle {100, 200,100,100} },
    .icon_down      = { name="down",        texture_id=.sheet_white2x, info=rl.Rectangle {400,1100,100,100} },
    .icon_stop      = { name="stop",        texture_id=.sheet_white2x, info=rl.Rectangle {100, 900,100,100} },
    .icon_nav       = { name="nav",         texture_id=.sheet_white2x, info=rl.Rectangle {100,1905,100,100} },
    .icon_check     = { name="check",       texture_id=.sheet_white2x, info=rl.Rectangle {400,1405,100,100} },
    .icon_cog       = { name="cog",         texture_id=.sheet_white2x, info=rl.Rectangle {300,1702,100,100} },
    .icon_exit      = { name="exit",        texture_id=.sheet_white2x, info=rl.Rectangle {400, 702,100,100} },
    .icon_info      = { name="info",        texture_id=.sheet_white2x, info=rl.Rectangle {300,1405,100,100} },
    .icon_question  = { name="question",    texture_id=.sheet_white2x, info=rl.Rectangle {200, 605,100,100} },
    .icon_play      = { name="play",        texture_id=.sheet_white2x, info=rl.Rectangle {300,1305,100,100} },
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
        font.measure_text = measure.text
        // rl.SetTextureFilter(font.font_rl.texture, .BILINEAR)
        // rl.GenTextureMipmaps(&font.font_rl.texture)
    }

    for &texture in textures {
        file := &files[texture.file_id]
        file_ext := fmt.ctprintf(".%s", file.type)
        image := rl.LoadImageFromMemory(file_ext, raw_data(file.data), i32(len(file.data)))
        texture.texture_rl = rl.LoadTextureFromImage(image)
        // rl.SetTextureFilter(texture.texture_rl, .BILINEAR)
        // rl.GenTextureMipmaps(&texture.texture_rl)
        rl.UnloadImage(image)
    }
}

assets_unload :: proc () {
    for &font in fonts {
        rl.UnloadFont(font.font_rl)
        font.font_rl = {}
    }

    for &texture in textures {
        rl.UnloadTexture(texture.texture_rl)
        texture.texture_rl = {}
    }
}

assets_color :: #force_inline proc (name: string) -> ^Color {
    if name == "" do return &colors[.undefined]
    for &color in colors do if color.name == name do return &color
    fmt.panicf("[!] Color not found: \"%v\"", name)
}

assets_font :: #force_inline proc (name: string) -> ^Font {
    if name == "" do return &fonts[.anaheim_bold_32]
    for &font in fonts do if font.name == name do return &font
    fmt.panicf("[!] Font not found: \"%v\"", name)
}

assets_sprite_id :: #force_inline proc (name: string) -> Sprite_ID {
    for sprite, id in sprites do if sprite.name == name do return id
    fmt.panicf("[!] Sprite not found: \"%v\"", name)
}
