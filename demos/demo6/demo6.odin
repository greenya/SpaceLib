package demo6

import "core:fmt"
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:core/tracking_allocator"
import "spacelib:raylib/draw"
import "spacelib:terse"

import "res"

Vec2 :: core.Vec2
Rect :: core.Rect
Color :: core.Color

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print(.minimal_unless_issues)

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 6")
    rl.InitAudioDevice()

    res.create()

    res.play_music("groovy_saturday", vol=.333)

    for !rl.WindowShouldClose() {
        if rl.IsKeyPressed(.SPACE) {
            sounds := make([dynamic] string, context.temp_allocator)
            for name, audio in res.audios do #partial switch _ in audio.info {
            case rl.Sound: append(&sounds, name)
            }

            random_sound := rand.choice(sounds[:])
            res.play_sound(random_sound)
        }

        rl.BeginDrawing()
        rl.ClearBackground(res.color("deep_teal").rgba)

        { // draw colors
            font := res.font("default")
            for name, i in core.map_keys_sorted(res.colors, context.temp_allocator) {
                color := res.color(name)
                rect := Rect { 20,50, 150,20 }
                rect = core.rect_moved(rect, { 0,rect.h*f32(i) })
                draw.rect(rect, color)
                text_pos := core.rect_center(rect)
                draw.text(name, text_pos+{1,1}, .5, font, core.black)
                draw.text(name, text_pos      , .5, font, core.white)
            }
        }

        screen_w := f32(rl.GetScreenWidth())
        screen_h := f32(rl.GetScreenHeight())
        aside_w :: 512

        { // draw fonts
            tr_rect := Rect { 0,0,f32(rl.GetScreenWidth())-aside_w-30,f32(rl.GetScreenHeight()) }
            tr_rect = core.rect_inflated(tr_rect, {-100-50,-50})
            tr_rect = core.rect_moved(tr_rect, { 50,0 })
            draw_sprite("panel-border-004", core.rect_inflated(tr_rect, {20,20}), {0,255,0,255})

            sb := strings.builder_make(context.temp_allocator)
            strings.write_string(&sb, "<left,top>")
            for name, i in core.map_keys_sorted(res.fonts, context.temp_allocator) {
                clr := core.alpha(res.color("sand"), clamp(1.0 - .15*f32(i), 0, 1))
                font := res.font(name)
                fmt.sbprintf(&sb, "<wrap,font=%s,color=%s>", name, core.color_to_hex(clr, context.temp_allocator))
                fmt.sbprintf(&sb,
                    "<color=sky><icon=star></>" +
                    "<group=name,color=amber>%s</group,/color> " +
                    "(<group=size,color=orange>%v</group> px</color>): 1234567890\n" +
                    "The quick brown fox jumps over the lazy dog.",
                    name, font.height,
                )
                fmt.sbprint(&sb, "</font,/color>\n\n")
            }

            tr := terse.create(strings.to_string(sb), tr_rect, allocator=context.temp_allocator)
            if rl.IsKeyDown(.LEFT_CONTROL) do draw.debug_terse(tr)
            draw_terse(tr)
        }

        { // draw sprites
            scale :: .5
            tex := res.atlas.texture
            draw.texture_all(tex, { screen_w-aside_w-80, 80, f32(tex.width)*scale, f32(tex.height)*scale })
        }

        { // draw horizontal 3-patch sprite
            bt_height := res.sprite("square-yellow").info.(rl.NPatchInfo).source.height
            bt_rect := Rect { screen_w-aside_w-80, 280, aside_w, bt_height }
            draw_sprite("square-yellow", bt_rect)
            draw_terse(terse.create("<color=indigo>Press SPACE to play random sound", bt_rect, allocator=context.temp_allocator))
        }

        { // draw vertical 3-patch sprite
            bt_rect := Rect { screen_w-aside_w-80, 340, 0, 200 }
            draw_sprite("red-button-03", bt_rect)
        }

        { // draw bg music status
            text := fmt.tprintf("Background music (sec): %.1f / %.1f", res.music_played(), res.music_len())
            pos := [2] f32 { screen_w-aside_w, screen_h-80 }
            draw.text(text, pos, 0, res.font("default"), res.color("amber"))
        }

        rl.DrawFPS(10, 10)
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    res.destroy()

    rl.CloseAudioDevice()
    rl.CloseWindow()
}

draw_terse :: proc (tr: ^terse.Terse) {
    draw.terse(tr, draw_terse_icon)
}

draw_sprite :: proc (name: string, rect: Rect, tint := core.white) {
    sprite := res.sprite(name)
    texture := sprite.texture
    rect_rl := transmute (rl.Rectangle) rect
    tint_rl := cast (rl.Color) tint

    switch info in sprite.info {
    case Rect:          rl.DrawTexturePro(texture, transmute (rl.Rectangle) info, rect_rl, {}, 0, tint_rl)
    case rl.NPatchInfo: rl.DrawTextureNPatch(texture, info, rect_rl, {}, 0, tint_rl)
    }
}

draw_terse_icon :: proc (word: ^terse.Word) {
    draw_sprite(word.text, word.rect, word.color)
}
