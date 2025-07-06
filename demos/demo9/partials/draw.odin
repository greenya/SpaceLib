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
import "../sprites"

_ :: fmt

@private Vec2 :: core.Vec2
@private Rect :: core.Rect
@private Color :: core.Color

draw_sprite :: proc (name: string, rect: Rect, tint: Color) {
    sprite := sprites.get(name)
    switch info in sprite.info {
    case Rect           : if sprite.wrap    do draw.texture_wrap    (sprite.tex^, info, rect, tint=tint)
                          else              do draw.texture         (sprite.tex^, info, rect, tint=tint)
    case rl.NPatchInfo  :                      draw.texture_npatch  (sprite.tex^, info, rect, tint=tint)
    }
}

draw_terse :: proc (t: ^terse.Terse, color: Maybe(Color) = nil, offset := Vec2 {}, drop_shadow := false) {
    assert(t != nil)

    if drop_shadow do draw_terse(t, colors.bg0, offset={0,2})

    for word in t.words {
        rect := offset != {} ? core.rect_moved(word.rect, offset) : word.rect
        if core.rect_intersection(rect, t.scissor) == {} do continue

        tint := color != nil ? color.? : word.color
        tint = core.alpha(tint, t.opacity)

        if word.is_icon {
            if      strings.has_prefix(word.text, "key/")   do draw_icon_key(word.text[4:], rect, t.opacity, .box)
            else if strings.has_prefix(word.text, "key2/")  do draw_icon_key(word.text[5:], rect, t.opacity, .diamond)
            else                                            do draw_sprite(word.text, rect, tint)
        } else if word.text != "" && word.text != " " {
            draw.text(word.text, {rect.x,rect.y}, word.font, tint)
        }
    }

    if rl.IsKeyDown(.LEFT_CONTROL) do draw.debug_terse(t)
}

draw_text_center :: proc (text: string, rect: Rect, font: string, color: Color) {
    font_tr := &fonts.get(font).font_tr
    draw.text_center(text, core.rect_center(rect), font_tr, color)
}

draw_icon_key :: proc (text: string, rect: Rect, opacity: f32, shape: enum { box, diamond }) {
    bg_color := core.alpha(colors.primary, opacity * .75)
    switch shape {
    case .box       : draw.rect_rounded(rect, .3, 4, bg_color)
    case .diamond   : draw.diamond(rect, bg_color)
    }
    tx_color := core.alpha(colors.bg0, opacity)
    draw_text_center(text, rect, "text_4m", tx_color)
}

draw_hexagon_header :: proc (t: ^terse.Terse, rect: Rect, limit_x, limit_w: f32, bg_opacity := f32(1)) {
    x1 := rect.x
    y1 := rect.y
    x2 := rect.x+rect.w
    y2 := rect.y+rect.h
    yc := (y1+y2)/2
    xl := x1-(yc-y1)
    xr := x2+(yc-y1)
    th := f32(1)
    c := core.alpha(colors.primary, t.opacity)

    // background
    bg_color := core.alpha(colors.bg1, t.opacity * bg_opacity)
    draw.triangle_fan({ {x1,yc}, {x1,y1}, {xl,yc}, {x1,y2}, {x2,y2}, {xr,yc}, {x2,y1}, {x1,y1} }, bg_color)

    // top and bottom lines
    draw.line({x1,y1}, {x2,y1}, th, c)
    draw.line({x1,y2}, {x2,y2}, th, c)

    // left corner
    draw.line({x1,y1}, {xl,yc}, th, c)
    draw.line({x1,y2}, {xl,yc}, th, c)

    // right corner
    draw.line({x2,y1}, {xr,yc}, th, c)
    draw.line({x2,y2}, {xr,yc}, th, c)

    // middle lines
    if limit_x<xl           do draw.rect_gradient_horizontal({ x=limit_x, y=yc-1, w=xl-limit_x, h=th }, {}, c)
    if limit_x+limit_w>xr   do draw.rect_gradient_horizontal({ x=xr, y=yc-1, w=limit_x+limit_w-xr, h=th }, c, {})

    draw_terse(t, drop_shadow=true)
}

draw_color_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.get(f.text), f.opacity)
    draw.rect(f.rect, color)
}

draw_image_placeholder :: proc (f: ^ui.Frame) {
    bg_color := core.alpha({20,20,20,255}, f.opacity)
    draw.rect(f.rect, bg_color)

    tx_color := core.alpha({60,60,60,255}, f.opacity)
    draw_text_center("IMAGE PLACEHOLDER", f.rect, "text_4l", tx_color)
}

draw_hexagon_rect :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    draw_hexagon_header(f.terse, f.terse.rect, parent_rect.x, parent_rect.w)
}

draw_hexagon_rect_wide :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    draw_hexagon_header(f.terse, f.rect, parent_rect.x, parent_rect.w)
}

draw_hexagon_rect_with_half_transparent_bg :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    draw_hexagon_header(f.terse, f.terse.rect, parent_rect.x, parent_rect.w, bg_opacity=.5)
}

draw_gradient_fade_down_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.get(f.text), f.opacity)
    draw.rect_gradient_vertical(f.rect, color, {})
}

draw_gradient_fade_up_and_down_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.get(f.text), f.opacity)
    draw.rect_gradient_vertical(core.rect_half_top(f.rect), {}, color)
    draw.rect_gradient_vertical(core.rect_half_bottom(f.rect), color, {})
}

draw_button :: proc (f: ^ui.Frame) {
    offset := f.captured ? Vec2 {0,2} : {}
    rect := core.rect_moved(f.rect, offset)
    hv_ratio := ui.hover_ratio(f, .Linear, .155, .Linear, .155)

    bg_top_color := core.brightness(colors.primary, -.9*(1-hv_ratio*.3))
    bg_bottom_color := core.brightness(colors.bg1, -.9)
    if f.captured do bg_top_color, bg_bottom_color = bg_bottom_color, bg_top_color
    draw.rect_gradient_vertical(rect, bg_top_color, bg_bottom_color)

    ln_color := core.alpha(colors.primary, f.opacity*.3 + hv_ratio*.7)
    draw.rect_lines(rect, 1, ln_color)

    draw_terse(f.terse, offset=offset)
}

draw_featured_button :: proc (f: ^ui.Frame) {
    rect := core.rect_inflated(f.rect, f.captured ? -2 : 0)
    hv_ratio := ui.hover_ratio(f, .Cubic_Out, .333, .Cubic_In, .333)

    if hv_ratio > 0 {
        cr_center := f.ui.mouse.pos
        cr_radius := f.rect.h * 1.777
        cr_inner_color := core.alpha(colors.accent, hv_ratio * .3)
        draw.circle_gradient(cr_center, cr_radius, cr_inner_color, {})
    }

    bg_color := core.brightness(core.alpha(colors.accent, .5), -.8 + hv_ratio/3)
    draw.rect(rect, bg_color)

    br_color := core.alpha(colors.primary, f.opacity*.3 + hv_ratio*.7)
    draw.rect_lines(rect, 1 + hv_ratio*2, br_color)

    ln_rect := core.rect_inflated(rect, 2 + (1-hv_ratio)*10)
    ln_color := core.alpha(br_color, hv_ratio)
    draw.rect_lines(ln_rect, 1, ln_color)

    tx_color := core.brightness(colors.primary, hv_ratio/2)
    draw_terse(f.terse, tx_color, drop_shadow=true)
}

draw_diamond_button :: proc (f: ^ui.Frame) {
    hv_ratio := ui.hover_ratio(f, .Linear, .111, .Linear, .111)
    rect := core.rect_inflated(f.rect, hv_ratio*5)

    draw.diamond(rect, colors.bg1)

    ln_color := core.brightness(f.entered ? colors.accent : colors.primary, -.4)
    draw.diamond_lines(rect, 3, core.alpha(ln_color, f.opacity))

    sp_color := core.brightness(colors.primary, -.5 * (1-hv_ratio))
    draw_sprite(f.text, core.rect_inflated(rect, -rect.w/4), sp_color)
}

draw_pyramid_button :: proc (f: ^ui.Frame) {
    sp_color := core.brightness(f.entered ? colors.accent : colors.primary, -.5)
    draw_sprite("shape_pilar_gradient", f.rect, core.alpha(sp_color, f.opacity))
}

draw_pyramid_button_icon :: proc (f: ^ui.Frame) {
    hv_ratio := ui.hover_ratio(f.parent, .Cubic_Out, .333, .Linear, .222)
    sp_color := core.brightness(colors.primary, -.5 * (1-hv_ratio))
    draw_sprite(f.text, f.rect, core.alpha(sp_color, f.opacity))
}

draw_screen_tab :: proc (f: ^ui.Frame) {
    if f.selected {
        bg_color := core.alpha(colors.accent, f.opacity * .5)
        draw.rect_gradient_vertical(f.rect, {}, bg_color)

        br_color := core.alpha(colors.accent, f.opacity)
        br_rect := core.rect_line_bottom(f.rect, 4)
        draw.rect(br_rect, br_color)

        draw.rect_gradient_vertical(core.rect_line_left(f.rect, 1), {}, br_color)
        draw.rect_gradient_vertical(core.rect_line_right(f.rect, 1), {}, br_color)
    } else {
        hv_ratio := ui.hover_ratio(f, .Cubic_Out, .222, .Cubic_In, .333)
        bg_color := core.alpha(colors.accent, f.opacity * .4 * hv_ratio)
        draw.rect_gradient_vertical(f.rect, {}, bg_color)
    }

    tx_color := f.selected ? colors.accent : colors.primary
    draw_terse(f.terse, tx_color, drop_shadow=true)
}

draw_screen_tab_points :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(colors.primary, f.opacity)
    draw.rect(f.rect, bg_color)
    br_color := core.brightness(bg_color, -.555)
    draw.rect_lines(f.rect, 2, br_color)
    draw_terse(f.terse)
}

draw_game_title :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.primary, f.opacity * .3)
    draw_text_center("D    U    N    E", core.rect_half_top(f.rect), "text_8l", color)
    draw_text_center("A  W  A  K  E  N  I  N  G", core.rect_half_bottom(f.rect), "text_6l", color)
}

draw_scrollbar_thumb :: proc (f: ^ui.Frame) {
    // if mouse captured we use hover ratio 1 to make sure it stays visibly selected;
    // not ideal, as it will drop to 0 instantly when mouse released away from the frame
    hv_ratio := f.captured\
        ? 1\
        : ui.hover_ratio(f, .Cubic_Out, .123, .Cubic_In, .123)
    color := core.alpha(colors.primary, f.opacity)
    rect := core.rect_inflated(f.rect, { -8 + 4*hv_ratio, 0 })
    draw.rect(rect, color)
}
