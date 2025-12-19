package res

import "core:fmt"
import "spacelib:core"
import "spacelib:raylib/res"
import "spacelib:terse"

Vec2    :: core.Vec2
Rect    :: core.Rect
Color   :: core.Color
Sprite  :: res.Sprite
Font    :: res.Font
Audio   :: res.Audio

colors  : map [string] Color
fonts   : map [string] ^Font
atlas   : ^res.Atlas
audios  : map [string] ^Audio

music_thread: ^res.Music_Thread

create :: proc () {
    create_colors()
    create_fonts()
    create_sprites()
    create_audios()

    terse.query_font = proc (name: string) -> ^terse.Font { return &font(name).font_tr }
    terse.query_color = proc (name: string) -> Color { return color(name) }
}

destroy :: proc () {
    delete(colors)
    colors = nil

    for _, f in fonts do res.destroy_font(f)
    delete(fonts)
    fonts = nil

    res.destroy_atlas(atlas)
    atlas = nil

    res.destroy_music_thread(music_thread)
    music_thread = nil

    for _, a in audios do res.destroy_audio(a)
    delete(audios)
    audios = nil
}

create_colors :: proc () {
    assert(colors == nil)
    colors["default"]   = core.red
    colors["night"]     = core.color_from_hex("#181425")
    colors["indigo"]    = core.color_from_hex("#262b44")
    colors["plum"]      = core.color_from_hex("#3e2731")
    colors["deep_teal"] = core.color_from_hex("#193c3e")
    colors["hot_pink"]  = core.color_from_hex("#ff0044")
    colors["crimson"]   = core.color_from_hex("#a22633")
    colors["navy"]      = core.color_from_hex("#3a4466")
    colors["ocean"]     = core.color_from_hex("#124e89")
    colors["grape"]     = core.color_from_hex("#68386c")
    colors["brick"]     = core.color_from_hex("#733e39")
    colors["forest"]    = core.color_from_hex("#265c42")
    colors["scarlet"]   = core.color_from_hex("#e43b44")
    colors["rust"]      = core.color_from_hex("#be4a2f")
    colors["steel"]     = core.color_from_hex("#5a6988")
    colors["rose"]      = core.color_from_hex("#b55088")
    colors["leaf"]      = core.color_from_hex("#3e8948")
    colors["copper"]    = core.color_from_hex("#b86f50")
    colors["sky"]       = core.color_from_hex("#0099db")
    colors["clay"]      = core.color_from_hex("#d77643")
    colors["orange"]    = core.color_from_hex("#f77622")
    colors["mocha"]     = core.color_from_hex("#c28569")
    colors["coral"]     = core.color_from_hex("#f6757a")
    colors["slate"]     = core.color_from_hex("#8b9bb4")
    colors["lime"]      = core.color_from_hex("#63c74d")
    colors["tan"]       = core.color_from_hex("#e4a672")
    colors["amber"]     = core.color_from_hex("#feae34")
    colors["peach"]     = core.color_from_hex("#e8b796")
    colors["aqua"]      = core.color_from_hex("#2ce8f5")
    colors["mist"]      = core.color_from_hex("#c0cbdc")
    colors["sand"]      = core.color_from_hex("#ead4aa")
    colors["lemon"]     = core.color_from_hex("#fee761")
    colors["white"]     = core.color_from_hex("#ffffff")
}

create_fonts :: proc () {
    f_manrope   := #load("fonts/manrope-bold.ttf")
    f_oswald    := #load("fonts/oswald-light.ttf")
    f_righteous := #load("fonts/righteous-regular.ttf")
    f_roboto    := #load("fonts/roboto_mono-regular.ttf")

    assert(fonts == nil)
    fonts["default"]    = res.create_font_from_default(height=20)
    fonts["body"]       = res.create_font_from_data(f_oswald, height=28, rune_spacing=.02, line_spacing=-.25)
    fonts["body_lg"]    = res.create_font_from_data(f_oswald, height=36, rune_spacing=.02, line_spacing=-.25)
    fonts["body_hg"]    = res.create_font_from_data(f_oswald, height=48, rune_spacing=.02, line_spacing=-.25)
    fonts["code"]       = res.create_font_from_data(f_roboto, height=28, line_spacing=-.25)
    fonts["number_lg"]  = res.create_font_from_data(f_manrope, height=64, rune_spacing=.02, line_spacing=-.15)
    fonts["header"]     = res.create_font_from_data(f_righteous, height=80, line_spacing=-.15)
}

create_sprites :: proc () {
    assert(atlas == nil)
    atlas = res.gen_atlas_from_files(
        files       = #load_directory("sprites"),
        auto_patch  = true,
        filter      = .BILINEAR,
    )
}

create_audios :: proc () {
    assert(audios == nil)
    for file in #load_directory("audio") {
        name := res.file_name(file.name)
        audios[name] = res.create_audio(file)
    }

    assert(music_thread == nil)
    music_thread = res.create_music_thread()
}

play_music :: proc (name: string, vol := f32(1)) {
    audio := audio(name)
    res.set_music_vol(audio, vol)
    res.music_thread_play(music_thread, audio)
}

play_sound :: proc (name: string) {
    audio := audio(name)
    res.play_sound(audio)
}

color :: #force_inline proc (name: string, a := f32(1), b := f32(0)) -> Color {
    if name[0] == '#' do return core.color_from_hex(name)

    fmt.assertf(name in colors, "Unknown color \"%s\"", name)
    result := colors[name]
    if a != 1 do result = core.alpha(result, a)
    if b != 0 do result = core.brightness(result, b)
    return result
}

font :: #force_inline proc (name: string) -> ^Font {
    fmt.assertf(name in fonts, "Unknown font \"%s\"", name)
    return fonts[name]
}

sprite :: #force_inline proc (name: string) -> ^Sprite {
    fmt.assertf(name in atlas.sprites, "Unknown sprite \"%s\"", name)
    return atlas.sprites[name]
}

audio :: #force_inline proc (name: string) -> ^Audio {
    fmt.assertf(name in audios, "Unknown audio \"%s\"", name)
    return audios[name]
}

music_played    :: #force_inline proc () -> f32 { return res.music_played(music_thread.audio) }
music_len       :: #force_inline proc () -> f32 { return res.music_len(music_thread.audio) }
