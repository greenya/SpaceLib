package demo5

import "core:fmt"
import "core:time"
import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:core/tracking_allocator"
import "spacelib:terse"
import "spacelib:raylib/draw"

_ :: fmt

Vec2 :: core.Vec2
Rect :: core.Rect

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print_report_with_issues_only()

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 5")
    assets_load()

    // ---- TEST #1 ----
    // text ::
    //     "<wrap,top,left>Hello, LEFT!\n"+
    //     "<right>Hello, RIGHT!\n"+
    //     "<center>Hello, CENTER!\n\n"+
    //     "<color=gold>This text is colored GOLD</color>\n"+
    //     "<color=olive>This text is colored OLIVE</color>\n"+
    //     "<font=body_code,color=red>"+
    //         "This CODE text and it is colored RED\n"+
    //         "CODE is continued on this line: [OK]\n"+
    //     "</font,/color>\n"+
    //     "<font=header,color=cyan>This is HEADER font colored CYAN</font,/color>\n"+
    //     "<color=green>\nSome green body text goes here, and here, and here, and here, and even more text goes here...</color> "+
    //     "And now this is default colored text. EOT."

    // ---- TEST #2 ----
    text0 :: "<wrap,top,color=white,font=header><color=gold>1,234<icon=coins></color>\t<color=gray>56<icon=coins></color>\t<color=salmon>78<icon=coins></color></font>\n\n"
    text1 :: "<left><group=group1>Lorem ipsum dolor</group>: <color=salmon><icon=fire>17 damage</color> consectetur adipiscing elit. Praesent vitae aliquam libero. Praesent malesuada nulla: <font=body_code,color=green>id<color=gold>=</color>ex<color=gold>+</color>sodales<font=body,/color> in auctor ex mattis. Praesent pretium iaculis bibendum."
    text2 :: "In <color=cyan>lacinia <font=body_bold>mauris sed<font=body> tempor </color>tempor. Mauris lacus sem, consequat ac orci vitae, aliquam dapibus nunc. Nulla tempor mi eu quam facilisis sollicitudin. <group=group2>Quisque ultrices laoreet finibus. Proin non ligula mauris. Mauris molestie pellentesque pellentesque.</group> Etiam volutpat vestibulum nisl."
    text3_s :: "<font=body_code>"
    text3_1 :: "<color=cyan>rl</color,color=gray>.</color,color=green>SetTraceLogLevel</color,color=gray>(.WARNING)</color>\n"
    text3_2 :: "<color=cyan>rl</color,color=gray>.</color,color=green>SetConfigFlags</color,color=gray>({ .WINDOW_RESIZABLE, .VSYNC_HINT })</color>\n"
    text3_3 :: "<color=cyan>rl</color,color=gray>.</color,color=green>InitWindow</color,color=gray>(</color,color=olive>1280</color,color=gray>, </color,color=olive>720</color,color=gray>, <color=gold>\"spacelib demo 5\"</color,color=gray>)</color>\n"
    text3_4 :: "<color=green>assets_load</color,color=gray>()</color>\n"
    text3_5 :: "<color=brown>/* comments goes here */</color>\n"
    text3_e :: "</font>"
    text4 :: "Vestibulum <group=group3>gravida</group> erat id lacus pretium semper. Morbi laoreet arcu augue, ac elementum ex porttitor id. Sed nec aliquam tortor. Fusce feugiat mollis tellus ut consectetur."
    text := text0 + text1 + "\n\n" + text2 + "\n\n" + text3_s+text3_1+text3_2+text3_3+text3_4+text3_5+text3_e + "\n" + text4

    sw: time.Stopwatch

    for !rl.WindowShouldClose() {
        free_all(context.temp_allocator)

        time.stopwatch_reset(&sw)
        time.stopwatch_start(&sw)
        text_rect := Rect { 200, 50, f32(rl.GetScreenWidth())-400, 600 }
        text_terse := terse.create(text, text_rect, terse_query_font, terse_query_color, allocator=context.temp_allocator)
        // defer terse.destroy(text_terse)
        time.stopwatch_stop(&sw)
        dur_measuring := time.stopwatch_duration(sw)

        rl.BeginDrawing()
        rl.ClearBackground({ 40, 40, 40, 255 })
        draw.rect_lines(core.rect_inflated(text_rect, {8,8}), 8, {40,40,255,255})

        time.stopwatch_reset(&sw)
        time.stopwatch_start(&sw)
        draw_terse_text(text_terse, debug=rl.IsKeyDown(.LEFT_CONTROL))
        time.stopwatch_stop(&sw)
        dur_drawing := time.stopwatch_duration(sw)

        cstr := fmt.ctprintf("measuring: %v\ndrawing: %v", dur_measuring, dur_drawing)
        rl.DrawText(cstr, 10, 30, 20, rl.GREEN)
        rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }

    assets_unload()
    rl.CloseWindow()
}

terse_query_font :: #force_inline proc (name: string) -> ^terse.Font {
    if name == terse.default_font_name do return &font_default.font_tr
    for &font in fonts do if font.name == name do return &font.font_tr
    fmt.eprintfln("[!] Font not found: \"%v\"", name)
    return &font_default.font_tr
}

terse_query_color :: #force_inline proc (name: string) -> core.Color {
    if name[0] == '#' do return core.color_from_hex(name)
    if name == terse.default_color_name do return colors[.white].val
    for &color in colors do if color.name == name do return color.val
    fmt.eprintfln("[!] Color not found: \"%v\"", name)
    return colors[.white].val
}

draw_terse_text :: proc (t: ^terse.Terse, debug := false) {
    if debug do draw.debug_terse(t)

    for word in t.words {
        if word.is_icon {
            for sprite, id in sprites {
                if sprite.name == word.text {
                    draw_sprite(id, word.rect, word.color.rgba)
                }
            }
        } else {
            pos := Vec2 { word.rect.x, word.rect.y }
            font := word.font
            font_rl := (cast (^rl.Font) font.font_ptr)^
            draw.text(word.text, pos, font_rl, font.height, font.rune_spacing, word.color)
        }
    }
}

draw_sprite :: proc (id: Sprite_ID, rect: Rect, tint := rl.WHITE) {
    sprite := &sprites[id]
    texture := &textures[sprite.texture_id]
    rect_rl := transmute (rl.Rectangle) rect

    switch info in sprite.info {
    case rl.Rectangle   : rl.DrawTexturePro(texture.texture, info, rect_rl, {}, 0, tint)
    case rl.NPatchInfo  : rl.DrawTextureNPatch(texture.texture, info, rect_rl, {}, 0, tint)
    }
}
