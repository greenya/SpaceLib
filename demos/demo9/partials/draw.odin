package partials

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

draw_terse :: proc (t: ^terse.Terse, color: Maybe(Color) = nil, offset := Vec2 {}, drop_shadow := false, _shadow_pass := false) {
    assert(t != nil)

    if drop_shadow {
        draw_terse(t, colors.get(.bg0), offset=offset+{0,2}, _shadow_pass=true)
    }

    for word in t.words {
        rect := offset != {} ? core.rect_moved(word.rect, offset) : word.rect
        if core.rect_intersection(rect, t.scissor) == {} do continue

        tint := color != nil ? color.? : word.color
        tint = core.alpha(tint, t.opacity)

        if word.is_icon {
            prefix :: strings.has_prefix
            switch {
            case prefix(word.text, "key/")          : draw_icon_key(word.text[4:], rect, t.opacity, shadow_only=_shadow_pass)
            case prefix(word.text, "key_tiny/")     : draw_icon_key(word.text[9:], core.rect_moved(rect, {0,-1}), t.opacity, font="text_4r", shadow_only=_shadow_pass)
            case prefix(word.text, "key_diamond/")  : draw_icon_key(word.text[12:], rect, t.opacity, shape=.diamond, shadow_only=_shadow_pass)
            case                                    : draw_sprite(word.text, rect, tint)
            }
        } else if word.text != "" && word.text != " " {
            draw.text(word.text, {rect.x,rect.y}, word.font, tint)
        }
    }

    if rl.IsKeyDown(.LEFT_CONTROL) do draw.debug_terse(t)
}

draw_icon_key :: proc (text: string, rect: Rect, opacity: f32, shape: enum {box,diamond} = .box, font := "text_4m", shadow_only := false) {
    bg_color := core.alpha(colors.get(shadow_only ? .bg0 : .primary), opacity * .75)
    switch shape {
    case .box       : draw.rect_rounded(rect, roundness_ratio=.3, segments=4, color=bg_color)
    case .diamond   : draw.diamond(rect, bg_color)
    }

    if !shadow_only {
        tx_color := core.alpha(colors.get(.bg0), opacity)
        switch text {
        case "__"   : draw_sprite("space_bar", core.rect_moved(rect, {0,rect.h/10}), tx_color)
        case        : draw_text_center(text, rect, font, tx_color)
        }
    }
}

draw_text_center :: proc (text: string, rect: Rect, font: string, color: Color) {
    font_tr := &fonts.get_by_name(font).font_tr
    draw.text_center(text, core.rect_center(rect), font_tr, color)
}

draw_hexagon_header :: proc (t: ^terse.Terse, rect: Rect, limit_x, limit_w: f32, bg_color: Color, hangout := false) {
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
    c := core.alpha(colors.get(.primary), t.opacity)

    // background
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
    color := core.alpha(colors.get_by_name(f.text), f.opacity)
    draw.rect(f.rect, color)
}

draw_image_placeholder :: proc (f: ^ui.Frame) {
    bg_color := core.alpha({20,20,20,255}, f.opacity)
    draw.rect(f.rect, bg_color)

    tx_color := core.alpha({60,60,60,255}, f.opacity)
    draw_text_center(f.text, f.rect, "text_4l", tx_color)
}

draw_hexagon_rect :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    draw_hexagon_header(f.terse, f.terse.rect, parent_rect.x, parent_rect.w, colors.get(.bg1))
}

draw_hexagon_rect_hangout :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    draw_hexagon_header(f.terse, f.terse.rect, parent_rect.x, parent_rect.w, colors.get(.bg1), hangout=true)
}

draw_hexagon_rect_hangout_short_lines :: proc (f: ^ui.Frame) {
    rect := f.terse.rect
    line_w := rect.h
    draw_hexagon_header(f.terse, rect, rect.x-2*line_w, rect.w+4*line_w, colors.get(.bg1), hangout=true)
}

draw_hexagon_rect_wide :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    draw_hexagon_header(f.terse, f.rect, parent_rect.x, parent_rect.w, colors.get(.bg1))
}

draw_hexagon_rect_wide_hangout :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    draw_hexagon_header(f.terse, f.rect, parent_rect.x, parent_rect.w, colors.get(.bg1), hangout=true)
}

draw_hexagon_rect_wide_hangout_accent :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    bg_color := core.brightness(colors.get(.accent), -.8)
    draw_hexagon_header(f.terse, f.rect, parent_rect.x, parent_rect.w, bg_color, hangout=true)
}

draw_hexagon_rect_with_half_transparent_bg :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    bg_color := core.alpha(colors.get(.bg1), .5)
    draw_hexagon_header(f.terse, f.terse.rect, parent_rect.x, parent_rect.w, bg_color)
}

draw_gradient_fade_down_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.get_by_name(f.text), f.opacity)
    draw.rect_gradient_vertical(f.rect, color, {})
}

draw_gradient_fade_up_and_down_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.get_by_name(f.text), f.opacity)
    draw.rect_gradient_vertical(core.rect_half_top(f.rect), {}, color)
    draw.rect_gradient_vertical(core.rect_half_bottom(f.rect), color, {})
}

draw_gradient_fade_right_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.get_by_name(f.text), f.opacity)
    draw.rect_gradient_horizontal(f.rect, color, {})
}

draw_game_title :: proc (f: ^ui.Frame) {
    color := core.alpha(colors.get(.primary), f.opacity * .3)
    draw_text_center("D    U    N    E", core.rect_half_top(f.rect), "text_8l", color)
    draw_text_center("A  W  A  K  E  N  I  N  G", core.rect_half_bottom(f.rect), "text_6l", color)
}

draw_scrollbar_track :: proc (f: ^ui.Frame) {
    // don't draw track if thumb is disabled
    if .disabled in f.children[0].flags do return

    color := core.alpha(colors.get(.primary), f.opacity * .5)
    draw.rect(f.rect, color)
}

draw_scrollbar_thumb :: proc (f: ^ui.Frame) {
    if .disabled in f.flags do return

    // if mouse captured we use hover ratio 1 to make sure it stays visibly selected;
    // not ideal, as it will drop to 0 instantly when mouse released away from the frame
    hv_ratio := f.captured\
        ? 1\
        : ui.hover_ratio(f, .Cubic_Out, .123, .Cubic_In, .123)
    color := core.alpha(core.brightness(colors.get(.primary), -.3), f.opacity)
    rect := core.rect_inflated(f.rect, { -8 + 2*hv_ratio, 0 })
    draw.rect(rect, color)
}

draw_window_rect :: proc (f: ^ui.Frame) {
    bg_top_color := core.alpha(colors.get(.bg0), f.opacity)
    bg_bottom_color := core.alpha(core.brightness(colors.get(.bg2), -.5), f.opacity)
    draw.rect_gradient_vertical(f.rect, bg_top_color, bg_bottom_color)

    br_color := core.alpha(colors.get(.primary), f.opacity * .3)
    draw.rect_lines(f.rect, 2, br_color)

    dim_rect := core.rect_from_center(core.rect_top(f.rect), 64)
    draw.diamond(dim_rect, bg_top_color)
    draw.diamond_lines(dim_rect, 2, br_color)

    icon_rect := core.rect_scaled_from_center(dim_rect, .6)
    icon_color := core.alpha(colors.get(.primary), f.opacity)
    draw_sprite("priority_high", icon_rect, icon_color)
}

draw_card_rect :: proc (f: ^ui.Frame) {
    ln_color := colors.get(.accent)
    bg_color := core.brightness(ln_color, -.75)

    if !f.selected {
        hv_ratio := ui.hover_ratio(f, .Cubic_Out, .333, .Cubic_In, .333)

        bg_color = core.ease_color(colors.get(.bg2), colors.get(.accent), hv_ratio)
        bg_color = core.alpha(core.brightness(bg_color, -.8), f.opacity*.3 + hv_ratio*.2)

        ln_color = core.ease_color(colors.get(.primary), colors.get(.accent), hv_ratio)
        ln_color = core.alpha(ln_color, f.opacity * .5)
    }

    draw.rect(f.rect, bg_color)
    draw.rect_lines(f.rect, 1, ln_color)
}

draw_tutorial_item :: proc (f: ^ui.Frame) {
    draw_card_rect(f)
    draw_terse(f.terse, drop_shadow=true)
}

draw_label_box :: proc (f: ^ui.Frame) {
    draw.rect(f.rect, core.brightness(colors.get(.primary), -.2))
    draw_terse(f.terse, colors.get(.bg0))
}
