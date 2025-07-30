package demo6

import "core:fmt"
import "core:math/rand"
import "core:slice"
import "core:strings"
import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:core/tracking_allocator"
import "spacelib:raylib/draw"
import "spacelib:raylib/res"
import "spacelib:terse"

Vec2 :: core.Vec2
Rect :: core.Rect
Color :: core.Color

app: struct {
    res: ^res.Res,
}

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print(.minimal_unless_issues)

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 6")
    rl.InitAudioDevice()

    app.res = res.create()

    res.add_files(app.res, #load_directory("res/colors"))
    res.add_files(app.res, #load_directory("res/fonts"))
    res.add_files(app.res, #load_directory("res/sprites"))
    res.add_files(app.res, #load_directory("res/audio"))

    res.load_colors(app.res)
    res.load_fonts(app.res)
    res.load_sprites(app.res, texture_filter=.BILINEAR)
    res.load_audio(app.res)

    res.print(app.res)

    bg_music := app.res.music["groovy_saturday"]
    rl.SetMusicVolume(bg_music, .333)
    rl.PlayMusicStream(bg_music)

    for !rl.WindowShouldClose() {
        free_all(context.temp_allocator)

        rl.UpdateMusicStream(bg_music)

        if rl.IsKeyPressed(.SPACE) {
            sounds, _ := slice.map_values(app.res.sounds, context.temp_allocator)
            rl.PlaySound(rand.choice(sounds))
        }

        rl.BeginDrawing()
        rl.ClearBackground(app.res.colors["deep_teal"].value.rgba)

        { // draw colors
            font := app.res.fonts["default"]
            for name, i in core.map_keys_sorted(app.res.colors, context.temp_allocator) {
                color := app.res.colors[name]
                rect := Rect { 20,50,150,20 }
                rect = core.rect_moved(rect, { 0,rect.h*f32(i) })
                draw.rect(rect, color)
                text_pos := core.rect_center(rect)
                draw.text_center(name, text_pos+{1,1}   , font, Color {0,0,0,128})
                draw.text_center(name, text_pos         , font, Color {255,255,255,255})
            }
        }

        screen_w := f32(rl.GetScreenWidth())
        // screen_h := f32(rl.GetScreenHeight())

        { // draw sprites
            draw.debug_res_texture(app.res, "sprites", { screen_w-512-80, 80 }, .5 )
        }

        { // draw horizontal 3-patch sprite
            bt_height := app.res.sprites["square-yellow"].info.(rl.NPatchInfo).source.height
            bt_rect := Rect { screen_w-512-80, 280, 512, bt_height }
            draw_sprite("square-yellow", bt_rect)
            draw_terse(create_terse("<color=indigo>Press SPACE to play random sound", bt_rect, context.temp_allocator))
        }

        { // draw vertical 3-patch sprite
            bt_rect := Rect { screen_w-512-80, 340, 0, 200 }
            draw_sprite("red-button-03", bt_rect)
        }

        { // draw fonts
            tr_rect := Rect { 0,0,f32(rl.GetScreenWidth())-512-30,f32(rl.GetScreenHeight()) }
            tr_rect = core.rect_inflated(tr_rect, {-100-50,-50})
            tr_rect = core.rect_moved(tr_rect, { 50,0 })
            draw_sprite("panel-border-004", core.rect_inflated(tr_rect, {20,20}), {0,255,0,255})

            sb := strings.builder_make(context.temp_allocator)
            strings.write_string(&sb, "<left,top>")
            for name, i in core.map_keys_sorted(app.res.fonts, context.temp_allocator) {
                clr := core.alpha(app.res.colors["sand"], clamp(1.0 - .15*f32(i), 0, 1))
                font := app.res.fonts[name]
                fmt.sbprintf(&sb, "<wrap,font=%s,color=%s>", name, core.color_to_hex(clr, context.temp_allocator))
                fmt.sbprintf(&sb, "<color=sky><icon=star></color><group=name,color=amber>%s</group,/color> (<group=size,color=orange>%v</group> px</color>): 1234567890\nThe quick brown fox jumps over the lazy dog.", name, font.height)
                fmt.sbprint(&sb, "</font,/color>\n\n")
            }

            tr := create_terse(strings.to_string(sb), tr_rect, context.temp_allocator)
            if rl.IsKeyDown(.LEFT_CONTROL) do draw.debug_terse(tr)
            draw_terse(tr)
        }

        rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }

    res.destroy(app.res)

    rl.CloseAudioDevice()
    rl.CloseWindow()
}

create_terse :: proc (text: string, rect: Rect, allocator := context.allocator) -> ^terse.Terse {
    return terse.create(
        text,
        rect,
        #force_inline proc (name: string) -> ^terse.Font {
            fmt.assertf(name in app.res.fonts, "No font with name \"%s\"", name)
            return &app.res.fonts[name].font_tr
        },
        #force_inline proc (name: string) -> Color {
            if name[0] == '#' do return core.color_from_hex(name)
            fmt.assertf(name in app.res.colors, "No color with name \"%s\"", name)
            return app.res.colors[name]
        },
        allocator=allocator,
    )
}

draw_terse :: proc (tr: ^terse.Terse) {
    draw.terse(tr, draw_terse_icon)
}

draw_sprite :: proc (name: string, rect: Rect, tint := Color {255,255,255,255}) {
    assert(name in app.res.sprites)
    sprite := app.res.sprites[name]
    texture := app.res.textures[sprite.texture]
    rect_rl := transmute (rl.Rectangle) rect
    tint_rl := cast (rl.Color) tint

    switch info in sprite.info {
    case Rect:          rl.DrawTexturePro(texture.texture_rl, transmute (rl.Rectangle) info, rect_rl, {}, 0, tint_rl)
    case rl.NPatchInfo: rl.DrawTextureNPatch(texture.texture_rl, info, rect_rl, {}, 0, tint_rl)
    }
}

draw_terse_icon :: proc (word: ^terse.Word) {
    draw_sprite(word.text, word.rect, word.color)
}
