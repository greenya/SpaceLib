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

    app.res = res.create_resources()
    res.add_files(app.res, #load_directory("res/fonts"))
    res.add_files(app.res, #load_directory("res/sprites"))
    res.reload_fonts(app.res)
    res.reload_sprites(app.res)

    res.print_resources(app.res)

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
            bt_rect := Rect { tex_rect.x+tex_rect.w+30, tex_rect.y, 40, tex_rect.h }
            draw_sprite("red-button-03", bt_rect)
        }

        rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }

    res.destroy_resources(app.res)

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

/* -----------------------

app: struct {
    screen: struct {
        rect: Rect,
        render_rect: Rect,
        scale: f32,
        size_i: [2] i32,
    },
}

main :: proc () {
    app.screen.rect = { 0,0,1280,720 }
    app.screen.render_rect = app.screen.rect
    ...
    rl.InitWindow(i32(app.screen.rect.w), i32(app.screen.rect.h), "spacelib demo 6")

    { -- rendering

        {
            size_i := [2] i32 { rl.GetScreenWidth(), rl.GetScreenHeight() }
            if app.screen.size_i != size_i {
                new_scale, new_render_rect := screen_scale({ f32(size_i.x),f32(size_i.y) }, { 1280,720 })
                fmt.printfln("Screen size: %v x %v, scale: %v", size_i.x, size_i.y, new_scale)
                res.reload_fonts(app.res, new_scale)
                app.screen.size_i = size_i
                app.screen.scale = new_scale
                app.screen.render_rect = new_render_rect
                app.screen.rect.w *= new_scale
                app.screen.rect.h *= new_scale
            }
        }

        ... maybe: add scissor ?
        ... maybe: add scale camera zoom ?

        camera := rl.Camera2D { zoom=1 }
        camera.offset = { app.screen.render_rect.x, app.screen.render_rect.y }
        rl.BeginMode2D(camera)
        rl.BeginScissorMode(i32(app.screen.render_rect.x), i32(app.screen.render_rect.y), i32(app.screen.render_rect.w), i32(app.screen.render_rect.h))
        rl.ClearBackground({ 20,40,30,255 })
        draw.rect_lines(app.screen.rect, 2, {200,100,50,255})
        draw.rect_lines(core.rect_inflated(app.screen.rect, {-4,-4}), 2, {200,100,50,255})

        ...

        rl.EndScissorMode()
        rl.EndMode2D()
    }
}

screen_scale :: #force_inline proc (screen: Vec2, target: Vec2) -> (scale: f32, render: Rect) {
    scale = min(screen.x/target.x, screen.y/target.y)
    render_w, render_h := target.x*scale, target.y*scale
    render = {
        (screen.x - render_w)/2,
        (screen.y - render_h)/2,
        render_w,
        render_h,
    }
    return
}

--------------------------- */
