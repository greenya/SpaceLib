package demo9_partials

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"
import "spacelib:terse"

import "../colors"
import "../fonts"

_ :: fmt

@private Vec2 :: core.Vec2
@private Rect :: core.Rect
@private Color :: core.Color

draw_terse :: proc (t: ^terse.Terse, color: Maybe(Color) = nil, offset := Vec2 {}, drop_shadow := false) {
    assert(t != nil)

    if drop_shadow do draw_terse(t, colors.bg0, {0,2})

    for word in t.words {
        // if word.in_group do continue

        rect := offset != {} ? core.rect_moved(word.rect, offset) : word.rect
        tint := color != nil ? color.? : word.color
        tint = core.alpha(tint, t.opacity)
        if word.is_icon {
            has_prefix :: strings.has_prefix
            if has_prefix(word.text, "key/")        do draw_icon_key(word.text[4:], rect, t.opacity)
            // else if has_prefix(word.text, "card.")  do draw_icon_card(word.text[5:], rect, t.opacity)
            // else                                    do draw_sprite(word.text, rect, tint)
        } else if word.text != " " {
            pos := Vec2 { rect.x, rect.y }
            font := word.font
            font_rl := (cast (^rl.Font) font.font_ptr)^
            draw.text(word.text, pos, font_rl, font.height, font.rune_spacing, tint)
        }
    }

    // if app.debug_drawing do draw.debug_terse(t)
}

draw_text_center :: proc (text: string, rect: Rect, font_name: string, color: Color) {
    font_tr := &fonts.get(font_name).font_tr
    draw.text_center(text, core.rect_center(rect), font_tr, color)
}

draw_icon_key :: proc (text: string, rect: Rect, opacity: f32) {
    bg_color := core.alpha(colors.primary, opacity)
    draw.rect(rect, bg_color)
    tx_color := core.alpha(colors.bg0, opacity)
    draw_text_center(text, rect, "text_4m", tx_color)
}

draw_hexagon_header :: proc (t: ^terse.Terse, limit_x, limit_w: f32) {
    // todo: maybe replace this madness with 3-patch horizontal sprite

    x1 := t.rect.x
    y1 := t.rect.y
    x2 := t.rect.x+t.rect.w
    y2 := t.rect.y+t.rect.h
    yc := (y1+y2)/2
    xl := x1-(yc-y1)
    xr := x2+(yc-y1)
    c := colors.primary

    // top and bottom lines
    draw.line({x1,y1}, {x2,y1}, 2, c)
    draw.line({x1,y2}, {x2,y2}, 2, c)

    // left corner
    draw.line({x1,y1}, {xl,yc}, 2, c)
    draw.line({x1,y2}, {xl,yc}, 2, c)

    // right corner
    draw.line({x2,y1}, {xr,yc}, 2, c)
    draw.line({x2,y2}, {xr,yc}, 2, c)

    // middle lines
    draw.rect_gradient({ x=limit_x, y=yc-1, w=xl-limit_x, h=3 }, {}, c, {}, c)
    draw.rect_gradient({ x=xr, y=yc-1, w=limit_x+limit_w-xr, h=3 }, c, {}, c, {})

    draw_terse(t, drop_shadow=true)
}

draw_color_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.get(f.text), f.opacity)
    draw.rect(f.rect, color)
}

draw_button :: proc (f: ^ui.Frame) {
    offset := f.captured ? Vec2 {0,2} : {}
    draw_terse(f.terse, offset=offset)

    ln_color := core.alpha(f.entered ? colors.accent : colors.primary, f.opacity)
    ln_rect := core.rect_moved(f.rect, offset)
    draw.rect_lines(ln_rect, 1, ln_color)
}

draw_pyramid_button :: proc (f: ^ui.Frame) {
    draw.rect_lines(f.rect, 2, f.entered ? colors.accent : colors.primary)
}

draw_pyramid_button_title :: proc (f: ^ui.Frame) {
    button_rect := f.parent.rect
    draw_hexagon_header(f.terse, button_rect.x, button_rect.w)
}

draw_screen_tab :: proc (f: ^ui.Frame) {
    if f.selected {
        bg_color := core.alpha(colors.accent, f.opacity * .5)
        draw.rect_gradient(f.rect, {}, {}, bg_color, bg_color)

        br_color := core.alpha(colors.accent, f.opacity)
        br_rect := core.rect_line_bottom(f.rect, 4)
        draw.rect(br_rect, br_color)

        draw.rect_gradient(core.rect_line_left(f.rect, 1), {}, {}, br_color, br_color)
        draw.rect_gradient(core.rect_line_right(f.rect, 1), {}, {}, br_color, br_color)
    } else {
        hover_ratio := ui.hover_ratio(f, .Cubic_Out, .222, .Cubic_In, .333)
        bg_color := core.alpha(colors.accent, f.opacity * .4 * hover_ratio)
        draw.rect_gradient(f.rect, {}, {}, bg_color, bg_color)
    }

    draw_terse(f.terse, f.selected ? colors.accent : colors.primary, drop_shadow=true)
}

draw_screen_tab_points :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(colors.primary, f.opacity)
    draw.rect(f.rect, bg_color)
    br_color := core.brightness(bg_color, -.555)
    draw.rect_lines(f.rect, 2, br_color)
    draw_terse(f.terse)
}
