package partials

import "core:fmt"
import "core:strings"
import "vendor:raylib"

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

draw_sprite :: proc (name: string, rect: Rect, fit := draw.Texture_Fit.fill, fit_align := draw.Texture_Fit_Align.center, tint := core.white) {
    sprite := sprites.get(name)
    switch info in sprite.info {
    case Rect               : if sprite.wrap    do draw.texture_wrap    (sprite.tex^, info, rect, tint=tint)
                              else              do draw.texture         (sprite.tex^, info, rect, fit=fit, fit_align=fit_align, tint=tint)
    case raylib.NPatchInfo  :                      draw.texture_npatch  (sprite.tex^, info, rect, tint=tint)
    }
}

draw_terse :: proc (t: ^terse.Terse, color: Color = {}, offset := Vec2 {}, drop_shadow := false, _shadow_pass := false) {
    assert(t != nil)

    if drop_shadow {
        draw_terse(t, colors.get(.bg0), offset=offset+{0,2}, _shadow_pass=true)
    }

    for line in t.lines {
        if !core.rects_intersect(line.rect, t.scissor) do continue

        for i in 0..<line.word_count {
            word := &t.words[line.word_start_idx+i]
            rect := offset != {} ? core.rect_moved(word.rect, offset) : word.rect
            if !core.rects_intersect(rect, t.scissor) do continue

            tint := color.a > 0 ? color : word.color
            tint = core.alpha(tint, t.opacity)

            if word.is_icon {
                prefix :: strings.has_prefix
                switch {
                case prefix(word.text, "key/")          : draw_icon_key(word.text[4:], rect, t.opacity, shadow_only=_shadow_pass)
                case prefix(word.text, "key_tiny/")     : draw_icon_key(word.text[9:], core.rect_moved(rect, {0,-1}), t.opacity, font="text_4r", shadow_only=_shadow_pass)
                case prefix(word.text, "key_diamond/")  : draw_icon_key(word.text[12:], rect, t.opacity, shape=.diamond, shadow_only=_shadow_pass)
                case                                    : draw_sprite(word.text, rect, tint=tint)
                }
            } else if word.text != "" && word.text != " " {
                draw.text(word.text, {rect.x,rect.y}, word.font, tint)
            }
        }
    }

    if raylib.IsKeyDown(.LEFT_CONTROL) do draw.debug_terse(t)
}

draw_icon_key :: proc (text: string, rect: Rect, opacity: f32, shape: enum {box,diamond} = .box, font := "text_4m", shadow_only := false) {
    bg_color := colors.get(shadow_only ? .bg0 : .primary, alpha=opacity*.75)
    switch shape {
    case .box       : draw.rect_rounded(rect, roundness_ratio=.3, segments=4, color=bg_color)
    case .diamond   : draw.diamond(rect, bg_color)
    }

    if !shadow_only {
        tx_color := colors.get(.bg0, alpha=opacity)
        switch text {
        case "__"   : draw_sprite("space_bar", core.rect_moved(rect, {0,rect.h/10}), tint=tx_color)
        case        : draw_text_center(text, rect, font, tx_color)
        }
    }
}

draw_icon_diamond :: proc (icon: string, rect: Rect, bg_color: Color, opacity: f32) {
    draw.diamond(rect, core.alpha(bg_color, opacity))
    draw.diamond_lines(core.rect_inflated(rect, -rect.w/10), 4, colors.get(.bg2, alpha=opacity))

    ln_color := colors.get(.primary, brightness=-.4, alpha=opacity)
    draw.diamond_lines(rect, 3, ln_color)

    sp_color := colors.get(.primary, alpha=opacity)
    draw_sprite(icon, core.rect_inflated(rect, -rect.w/4), tint=sp_color)
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
    c := colors.get(.primary, alpha=t.opacity)
    c_a0 := core.alpha(c, 0)

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
    if limit_x<xl           do draw.rect_gradient_horizontal({ x=limit_x, y=yc-1, w=xl-limit_x, h=th }, c_a0, c)
    if limit_x+limit_w>xr   do draw.rect_gradient_horizontal({ x=xr, y=yc-1, w=limit_x+limit_w-xr, h=th }, c, c_a0)

    draw_terse(t, drop_shadow=true)
}

draw_text_drop_shadow :: proc (f: ^ui.Frame) {
    draw_terse(f.terse, drop_shadow=true)
}

draw_color_rect :: proc (f: ^ui.Frame) {
    color := colors.get_by_name(f.text, alpha=f.opacity)
    draw.rect(f.rect, color)
}

draw_image_placeholder :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(core.gray1, f.opacity)
    draw.rect(f.rect, bg_color)

    tx_color := core.alpha(core.gray3, f.opacity)
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
    bg_color := colors.get(.accent, brightness=-.8)
    draw_hexagon_header(f.terse, f.rect, parent_rect.x, parent_rect.w, bg_color, hangout=true)
}

draw_hexagon_rect_with_half_transparent_bg :: proc (f: ^ui.Frame) {
    parent_rect := f.parent.rect
    bg_color := colors.get(.bg1, alpha=.5)
    draw_hexagon_header(f.terse, f.terse.rect, parent_rect.x, parent_rect.w, bg_color)
}

draw_gradient_fade_down_rect :: proc (f: ^ui.Frame) {
    color := colors.get_by_name(f.text, alpha=f.opacity)
    color_a0 := core.alpha(color, 0)
    draw.rect_gradient_vertical(f.rect, color, color_a0)
}

draw_gradient_fade_up_and_down_rect :: proc (f: ^ui.Frame) {
    color := colors.get_by_name(f.text, alpha=f.opacity)
    color_a0 := core.alpha(color, 0)
    draw.rect_gradient_vertical(core.rect_half_top(f.rect), color_a0, color)
    draw.rect_gradient_vertical(core.rect_half_bottom(f.rect), color, color_a0)
}

draw_gradient_fade_left_and_right_rect :: proc (f: ^ui.Frame) {
    color := colors.get_by_name(f.text, alpha=f.opacity)
    color_a0 := core.alpha(color, 0)
    draw.rect_gradient_horizontal(core.rect_half_left(f.rect), color_a0, color)
    draw.rect_gradient_horizontal(core.rect_half_right(f.rect), color, color_a0)
}

draw_gradient_fade_right_rect :: proc (f: ^ui.Frame) {
    color := colors.get_by_name(f.text, alpha=f.opacity)
    color_a0 := core.alpha(color, 0)
    draw.rect_gradient_horizontal(f.rect, color, color_a0)
}

draw_game_title :: proc (f: ^ui.Frame) {
    color := colors.get(.primary, alpha=f.opacity*.3)
    draw_text_center("D    U    N    E", core.rect_half_top(f.rect), "text_8l", color)
    draw_text_center("A  W  A  K  E  N  I  N  G", core.rect_half_bottom(f.rect), "text_6l", color)
}

draw_scrollbar_track :: proc (f: ^ui.Frame) {
    // don't draw track if thumb is disabled
    if .disabled in f.children[0].flags do return

    color := colors.get(.primary, alpha=f.opacity*.5)
    draw.rect(f.rect, color)
}

draw_scrollbar_thumb :: proc (f: ^ui.Frame) {
    if .disabled in f.flags do return

    // if mouse captured we use hover ratio 1 to make sure it stays visibly selected;
    // not ideal, as it will drop to 0 instantly when mouse released away from the frame
    hv_ratio := f.captured\
        ? 1\
        : ui.hover_ratio(f, .Cubic_Out, .123, .Cubic_In, .123)
    color := colors.get(.primary, brightness=-.3, alpha=f.opacity)
    rect := core.rect_inflated(f.rect, { -8 + 2*hv_ratio, 0 })
    draw.rect(rect, color)
}

draw_window_rect :: proc (f: ^ui.Frame) {
    bg_top_color := colors.get(.bg0, alpha=f.opacity)
    bg_bottom_color := colors.get(.bg2, brightness=-.5, alpha=f.opacity)
    draw.rect_gradient_vertical(f.rect, bg_top_color, bg_bottom_color)

    br_color := colors.get(.primary, alpha=f.opacity*.3)
    draw.rect_lines(f.rect, 2, br_color)

    dim_rect := core.rect_from_center(core.rect_top(f.rect), 64)
    draw.diamond(dim_rect, bg_top_color)
    draw.diamond_lines(dim_rect, 2, br_color)

    icon_rect := core.rect_scaled(dim_rect, .6)
    icon_color := colors.get(.primary, alpha=f.opacity)
    draw_sprite("priority_high", icon_rect, tint=icon_color)
}

draw_card_rect :: proc (f: ^ui.Frame) {
    ln_color := colors.get(.accent)
    bg_color := colors.get(.accent, brightness=-.75)

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
    draw.rect(f.rect, colors.get(.primary, brightness=-.2))
    draw_terse(f.terse, colors.get(.bg0))
}

draw_codex_section_item :: proc (f: ^ui.Frame) {
    bg_color := colors.get(.primary, brightness=-.7)
    draw.rect(f.rect, bg_color)

    sp_rect := core.rect_moved(f.rect, {-f.rect.w/20,0})
    draw_sprite("book-pile", sp_rect, fit=.contain, fit_align=.end, tint=colors.get(.primary, brightness=-.4))

    draw.rect_lines(f.rect, 1, colors.get(.primary, brightness=f.entered ? .2 : -.4))
    draw_terse(f.terse, drop_shadow=true)
}

draw_after_codex_section_item :: proc (f: ^ui.Frame) {
    flow := ui.layout_flow(f)

    top_scrolled_h := min(60, flow.scroll.offset - flow.scroll.offset_min)
    if top_scrolled_h > 0 {
        bg_rect := core.rect_bar_top(f.rect, top_scrolled_h)
        draw.rect_gradient_vertical(bg_rect, colors.get(.bg2), Color {})
    }

    bottom_scrolled_h := min(60, flow.scroll.offset_max - flow.scroll.offset)
    if bottom_scrolled_h > 0 {
        bg_rect := core.rect_bar_bottom(f.rect, bottom_scrolled_h)
        draw.rect_gradient_vertical(bg_rect, Color {}, colors.get(.bg2))
    }
}

draw_codex_topic_item :: proc (f: ^ui.Frame) {
    draw.rect(f.rect, colors.get(.primary, brightness=-.8))

    sp_rect := core.rect_inflated(f.rect, -f.rect.h/20)
    draw_sprite("book-cover", sp_rect, fit=.contain, tint=colors.get(.primary, brightness=-.4))

    hv_ratio := ui.hover_ratio(f, .Linear, .111, .Cubic_Out, .333)

    tx_offset := Vec2 { 0, f.rect.h/4 } * (1-hv_ratio)

    tx_bg_rect_h := max(f.rect.h/4, f.terse.rect.h)
    tx_bg_rect_h += hv_ratio * (f.rect.h-tx_bg_rect_h)
    tx_bg_rect := core.rect_bar_center_horizontal(f.rect, tx_bg_rect_h)
    tx_bg_rect = core.rect_moved(tx_bg_rect, tx_offset)
    tx_bg_color := core.ease_color(core.black, colors.get(.accent, brightness=-.6), hv_ratio)
    tx_bg_color = core.alpha(tx_bg_color, .8)
    draw.rect(tx_bg_rect, tx_bg_color)

    draw.rect_lines(f.rect, 1, colors.get(.primary, brightness=f.entered ? .2 : -.4))

    draw_terse(f.terse, offset=tx_offset, drop_shadow=true)
}

draw_icon_diamond_primary :: proc (f: ^ui.Frame) {
    draw_icon_diamond(f.text, f.rect, colors.get(.primary, brightness=-.6), f.opacity)
}

draw_icon_box_fill_primary :: proc (f: ^ui.Frame) {
    draw.rect(f.rect, colors.get(.primary, brightness=-.2))
    draw_sprite(f.text, core.rect_inflated(f.rect, 0), tint=colors.get(.bg1))
}

draw_header_bar_primary :: proc (f: ^ui.Frame) {
    color := colors.get(.primary, brightness=-.5, alpha=f.opacity)
    color_a0 := core.alpha(color, 0)
    draw.rect_gradient_horizontal(f.rect, color, color_a0)
    draw_terse(f.terse, drop_shadow=true)
}

draw_info_panel_rect  :: proc (f: ^ui.Frame) {
    draw.rect(f.rect, {0,0,0,80})
    draw.rect(core.rect_inflated(f.rect, -6), {0,0,0,80})
}
