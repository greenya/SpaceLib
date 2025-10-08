package demo10

import "spacelib:core"
import "spacelib:raylib/res"
import "spacelib:terse"

color_bg    :: core.gray2
color_panel :: core.gray4
color_text  :: core.gray7
color_hl    :: core.aqua

font_4: ^res.Font
font_5: ^res.Font
font_6: ^res.Font

res_init :: proc () {
    font_data := #load("res/Born2bSportyV2.ttf")
    font_4 = res.create_font_from_data(font_data, height=32)
    font_5 = res.create_font_from_data(font_data, height=48)
    font_6 = res.create_font_from_data(font_data, height=64)

    terse.query_font = proc (name: string) -> ^terse.Font {
        switch name {
        case "6": return &font_6.font_tr
        case "5": return &font_5.font_tr
        case    : return &font_4.font_tr
        }
    }

    terse.query_color = proc (name: string) -> core.Color {
        switch name {
        case "hl"   : return color_hl
        case        : return color_text
        }
    }
}

res_destroy :: proc () {
    res.destroy_font(font_4)
    res.destroy_font(font_5)
    res.destroy_font(font_6)
}
