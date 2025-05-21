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
    res.add_files(app.res, #load_directory("res/fonts"))
    res.add_files(app.res, #load_directory("res/sprites"))
    res.reload_fonts(app.res)
    res.reload_sprites(app.res)

    res.print(app.res)

    for !rl.WindowShouldClose() {
        free_all(context.temp_allocator)

        rl.BeginDrawing()
        rl.ClearBackground({ 20,40,30,255 })

        tr_rect := core.rect_inflated({ 0,0,f32(rl.GetScreenWidth()),f32(rl.GetScreenHeight()) }, {-100,-50})
        draw_sprite("panel-border-004", core.rect_inflated(tr_rect, {20,20}), {0,255,0,255})

        sb := strings.builder_make(context.temp_allocator)
        strings.write_string(&sb, "<left,top>")
        for name in core.map_keys_sorted(app.res.fonts, context.temp_allocator) {
            font := app.res.fonts[name]
            fmt.sbprintf(&sb, "<font=%s>", name)
            fmt.sbprintf(&sb, "<icon=star><group=name>%s</group> (<group=size>%v</group> px): 1234567890\nThe quick brown fox jumps over the lazy dog.", name, font.height)
            fmt.sbprint(&sb, "</font>\n\n")
        }

        tr := create_terse(strings.to_string(sb), tr_rect, context.temp_allocator)

        if rl.IsKeyDown(.LEFT_CONTROL) do draw.debug_terse(tr)
        draw_terse(tr)

        tex := app.res.textures["sprites"]
        tex_rect := Rect { f32(rl.GetScreenWidth())-100-f32(tex.width), 50, f32(tex.width), f32(tex.height) }
        rl.DrawTextureV(tex.texture_rl, { tex_rect.x, tex_rect.y }, rl.WHITE)
        draw.rect_lines(tex_rect, 1, {255,255,0,255})

        {
            bt_height := app.res.sprites["square-yellow"].info.(rl.NPatchInfo).source.height
            bt_rect := Rect { tex_rect.x, tex_rect.y+tex_rect.h+20, tex_rect.w, bt_height }
            draw_sprite("square-yellow", bt_rect, {160,80,120,255})
            draw_terse(create_terse("Test 3-Patch Horizontal Texture", bt_rect, context.temp_allocator))
        }

        {
            bt_rect := Rect { tex_rect.x+tex_rect.w+30, tex_rect.y, 0, tex_rect.h }
            draw_sprite("red-button-03", bt_rect)
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
        #force_inline proc (name: string) -> ^terse.Font { return &app.res.fonts[name].font_tr },
        #force_inline proc (name: string) -> Color { return { 255,255,255,255 } },
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
