package partials

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"

import "../colors"

draw_screen_tab :: proc (f: ^ui.Frame) {
    if f.selected {
        bg_color := colors.get(.accent, alpha=f.opacity*.5)
        draw.rect_gradient_vertical(f.rect, {}, bg_color)

        br_color := colors.get(.accent, alpha=f.opacity)
        br_rect := core.rect_bar_bottom(f.rect, 4)
        draw.rect(br_rect, br_color)

        br_color = colors.get(.accent, brightness=.3)

        draw.rect_gradient_vertical(core.rect_bar_left(f.rect, 1), {}, br_color)
        draw.rect_gradient_vertical(core.rect_bar_right(f.rect, 1), {}, br_color)
    } else {
        hv_ratio := ui.hover_ratio(f, .Cubic_Out, .222, .Cubic_In, .333)
        bg_color := colors.get(.accent, alpha=f.opacity*.4*hv_ratio)
        draw.rect_gradient_vertical(f.rect, {}, bg_color)
    }

    tx_color := colors.get(f.selected ? .accent : .primary)
    draw_terse(f, tx_color, drop_shadow=true)
}

draw_screen_tab_points :: proc (f: ^ui.Frame) {
    bg_color := colors.get(.primary, alpha=f.opacity)
    draw.rect(f.rect, bg_color)
    br_color := core.brightness(bg_color, -.555)
    draw.rect_lines(f.rect, 2, br_color)
    draw_terse(f)
}

draw_screen_pyramid_button :: proc (f: ^ui.Frame) {
    sp_color := colors.get(f.entered ? .accent : .primary, brightness=-.5, alpha=f.opacity)
    draw_sprite("shape_pilar_gradient", f.rect, tint=sp_color)

    if f.captured {
        pl_color := core.brightness(sp_color, .1)
        draw_sprite("shape_pilar_gradient", f.rect, tint=pl_color)
    }
}

draw_screen_pyramid_button_icon :: proc (f: ^ui.Frame) {
    hv_ratio := ui.hover_ratio(f.parent, .Cubic_Out, .333, .Linear, .222)
    sp_color := colors.get(.primary, brightness=-.5*(1-hv_ratio), alpha=f.opacity)
    draw_sprite(f.text, f.rect, tint=sp_color)
}

draw_screen_curtain_cross_switch_screen_ratio :: .7

draw_screen_curtain_cross_smooth :: proc (f: ^ui.Frame) {
    draw_screen_curtain_cross(f, .Cubic_Out, .Cubic_In)
}

draw_screen_curtain_cross_bouncy :: proc (f: ^ui.Frame) {
    draw_screen_curtain_cross(f, .Bounce_Out, .Cubic_In)
}

draw_screen_curtain_cross :: proc (f: ^ui.Frame, in_easing, out_easing: core.Ease) {
    h := f.rect.h/2
    c := core.rect_center(f.rect)
    x1, y1 := c.x-h, f.rect.y
    x2, y2 := c.x+h, y1+f.rect.h

    sr :: draw_screen_curtain_cross_switch_screen_ratio
    move_in_ratio := core.ease_ratio(core.clamp_ratio(f.anim.ratio, 0, sr), in_easing)
    move_out_ratio := core.ease_ratio(core.clamp_ratio(f.anim.ratio, sr, 1), out_easing)

    shade_ratio := .777 * (move_in_ratio<1 ? move_in_ratio : 1-move_out_ratio)
    draw.rect(f.rect, core.alpha(core.black, shade_ratio))

    for i in ([?] struct { rect: Rect, dir: Vec2, distance: f32 } {
        { rect={ x1, y1-2*h, 2*h, 2*h }     , dir={0,1} , distance=h },     // top
        { rect={ x1, y2, 2*h, 2*h }         , dir={0,-1}, distance=h },     // bottom
        { rect={ x1-5*h, y1-h, 4*h, 4*h }   , dir={1,0} , distance=2*h },   // left
        { rect={ x2+h, y1-h, 4*h, 4*h }     , dir={-1,0}, distance=2*h },   // right
    }) {
        rect := core.rect_moved(i.rect, i.dir * i.distance * move_in_ratio)

        if move_out_ratio > 0 {
            rect = core.rect_moved(rect, -1 * i.dir * i.distance * move_out_ratio)
        }

        draw.diamond(rect, colors.get(.bg2))
        draw.diamond_lines(rect, 4, colors.get(.primary, alpha=f.anim.ratio))
    }
}
