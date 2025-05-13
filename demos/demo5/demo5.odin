package demo5

import "core:fmt"
import "core:time"
import rl "vendor:raylib"
import "spacelib:core"
import "spacelib:terse"
import "spacelib:tracking_allocator"
import rl_sl "spacelib:raylib"
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

    // text ::
    //     "{top,left}Hello, LEFT!\n"+
    //     "{right}Hello, RIGHT!\n"+
    //     "{center}Hello, CENTER!\n\n"+
    //     "{color=gold}This text is colored GOLD{/color}\n"+
    //     "{color=olive}This text is colored OLIVE{/color}\n"+
    //     "{font=body_code,color=red}"+
    //         "This CODE text and it is colored RED\n"+
    //         "CODE is continued on this line: [OK]\n"+
    //     "{/font,/color}\n"+
    //     "{font=header,color=cyan}This is HEADER font colored CYAN{/font,/color}\n"+
    //     "{color=green}\nSome green body text goes here, and here, and here, and here, and even more text goes here...{/color} "+
    //     "And now this is default colored text. EOT."

    text0 :: "{top,color=white,font=header}{color=gold}1,234{icon=coins}{/color}\t{color=gray}56{icon=coins}{/color}\t{color=salmon}78{icon=coins}{/color}{/font}\n\n"
    text1 :: "{left}{group=group1}Lorem ipsum dolor{/group}: {color=salmon}{icon=fire}17 damage{/color} consectetur adipiscing elit. Praesent vitae aliquam libero. Praesent malesuada nulla: {font=body_code,color=green}id{color=gold}={/color}ex{color=gold}+{/color}sodales{font=body,/color} in auctor ex mattis. Praesent pretium iaculis bibendum. Morbi ultrices vehicula turpis, ac varius lacus scelerisque eu. Nunc accumsan, nisl quis ultrices ultrices, nibh nunc tincidunt urna, ac vulputate purus felis consequat metus."
    text2 :: "In {color=cyan}lacinia {font=body_bold}mauris sed{font=body} tempor {/color}tempor. Mauris lacus sem, consequat ac orci vitae, aliquam dapibus nunc. Nulla tempor mi eu quam facilisis sollicitudin. {group=group2}Quisque ultrices laoreet finibus. Proin non ligula mauris. Mauris molestie pellentesque pellentesque.{/group} Etiam volutpat vestibulum nisl, sit amet interdum tortor rutrum gravida."
    text3_s :: "{font=body_code}"
    text3_1 :: "{color=cyan}rl{/color,color=gray}.{/color,color=green}SetTraceLogLevel{/color,color=gray}(.WARNING){/color}\n"
    text3_2 :: "{color=cyan}rl{/color,color=gray}.{/color,color=green}InitWindow{/color,color=gray}({/color,color=olive}1280{/color,color=gray}, {/color,color=olive}720{/color,color=gray}, {color=gold}\"spacelib demo 5\"{/color,color=gray}){/color}\n"
    text3_3 :: "{color=green}assets_load{/color,color=gray}(){/color}\n"
    text3_4 :: "{color=brown}/* comments goes here */{/color}\n"
    text3_e :: "{/font}"
    text4 :: "Vestibulum {group=group3}gravida{/group} erat id lacus pretium semper. Morbi laoreet arcu augue, ac elementum ex porttitor id. Sed nec aliquam tortor. Fusce feugiat mollis tellus ut consectetur."
    text := text0 + text1 + "\n\n" + text2 + "\n\n" + text3_s+text3_1+text3_2+text3_3+text3_4+text3_e + "\n" + text4

    sw: time.Stopwatch

    for !rl.WindowShouldClose() {
        free_all(context.temp_allocator)

        time.stopwatch_reset(&sw)
        time.stopwatch_start(&sw)
        text_rect := Rect { 200, 50, f32(rl.GetScreenWidth())-400, 400 }
        text_terse := terse.create(text, text_rect, terse_query_font, terse_query_color, context.temp_allocator, debug_keep_codes=false)
        // defer terse.destroy(text_terse)
        time.stopwatch_stop(&sw)
        dur_measuring := time.stopwatch_duration(sw)

        rl.BeginDrawing()
        rl.ClearBackground({ 40, 40, 40, 255 })
        draw_rect_lines(core.rect_inflated(text_rect, {8,8}), 8, {40,40,255,255})

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
    if name == "" do return &font_default.font_tr
    for &font in fonts do if font.name == name do return &font.font_tr
    fmt.eprintfln("[!] Font not found: \"%v\"", name)
    return &font_default.font_tr
}

terse_query_color :: #force_inline proc (name: string) -> core.Color {
    if name == "" do return colors[.white].rgba
    for &color in colors do if color.name == name do return color.rgba
    fmt.eprintfln("[!] Color not found: \"%v\"", name)
    return colors[.white].rgba
}

draw_terse_text :: proc (text: ^terse.Text, debug := false) {
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
                pos := Vec2 { word.rect.x, word.rect.y }
                font := word.font
                font_rl := (cast (^rl.Font) font.font_ptr)^
                rl_sl.draw_text(word.text, pos, font_rl, font.height, font.letter_spacing, cast (rl.Color) word.color)
            }
        }
    }

    if debug {
        groups_color := rl.Color {255,0,255,200}
        for group in text.groups do for rect, i in group.line_rects {
            draw_rect_lines(rect, 3, groups_color)
            if i == 0 {
                font := rl.GetFontDefault()
                font_height := f32(20)
                font_spacing := f32(2)
                cstr := fmt.ctprint(group.name)
                size := rl.MeasureTextEx(font, cstr, font_height, font_spacing)
                draw_rect({rect.x,rect.y-size.y,size.x+4*2,size.y}, groups_color)
                rl_sl.draw_text(group.name, {rect.x+4,rect.y-font_height}, font, font_height, font_spacing, rl.ColorBrightness(groups_color, -.75))
            }
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

draw_rect :: proc (rect: Rect, tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleRec(rect_rl, tint)
}

draw_rect_lines :: proc (rect: Rect, thick := f32(1.0), tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleLinesEx(rect_rl, thick, tint)
}
