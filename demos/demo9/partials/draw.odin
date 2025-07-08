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

draw_hexagon_header :: proc (t: ^terse.Terse, rect: Rect, limit_x, limit_w: f32, hangout := false, bg_opacity := f32(1)) {
    x1, y1, x2, y2, yc, xl, xr: f32

    if hangout {
        x1 = rect.x
        y1 = rect.y
        x2 = rect.x+rect.w
        y2 = rect.y+rect.h
        yc = (y1+y2)/2
        xl = x1-(yc-y1)
        xr = x2+(yc-y1)
    } else {
        y1 = rect.y
        y2 = rect.y+rect.h
        yc = (y1+y2)/2
        x1 = rect.x+(yc-y1)
        x2 = rect.x+rect.w-(yc-y1)
        xl = rect.x
        xr = rect.x+rect.w
    }

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

draw_hexagon_rect_hangout :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    draw_hexagon_header(f.terse, f.terse.rect, parent_rect.x, parent_rect.w, hangout=true)
}

draw_hexagon_rect_wide :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    draw_hexagon_header(f.terse, f.rect, parent_rect.x, parent_rect.w)
}

draw_hexagon_rect_wide_hangout :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    draw_hexagon_header(f.terse, f.rect, parent_rect.x, parent_rect.w, hangout=true)
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

draw_gradient_fade_right_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.get(f.text), f.opacity)
    draw.rect_gradient_horizontal(f.rect, color, {})
}

draw_game_title :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.primary, f.opacity * .3)
    draw_text_center("D    U    N    E", core.rect_half_top(f.rect), "text_8l", color)
    draw_text_center("A  W  A  K  E  N  I  N  G", core.rect_half_bottom(f.rect), "text_6l", color)
}

draw_scrollbar_track :: proc (f: ^ui.Frame) {
    // don't draw track if thumb is disabled
    if .disabled in f.children[0].flags do return

    color := core.alpha(colors.primary, f.opacity * .5)
    draw.rect(f.rect, color)
}

draw_scrollbar_thumb :: proc (f: ^ui.Frame) {
    if .disabled in f.flags do return

    // if mouse captured we use hover ratio 1 to make sure it stays visibly selected;
    // not ideal, as it will drop to 0 instantly when mouse released away from the frame
    hv_ratio := f.captured\
        ? 1\
        : ui.hover_ratio(f, .Cubic_Out, .123, .Cubic_In, .123)
    color := core.alpha(core.brightness(colors.primary, -.3), f.opacity)
    rect := core.rect_inflated(f.rect, { -8 + 2*hv_ratio, 0 })
    draw.rect(rect, color)
}
