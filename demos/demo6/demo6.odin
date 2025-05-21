package demo6

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:tracking_allocator"
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
    defer tracking_allocator.print_report_with_issues_only()

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 6")

    app.res = res.create()
    res.add_files(app.res, #load_directory("res/colors"))
    res.add_files(app.res, #load_directory("res/fonts"))
    res.add_files(app.res, #load_directory("res/sprites"))
    res.load_colors(app.res)
    res.load_fonts(app.res)
    res.load_sprites(app.res, texture_filter=.TRILINEAR)

    res.print(app.res)

    for !rl.WindowShouldClose() {
        free_all(context.temp_allocator)

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

        tex_rect: Rect
        { // draw sprites
            tex := app.res.textures["sprites"]
            tex_rect = { f32(rl.GetScreenWidth())-100-f32(tex.width), 50, f32(tex.width), f32(tex.height) }
            rl.DrawTextureV(tex.texture_rl, { tex_rect.x, tex_rect.y }, rl.WHITE)
            draw.rect_lines(tex_rect, 1, {255,255,0,255})
        }

        { // draw horizontal 3-patch sprite
            bt_height := app.res.sprites["square-yellow"].info.(rl.NPatchInfo).source.height
            bt_rect := Rect { tex_rect.x, tex_rect.y+tex_rect.h+20, tex_rect.w, bt_height }
            draw_sprite("square-yellow", bt_rect)
            draw_terse(create_terse("<color=indigo>Test 3-Patch Horizontal Texture", bt_rect, context.temp_allocator))
        }

        { // draw vertical 3-patch sprite
            bt_rect := Rect { tex_rect.x+tex_rect.w+20, tex_rect.y, 0, tex_rect.h }
            draw_sprite("red-button-03", bt_rect)
        }

        { // draw fonts
            tr_rect := Rect { 0,0,f32(rl.GetScreenWidth())-tex_rect.w-30,f32(rl.GetScreenHeight()) }
            tr_rect = core.rect_inflated(tr_rect, {-100-50,-50})
            tr_rect = core.rect_moved(tr_rect, { 50,0 })
            draw_sprite("panel-border-004", core.rect_inflated(tr_rect, {20,20}), {0,255,0,255})

            sb := strings.builder_make(context.temp_allocator)
            strings.write_string(&sb, "<left,top>")
            for name, i in core.map_keys_sorted(app.res.fonts, context.temp_allocator) {
                clr := core.alpha(app.res.colors["sand"], 1.0 - .15*f32(i))
                font := app.res.fonts[name]
                fmt.sbprintf(&sb, "<font=%s,color=%s>", name, core.color_to_hex(clr, context.temp_allocator))
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
        allocator,
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
    case rl.Rectangle:  rl.DrawTexturePro(texture.texture_rl, info, rect_rl, {}, 0, tint_rl)
    case rl.NPatchInfo: rl.DrawTextureNPatch(texture.texture_rl, info, rect_rl, {}, 0, tint_rl)
    }
}

draw_terse_icon :: proc (word: ^terse.Word) {
    draw_sprite(word.text, word.rect, word.color)
}
