package partials

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"

import "../colors"

draw_button :: proc (f: ^ui.Frame) {
    offset := f.captured ? Vec2 {0,2} : {}
    rect := core.rect_moved(f.rect, offset)
    hv_ratio := ui.hover_ratio(f, .Linear, .155, .Linear, .155)

    bg_top_color := core.alpha(core.brightness(colors.primary, -.9*(1-hv_ratio*.3)), f.opacity)
    bg_bottom_color := core.alpha(core.brightness(colors.bg1, -.9), f.opacity)
    if f.captured do bg_top_color, bg_bottom_color = bg_bottom_color, bg_top_color
    draw.rect_gradient_vertical(rect, bg_top_color, bg_bottom_color)

    ln_color := core.alpha(colors.primary, f.opacity*.3 + hv_ratio*.7)
    draw.rect_lines(rect, 1, ln_color)

    draw_terse(f.terse, offset=offset)
}

draw_button_diamond :: proc (f: ^ui.Frame) {
    hv_ratio := ui.hover_ratio(f, .Linear, .111, .Linear, .111)
    rect := core.rect_inflated(f.rect, hv_ratio*5)

    draw.diamond(rect, f.captured ? core.brightness(colors.accent, -.8) : colors.bg1)

    ln_color := core.brightness(f.entered ? colors.accent : colors.primary, -.4)
    draw.diamond_lines(rect, 3, core.alpha(ln_color, f.opacity))

    sp_color := core.brightness(colors.primary, -.5 * (1-hv_ratio))
    draw_sprite(f.text, core.rect_inflated(rect, -rect.w/4), sp_color)
}

draw_button_featured :: proc (f: ^ui.Frame) {
    rect := core.rect_inflated(f.rect, f.captured ? -2 : 0)
    hv_ratio := ui.hover_ratio(f, .Cubic_Out, .333, .Cubic_In, .333)

    if hv_ratio > 0 {
        cr_center := core.clamp_vec_to_rect(f.ui.mouse.pos, rect)
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

draw_button_radio_rect :: proc (f: ^ui.Frame) {
    bg_color := f.selected\
        ? core.brightness(colors.primary, -.3)\
        : colors.bg1
    draw.rect(f.rect, bg_color)

    hv_ratio := ui.hover_ratio(f, .Cubic_Out, .222, .Cubic_In, .222)
    br_color := core.alpha(colors.primary, hv_ratio)
    draw.rect_lines(f.rect, 1, br_color)
}

draw_button_radio_with_text :: proc (f: ^ui.Frame) {
    draw_button_radio_rect(f)

    tx_color := f.selected ? colors.bg1 : colors.primary
    draw_text_center(f.text, f.rect, "text_4r", tx_color)
}

draw_button_radio_pin :: proc (f: ^ui.Frame) {
    draw_button_radio_rect(f)

    br_color := core.alpha(colors.primary, f.opacity * .5)
    draw.rect_lines(f.rect, 1, br_color)
}

draw_button_radio_pin_nav :: proc (f: ^ui.Frame) {
    tx_color := core.brightness(colors.primary, f.entered ? .3 : -.3)
    draw_sprite(f.text, f.rect, tx_color)
}

draw_button_dropdown_button :: proc (f: ^ui.Frame) {
    if f.selected {
        bg_color := core.brightness(colors.accent, -.7)
        draw.rect(f.rect, bg_color)
    }

    hv_ratio := ui.hover_ratio(f, .Cubic_Out, .222, .Cubic_In, .222)
    br_color := core.alpha(colors.primary, f.opacity*.5 + hv_ratio*.5)
    draw.rect_lines(f.rect, 1, br_color)

    sp_rect := Rect { f.rect.x+f.rect.w-f.rect.h, f.rect.y, f.rect.h, f.rect.h }
    draw_sprite("arrow_drop_down", sp_rect, br_color)
}

draw_button_dropdown_rect :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(core.brightness(colors.primary, -.4), f.opacity)
    draw.rect(f.rect, bg_color)
}

draw_button_dropdown_item_anim_offset_x :: 20

draw_button_dropdown_item :: proc (f: ^ui.Frame) {
    hv_ratio := ui.hover_ratio(f, .Exponential_Out, .222, .Exponential_In, .333)
    rect := f.rect
    rect.w *= hv_ratio
    draw.rect(rect, core.alpha(colors.primary, f.opacity))

    if f.selected {
        sl_color := core.alpha(colors.accent, f.opacity)
        draw.rect_gradient_horizontal(f.rect, sl_color, {255,255,255,0})
    }

    aox :: draw_button_dropdown_item_anim_offset_x

    draw_terse(f.terse, offset={aox*.5*hv_ratio,0}, color=colors.bg0)

    hv_ratio = ui.hover_ratio(f, .Bounce_Out, .888, .Cubic_In, .333)
    q_w :: 20
    q_s_rect := core.rect_bar_right(f.rect, q_w)
    q_e_rect := core.rect_bar_right(f.terse.rect, q_w)
    q_e_rect.x += aox/2
    q_rect := core.ease_rect(q_s_rect, q_e_rect, hv_ratio)
    q_color := core.ease_color({}, colors.bg0, hv_ratio)
    draw_text_center("?", q_rect, "text_4l", q_color)
}
