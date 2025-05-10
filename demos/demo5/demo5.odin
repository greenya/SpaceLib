package demo5

import "core:fmt"
import "core:time"
import rl "vendor:raylib"
import "spacelib:measured_text"
import rl_sl "spacelib:raylib"
import "spacelib:tracking_allocator"
import "spacelib:ui"
_ :: fmt

main :: proc () {
    context.allocator = tracking_allocator.init()
    defer tracking_allocator.print_report_with_issues_only()

    rl.SetTraceLogLevel(.WARNING)
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
    rl.InitWindow(1280, 720, "spacelib demo 5")
    assets_load()

    // text := "{top,left}Hello, LEFT!\n{right}Hello, RIGHT!\n{center}Hello, CENTER!\n\n{color=gold}This text is colored GOLD\n{color=olive}This text is colored OLIVE\n{color=red,font=body_code}This CODE text and it is colored RED\nCODE is continued on this line: [OK]\n\n{font=header,color=cyan}This is HEADER font colored CYAN\n{font=body,color=green}\nMore body text goes here... More body text goes here... More body text goes here... More body text goes here... More body text goes here... More body text goes here..."

    text0 :: "{top,font=header}{color=gold}1,234{icon=coins}\t{color=gray}56{icon=coins}\t{color=salmon}78{icon=coins}\n{font=body,color=white}\n"
    text1 :: "{left}Lorem ipsum dolor: {color=salmon} {icon=fire}17 damage{color=white} consectetur adipiscing elit. Praesent vitae aliquam libero. Praesent malesuada nulla: {font=body_code,color=green}id{color=gold}={color=green}ex{color=gold}+{color=green}sodales{font=body,color=white} in auctor ex mattis. Praesent pretium iaculis bibendum. Morbi ultrices vehicula turpis, ac varius lacus scelerisque eu. Nunc accumsan, nisl quis ultrices ultrices, nibh nunc tincidunt urna, ac vulputate purus felis consequat metus."
    text2 :: "In {color=cyan}lacinia {font=body_bold}mauris sed{font=body} tempor {color=white}tempor. Mauris lacus sem, consequat ac orci vitae, aliquam dapibus nunc. Nulla tempor mi eu quam facilisis sollicitudin. Quisque ultrices laoreet finibus. Proin non ligula mauris. Mauris molestie pellentesque pellentesque. Etiam volutpat vestibulum nisl, sit amet interdum tortor rutrum gravida."
    text3_s :: "{font=body_code}"
    text3_1 :: "{color=cyan}rl{color=gray}.{color=green}SetTraceLogLevel{color=gray}(.WARNING)\n"
    text3_2 :: "{color=cyan}rl{color=gray}.{color=green}InitWindow{color=gray}({color=olive}1280{color=gray}, {color=olive}720{color=gray}, {color=gold}\"spacelib demo 5\"{color=gray})\n"
    text3_3 :: "{color=green}assets_load{color=gray}()\n"
    text3_4 :: "{color=brown}/* comments goes here */\n"
    text3_e :: "{font=body,color=white}"
    text4 :: "Vestibulum gravida erat id lacus pretium semper. Morbi laoreet arcu augue, ac elementum ex porttitor id. Sed nec aliquam tortor. Fusce feugiat mollis tellus ut consectetur. Fusce mauris lorem, tempor a nunc vitae, facilisis porta odio. Nulla nec aliquet diam. Duis gravida diam eu turpis vulputate, vel iaculis nunc gravida. Etiam sit amet elementum augue. Quisque luctus pellentesque lacus, quis ullamcorper nisl."
    text := text0 + text1 + "\n\n" + text2 + "\n\n" + text3_s+text3_1+text3_2+text3_3+text3_4+text3_e + "\n" + text4

    // mrect1 := ui.Rect { 200, 100, 800, 400 }
    // mtext1 := measured_text.create(text, mrect1, measured_text_query_font, measured_text_query_color)
    // fmt.printfln("%#v", mtext1)

    sw: time.Stopwatch

    for !rl.WindowShouldClose() {
        free_all(context.temp_allocator)

        time.stopwatch_reset(&sw)
        time.stopwatch_start(&sw)
        mrect := ui.Rect { 200, 100, f32(rl.GetScreenWidth())-400, 400 }
        mtext := measured_text.create(text, mrect, measured_text_query_font, measured_text_query_color, context.temp_allocator, debug_keep_codes=false)
        time.stopwatch_stop(&sw)
        dur_measuring := time.stopwatch_duration(sw)

        rl.BeginDrawing()
        rl.ClearBackground({ 40, 40, 40, 255 })
        draw_rect_lines(ui.rect_inflated(mrect, {8,8}), 8, {40,40,255,255})

        time.stopwatch_reset(&sw)
        time.stopwatch_start(&sw)
        draw_measured_text(mtext, debug=rl.IsKeyDown(.LEFT_CONTROL))
        time.stopwatch_stop(&sw)
        dur_drawing := time.stopwatch_duration(sw)

        cstr := fmt.ctprintf("measuring: %v\ndrawing: %v", dur_measuring, dur_drawing)
        rl.DrawText(cstr, 10, 30, 20, rl.GREEN)
        rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }

    // measured_text.destroy(mtext1)

    assets_unload()
    rl.CloseWindow()
}

measured_text_query_font :: #force_inline proc (name: string) -> ^measured_text.Font {
    if name == "" do return &font_default.font_mt
    for &font in fonts do if font.name == name do return &font.font_mt
    fmt.eprintfln("[!] Font not found: \"%v\"", name)
    return &font_default.font_mt
}

measured_text_query_color :: #force_inline proc (name: string) -> ui.Color {
    if name == "" do return colors[.white].rgba
    for &color in colors do if color.name == name do return color.rgba
    fmt.eprintfln("[!] Color not found: \"%v\"", name)
    return colors[.white].rgba
}

draw_measured_text :: proc (text: ^measured_text.Text, debug := false) {
    if debug {
        draw_rect_lines(text.rect, 1, {255,0,0,160})
        draw_rect(text.rect, {255,0,0,20})
    }

    for line in text.lines {
        if debug do draw_rect_lines(line.rect, 1, {255,255,128,80})
        for word in line.words {
            if debug do draw_rect_lines(word.rect, 1, {255,255,0,40})
            if word.is_icon {
                for sprite, id in sprites {
                    if sprite.name == word.text {
                        draw_sprite(id, word.rect, word.color.rgba)
                    }
                }
            } else {
                pos := ui.Vec2 { word.rect.x, word.rect.y }
                font := word.font
                font_rl := (cast (^rl.Font) font.font_ptr)^
                rl_sl.draw_text(word.text, pos, font_rl, font.height, font.letter_spacing, cast (rl.Color) word.color)
            }
        }
    }
}

draw_sprite :: proc (id: Sprite_ID, rect: ui.Rect, tint := rl.WHITE) {
    sprite := &sprites[id]
    texture := &textures[sprite.texture_id]
    rect_rl := transmute (rl.Rectangle) rect

    switch info in sprite.info {
    case rl.Rectangle   : rl.DrawTexturePro(texture.texture, info, rect_rl, {}, 0, tint)
    case rl.NPatchInfo  : rl.DrawTextureNPatch(texture.texture, info, rect_rl, {}, 0, tint)
    }
}

draw_rect :: proc (rect: ui.Rect, tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleRec(rect_rl, tint)
}

draw_rect_lines :: proc (rect: ui.Rect, thick := f32(1.0), tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleLinesEx(rect_rl, thick, tint)
}
