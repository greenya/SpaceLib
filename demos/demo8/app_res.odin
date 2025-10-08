package demo8

import "core:fmt"
import "spacelib:core"
import "spacelib:raylib/res"
import "spacelib:terse"

App_Res :: struct {
    colors  : map [string] Color,
    fonts   : map [string] ^Font,
    atlas   : ^res.Atlas,
}

app_res_create :: proc () {
    app.res = new(App_Res)

    app_res_create_colors()
    app_res_create_fonts()
    app_res_create_sprites()

    terse.query_font = proc (name: string) -> ^terse.Font { return &font(name).font_tr }
    terse.query_color = proc (name: string) -> Color { return color(name) }
}

app_res_destroy :: proc () {
    delete(app.res.colors)

    for _, font in app.res.fonts do res.destroy_font(font)
    delete(app.res.fonts)

    res.destroy_atlas(app.res.atlas)

    free(app.res)
    app.res = nil
}

app_res_create_colors :: proc () {
    assert(app.res.colors == nil)

    c := &app.res.colors
    from_hex :: core.color_from_hex

    c["default"]        = core.red
    c["bw_00"]          = from_hex("#000000")
    c["bw_11"]          = from_hex("#111111")
    c["bw_18"]          = from_hex("#181818")
    c["bw_1a"]          = from_hex("#1a1a1a")
    c["bw_20"]          = from_hex("#202020")
    c["bw_2c"]          = from_hex("#2c2c2c")
    c["bw_40"]          = from_hex("#404040")
    c["bw_59"]          = from_hex("#595959")
    c["bw_6c"]          = from_hex("#6c6c6c")
    c["bw_95"]          = from_hex("#959595")
    c["bw_bc"]          = from_hex("#bcbcbc")
    c["bw_da"]          = from_hex("#dadada")
    c["bw_ff"]          = from_hex("#ffffff")

    c["weight_ar"]      = from_hex("#10b289") // air
    c["weight_lt"]      = from_hex("#71b465") // light
    c["weight_md"]      = from_hex("#af9759") // medium
    c["weight_hv"]      = from_hex("#c15000") // heavy

    c["res_bleed"]      = from_hex("#923e3e")
    c["res_fire"]       = from_hex("#a7773d")
    c["res_lightning"]  = from_hex("#6e6ea4")
    c["res_poison"]     = from_hex("#6baa5f")
    c["res_blight"]     = from_hex("#a5a5a5")

    c["trait_hl"]       = from_hex("#fff1bc")
    c["blight_rot"]     = from_hex("#d6a019")
}

app_res_create_fonts :: proc () {
    assert(app.res.fonts == nil)

    font_file_regular   := #load("res/fonts/Sansation-Regular.ttf")
    font_file_bold      := #load("res/fonts/Sansation-Bold.ttf")

    f := &app.res.fonts
    from_default    :: res.create_font_from_default
    from_data       :: res.create_font_from_data

    f["default"]        = from_default(height=20)
    f["text_16"]        = from_data(font_file_regular, height=16, filter=.BILINEAR)
    f["text_18"]        = from_data(font_file_regular, height=18, filter=.BILINEAR)
    f["text_18_bold"]   = from_data(font_file_bold, height=18, filter=.BILINEAR)
    f["text_20"]        = from_data(font_file_regular, height=20, filter=.BILINEAR)
    f["text_24"]        = from_data(font_file_bold, height=24, filter=.BILINEAR)
    f["text_24_sparse"] = from_data(font_file_bold, height=24, rune_spacing=.15, filter=.BILINEAR)
    f["text_32"]        = from_data(font_file_bold, height=32, filter=.BILINEAR)
    f["text_40"]        = from_data(font_file_bold, height=40, filter=.BILINEAR)
}

app_res_create_sprites :: proc () {
    assert(app.res.atlas == nil)

    app.res.atlas = res.create_atlas(
        files       = #load_directory("res/sprites"),
        size_limit  = { 1024, 2048 },
        gap         = 2,
        filter      = .BILINEAR,
    )
}

color :: #force_inline proc (name: string, a := f32(1), b := f32(0)) -> Color {
    fmt.assertf(name in app.res.colors, "Unknown color \"%s\"", name)
    result := app.res.colors[name]
    if a != 1 do result = core.alpha(result, a)
    if b != 0 do result = core.brightness(result, b)
    return result
}

font :: #force_inline proc (name: string) -> ^Font {
    fmt.assertf(name in app.res.fonts, "Unknown font \"%s\"", name)
    return app.res.fonts[name]
}

sprite :: #force_inline proc (name: string) -> ^Sprite {
    fmt.assertf(name in app.res.atlas.sprites, "Unknown sprite \"%s\"", name)
    return app.res.atlas.sprites[name]
}
