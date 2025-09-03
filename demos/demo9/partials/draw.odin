package partials

import "core:fmt"
import "core:strings"
import "vendor:raylib"

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"

import "../colors"
import "../data"
import "../fonts"
import "../sprites"

_ :: fmt

@private Vec2 :: core.Vec2
@private Rect :: core.Rect
@private Color :: core.Color

draw_text_aligned :: proc (text: string, pos, align: Vec2, font: ^fonts.Font, color: Color, drop_shadow := false) {
    if drop_shadow {
        sh_color := colors.get(.bg1)
        sh_color.a = color.a
        sh_pos := pos + { font.height/30, font.height/15 }
        draw.text_aligned(text, sh_pos, align, &font.font_tr, sh_color)
    }
    draw.text_aligned(text, pos, align, &font.font_tr, color)
}

draw_sprite :: proc (name: string, rect: Rect, fit := draw.Texture_Fit.fill, fit_align := draw.Texture_Fit_Align.center, tint := core.white) {
    sprite := sprites.get(name)
    switch info in sprite.info {
    case Rect               : if sprite.wrap    do draw.texture_wrap    (sprite.tex^, info, rect, tint=tint)
                              else              do draw.texture         (sprite.tex^, info, rect, fit=fit, fit_align=fit_align, tint=tint)
    case raylib.NPatchInfo  :                      draw.texture_npatch  (sprite.tex^, info, rect, tint=tint)
    }
}

draw_terse :: proc (f: ^ui.Frame, color: Color = {}, offset := Vec2 {}, drop_shadow := false, _shadow_pass := false) {
    assert(f.terse != nil)

    if drop_shadow {
        draw_terse(f, color=colors.get(.bg0), offset=offset+{0,2}, _shadow_pass=true)
    }

    for &line in f.terse.lines {
        if !core.rects_intersect(line.rect, f.ui.scissor_rect) do continue

        for word in line.words {
            rect := offset != {} ? core.rect_moved(word.rect, offset) : word.rect
            if !core.rects_intersect(rect, f.ui.scissor_rect) do continue

            tint := color.a > 0 ? color : word.color
            tint = core.alpha(tint, f.opacity)

            if word.is_icon {
                prefix :: strings.has_prefix
                switch {
                case prefix(word.text, "key/")          : draw_icon_key(word.text[4:], rect, f.opacity, shadow_only=_shadow_pass)
                case prefix(word.text, "key_tiny/")     : draw_icon_key(word.text[9:], core.rect_moved(rect, {0,-1}), f.opacity, font="text_4r", shadow_only=_shadow_pass)
                case prefix(word.text, "key_diamond/")  : draw_icon_key(word.text[12:], rect, f.opacity, shape=.diamond, shadow_only=_shadow_pass)
                case                                    : draw_sprite(word.text, rect, tint=tint)
                }
            } else if word.text != "" && word.text != " " {
                draw.text(word.text, {rect.x,rect.y}, word.font, tint)
            }
        }
    }
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
        case        : draw_text_aligned(text, core.rect_center(rect), .5, fonts.get_by_name(font), tx_color)
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

draw_hexagon_header :: proc (f: ^ui.Frame, rect: Rect, limit_x, limit_w: f32, ln_color, bg_color: Color, drop_shadow := true, hangout := false) {
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
    c := core.alpha(ln_color, f.opacity)
    c_a0 := core.alpha(c, 0)

    // background
    c_bg := core.alpha(bg_color, f.opacity)
    draw.triangle_fan({ {x1,yc}, {x1,y1}, {xl,yc}, {x1,y2}, {x2,y2}, {xr,yc}, {x2,y1}, {x1,y1} }, c_bg)

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

    draw_terse(f, drop_shadow=drop_shadow)
}

draw_text_drop_shadow :: proc (f: ^ui.Frame) {
    draw_terse(f, drop_shadow=true)
}

draw_color_rect :: proc (f: ^ui.Frame) {
    color := colors.get_by_name(f.text, alpha=f.opacity)
    draw.rect(f.rect, color)
}

draw_color_rect_with_primary_border :: proc (f: ^ui.Frame) {
    color := colors.get_by_name(f.text, alpha=f.opacity)
    draw.rect(f.rect, color)
    draw.rect_lines(f.rect, 1, colors.get(.primary, alpha=f.opacity*0.5))
}

draw_color_rect_with_primary_border_d5 :: proc (f: ^ui.Frame) {
    color := colors.get_by_name(f.text, alpha=f.opacity)
    draw.rect(f.rect, color)
    draw.rect_lines(f.rect, 2, colors.get(.primary, brightness=-.5, alpha=f.opacity*0.5))
}

draw_image_placeholder :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(core.gray1, f.opacity)
    draw.rect(f.rect, bg_color)

    tx_color := core.alpha(core.gray3, f.opacity)
    draw_text_aligned(f.text, core.rect_center(f.rect), .5, fonts.get(.text_4l), tx_color)
}

draw_hexagon_rect :: proc (f: ^ui.Frame) {
    draw_hexagon_header(f,
        rect        = f.terse.rect,
        limit_x     = f.parent.rect.x,
        limit_w     = f.parent.rect.w,
        ln_color    = colors.get(.primary),
        bg_color    = colors.get(.bg1),
    )
}

draw_hexagon_rect_hangout :: proc (f: ^ui.Frame) {
    draw_hexagon_header(f,
        rect        = f.terse.rect,
        limit_x     = f.parent.rect.x,
        limit_w     = f.parent.rect.w,
        ln_color    = colors.get(.primary),
        bg_color    = colors.get(.bg1),
        hangout     = true,
    )
}

draw_hexagon_rect_hangout_self_rect :: proc (f: ^ui.Frame) {
    draw_hexagon_header(f,
        rect        = f.terse.rect,
        limit_x     = f.rect.x,
        limit_w     = f.rect.w,
        ln_color    = colors.get(.primary),
        bg_color    = colors.get(.bg1),
        hangout     = true,
    )
}

draw_hexagon_rect_fill_hangout_self_rect :: proc (f: ^ui.Frame) {
    color := colors.get(.primary, brightness=-.3)
    draw_hexagon_header(f,
        rect        = f.terse.rect,
        limit_x     = f.rect.x,
        limit_w     = f.rect.w,
        ln_color    = color,
        bg_color    = color,
        drop_shadow = false,
        hangout     = true,
    )
}

draw_hexagon_rect_hangout_short_lines :: proc (f: ^ui.Frame) {
    draw_hexagon_header(f,
        rect        = f.terse.rect,
        limit_x     = f.terse.rect.x - 2*f.terse.rect.h,
        limit_w     = f.terse.rect.w + 4*f.terse.rect.h,
        ln_color    = colors.get(.primary),
        bg_color    = colors.get(.bg1),
        hangout     = true,
    )
}

draw_hexagon_rect_wide :: proc (f: ^ui.Frame) {
    draw_hexagon_header(f,
        rect        = f.rect,
        limit_x     = f.parent.rect.x,
        limit_w     = f.parent.rect.w,
        ln_color    = colors.get(.primary),
        bg_color    = colors.get(.bg1),
    )
}

draw_hexagon_rect_wide_hangout :: proc (f: ^ui.Frame) {
    draw_hexagon_header(f,
        rect        = f.rect,
        limit_x     = f.parent.rect.x,
        limit_w     = f.parent.rect.w,
        ln_color    = colors.get(.primary),
        bg_color    = colors.get(.bg1),
        hangout     = true,
    )
}

draw_hexagon_rect_wide_hangout_accent :: proc (f: ^ui.Frame) {
    draw_hexagon_header(f,
        rect        = f.rect,
        limit_x     = f.parent.rect.x,
        limit_w     = f.parent.rect.w,
        ln_color    = colors.get(.primary),
        bg_color    = colors.get(.accent, brightness=-.8),
        hangout     = true,
    )
}

draw_hexagon_rect_wide_hangout_error :: proc (f: ^ui.Frame) {
    draw_hexagon_header(f,
        rect        = f.rect,
        limit_x     = f.parent.rect.x,
        limit_w     = f.parent.rect.w,
        ln_color    = colors.get(.primary),
        bg_color    = colors.get(.unrepairable, brightness=-.6),
        hangout     = true,
    )
}

draw_hexagon_rect_with_half_transparent_bg :: proc (f: ^ui.Frame) {
    draw_hexagon_header(f,
        rect        = f.terse.rect,
        limit_x     = f.parent.rect.x,
        limit_w     = f.parent.rect.w,
        ln_color    = colors.get(.primary),
        bg_color    = colors.get(.bg1, alpha=.5),
    )
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
    center := core.rect_center(f.rect)
    draw_text_aligned("D    U    N    E", center, {.5,.75}, fonts.get(.text_8l), color)
    draw_text_aligned("A  W  A  K  E  N  I  N  G", center, {.5,0}, fonts.get(.text_6l), color)
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
    draw_terse(f, drop_shadow=true)
}

draw_label_box :: proc (f: ^ui.Frame) {
    draw.rect(f.rect, colors.get(.primary, brightness=-.3))
    draw_terse(f, color=colors.get(.bg0))
}

draw_codex_section_item :: proc (f: ^ui.Frame) {
    bg_color := colors.get(.primary, brightness=-.7)
    draw.rect(f.rect, bg_color)

    sp_rect := core.rect_moved(f.rect, {-f.rect.w/20,0})
    draw_sprite("book-pile", sp_rect, fit=.contain, fit_align=.end, tint=colors.get(.primary, brightness=-.4))

    draw.rect_lines(f.rect, 1, colors.get(.primary, brightness=f.entered ? .2 : -.4))
    draw_terse(f, drop_shadow=true)
}

draw_after_flow_scrolled_vertical_gradients :: proc (f: ^ui.Frame) {
    flow := ui.layout_flow(f)
    assert(flow != nil)

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

    draw_terse(f, offset=tx_offset, drop_shadow=true)
}

draw_icon_diamond_primary :: proc (f: ^ui.Frame) {
    draw_icon_diamond(f.text, f.rect, colors.get(.primary, brightness=-.6), f.opacity)
}

draw_icon_primary :: proc (f: ^ui.Frame) {
    draw_sprite(f.text, f.rect, tint=colors.get(.primary, brightness=-.3))
}

draw_icon_primary_with_shadow :: proc (f: ^ui.Frame) {
    sh_rect := core.rect_moved(f.rect, {f.rect.w/20,f.rect.h/20})
    draw_sprite(f.text, sh_rect, tint=colors.get(.bg1))
    draw_sprite(f.text, f.rect, tint=colors.get(.primary, brightness=-.3))
}

draw_icon_box_fill_primary :: proc (f: ^ui.Frame) {
    draw.rect(f.rect, colors.get(.primary, brightness=-.3))
    draw_sprite(f.text, core.rect_inflated(f.rect, -f.rect.w/10), tint=colors.get(.bg1))
}

draw_icon_diamond_fill_primary :: proc (f: ^ui.Frame) {
    draw.diamond(f.rect, colors.get(.primary, brightness=-.3))
    draw_sprite(f.text, core.rect_inflated(f.rect, -f.rect.w/5), tint=colors.get(.bg1))
}

draw_header_bar_primary :: proc (f: ^ui.Frame) {
    color := colors.get(.primary, brightness=-.5, alpha=f.opacity)
    color_a0 := core.alpha(color, 0)
    draw.rect_gradient_horizontal(f.rect, color, color_a0)
    draw_terse(f, drop_shadow=true)
}

draw_info_panel_rect :: proc (f: ^ui.Frame) {
    draw.rect(f.rect, {0,0,0,50})
    draw.rect(core.rect_inflated(f.rect, -6), {0,0,0,120})
}

draw_slider_track :: proc (f: ^ui.Frame) {
    bg_color := colors.get(.primary, alpha=.2)
    draw.rect(f.rect, bg_color)
}

draw_slider_track_with_marks :: proc (f: ^ui.Frame) {
    draw_slider_track(f)

    assert(len(f.children) == 1)
    _, data := ui.actor_slider(f.children[0])
    mark_gap := f.rect.w / f32(data.total-1)
    mark_pos := Vec2 { f.rect.x, f.rect.y+f.rect.h/2 }
    mark_color := colors.get(.primary, brightness=-.4)
    for i in 0..<data.total {
        if i != data.idx {
            mark_rect := core.rect_from_center(mark_pos, 16)
            draw_sprite("nearby", mark_rect, tint=mark_color)
        }
        mark_pos.x += mark_gap
    }
}

draw_slider_thumb :: proc (f: ^ui.Frame) {
    sp_color := colors.get(.accent, brightness=f.entered ? .3 : 0)
    draw_sprite("nearby", f.rect, tint=sp_color)
}

draw_chevron_label_rect :: proc (f: ^ui.Frame) {
    sp_bg_color := colors.get(.primary, brightness=-.3)
    sp_bg_rect := core.rect_bar_left(f.rect, f.rect.h*.9)
    draw.rect(sp_bg_rect, sp_bg_color)

    draw.triangle(
        core.rect_top_right(sp_bg_rect),
        core.rect_bottom_right(sp_bg_rect),
        core.rect_right(sp_bg_rect) + {sp_bg_rect.h/2,0},
        sp_bg_color,
    )

    sp_color := colors.get(.bg1)
    sp_rect := core.rect_scaled(core.rect_bar_left(f.rect, f.rect.h), .8)
    draw_sprite(f.text, sp_rect, tint=sp_color)

    draw.rect_lines(f.rect, 1, colors.get(.primary, alpha=f.opacity*0.5))
}

draw_container_slot :: proc (f: ^ui.Frame) {
    con := ui.user_ptr(f, ^Container)
    slot := &con.data.slots[f.user_idx]

    br_color := colors.get(.primary, alpha=.2)
    br_color_focus := colors.get(.accent)
    br_thick := f32(1)

    if slot.item != nil {
        draw_slot_origin(slot, f.rect, f.opacity)
        draw_slot_icon(slot, f.rect, f.opacity)
        draw_slot_tier(slot, f.rect, f.opacity)
        if slot.item.stack == 1 do draw_slot_durability_and_liquid_levels(slot, f.rect, f.opacity)
        else                    do draw_slot_stack_count(slot, f.rect, f.opacity)
        draw_slot_volume(slot, f.rect, f.opacity)

        if f.captured {
            br_color = br_color_focus
            br_thick = 3
        } else {
            hv_ratio := f.captured ? 1 : ui.hover_ratio(f, .Linear, .3, .Linear, .3)
            br_color = core.ease_color(br_color, br_color_focus, hv_ratio, .Linear)
        }
    } else {
        draw_empty_slot(slot, f.rect, f.opacity)
    }

    draw.rect_lines(f.rect, br_thick, br_color)
}

draw_empty_slot :: proc (slot: ^data.Container_Slot, rect: Rect, opacity: f32) {
    icon: string
    switch slot.spec {
    case .slot_head     : icon = "protection-glasses"
    case .slot_chest    : icon = "moncler-jacket"
    case .slot_legs     : icon = "armored-pants"
    case .slot_hands    : icon = "gloves"
    case .slot_feet     : icon = "steeltoe-boots"
    case .slot_shield   : icon = "shieldcomb"
    case .slot_belt     : icon = "belt-armor"
    case .slot_light    : icon = "torch"
    case .slot_power    : icon = "power-generator"
    case                : icon = "add"
    }
    sp_rect := core.rect_scaled(rect, .65)
    sp_color := colors.get(.primary, alpha=.1*opacity)
    draw_sprite(icon, sp_rect, tint=sp_color)
}

draw_slot_origin :: proc (slot: ^data.Container_Slot, rect: Rect, opacity: f32) {
    assert(slot.item != nil)

    t, b: Color
    clr :: #force_inline proc (id: colors.ID, b, a: f32) -> Color { return colors.get(id, brightness=b, alpha=a) }
    switch slot.item.origin {
    case .none      : t=clr(.primary, -.9, opacity)   ; b=clr(.primary, -.7, opacity)
    case .imperial  : t=clr(.imperial, -.9, opacity)  ; b=clr(.imperial, -.4, opacity)
    case .house     : t=clr(.house, -.9, opacity)     ; b=clr(.house, -.6, opacity)
    case .fremen    : t=clr(.fremen, -.9, opacity)    ; b=clr(.fremen, -.6, opacity)
    case .unique    : t=clr(.unique, -.3, opacity)    ; b=clr(.unique, -.9, opacity)
    case .special   : t=clr(.special, -.3, opacity)   ; b=clr(.special, -.9, opacity)
    }
    draw.rect_gradient_vertical(rect, t, b)
}

draw_slot_volume :: proc (slot: ^data.Container_Slot, rect: Rect, opacity: f32, in_tooltip := false) {
    assert(slot.item != nil)

    volume := data.container_slot_volume(slot^)
    if volume == 0 do return

    pad: f32 = in_tooltip ? 10 : 5
    bar_w :: 6
    bar_h: f32
    bar_color: Color

    switch {
    case volume < 5     : bar_h=rect.h/8    ; bar_color=colors.get(.vol_low, alpha=opacity)
    case volume < 15    : bar_h=rect.h/5    ; bar_color=colors.get(.vol_med, alpha=opacity)
    case                : bar_h=rect.h/3    ; bar_color=colors.get(.vol_high, alpha=opacity)
    }

    rect := rect
    rect = Rect { rect.x+pad, rect.y+rect.h-bar_h-pad, bar_w, bar_h }

    if in_tooltip {
        volume_text := core.format_f32_tmp(volume, 3)
        text := fmt.tprintf("%sV", volume_text)
        text_pos := core.rect_bottom_right(rect) + {4,6}
        text_font := fonts.get(.text_4l)
        draw_text_aligned(text, text_pos, {0,1}, text_font, colors.get(.primary, alpha=opacity), drop_shadow=true)
    } else {
        if slot.item.durability > 0                 do rect.y -= container_slot_progress_bar_h
        if slot.item.liquid_container.type != .none do rect.y -= container_slot_progress_bar_h
    }

    draw.rect(rect, core.brightness(bar_color, .5))
    rect.w -= 1
    rect.h -= 1
    rect.x += 1
    rect.y += 1
    draw.rect(rect, core.brightness(bar_color, -.5))
    rect.w -= 1
    rect.h -= 1
    draw.rect(rect, bar_color)
}

draw_slot_tier :: proc (slot: ^data.Container_Slot, rect: Rect, opacity: f32) {
    assert(slot.item != nil)

    text_tiers := [?] string { "", "I", "II", "III", "IV", "V", "VI" }
    if slot.item.tier < 1 || slot.item.tier >= len(text_tiers) do return

    text := text_tiers[slot.item.tier]
    text_pos := core.rect_top_right(rect) + {-10,2}
    text_font := fonts.get(.text_4l)
    text_color := colors.get(.primary, brightness=-.4, alpha=opacity)
    draw_text_aligned(text, text_pos, {1,0}, text_font, text_color, drop_shadow=true)
}

draw_slot_icon :: proc (slot: ^data.Container_Slot, rect: Rect, opacity: f32) {
    assert(slot.item != nil)

    icon := slot.item.icon != "" ? slot.item.icon : "question_mark"
    icon_rect := core.rect_scaled(rect, .8)
    draw_sprite(icon, core.rect_moved(icon_rect, {3,4}), fit=.contain, tint=colors.get(.bg1, alpha=opacity))
    draw_sprite(icon, icon_rect, fit=.contain, tint=core.alpha(core.white, opacity))
}

draw_slot_stack_count :: proc (slot: ^data.Container_Slot, rect: Rect, opacity: f32) {
    if slot.count < 1 do return

    text := core.format_int_tmp(slot.count)
    text_pos := core.rect_bottom_right(rect) - {8,2}
    text_font := fonts.get(.text_4r)
    text_color := colors.get(.primary, alpha=opacity)
    draw_text_aligned(text, text_pos, 1, text_font, text_color, drop_shadow=true)
}

container_slot_progress_bar_h :: 4

draw_slot_durability_and_liquid_levels :: proc (slot: ^data.Container_Slot, rect: Rect, opacity: f32) {
    assert(slot.item.stack == 1)

    bar_offset_y := f32(0)

    if slot.item.durability > 0 {
        bar_rect := core.rect_bar_bottom(core.rect_inflated(rect, -1), container_slot_progress_bar_h)
        draw_rect_progress_bar_durability(bar_rect,
            value           = slot.durability.value,
            unrepairable    = slot.durability.unrepairable,
            maximum         = slot.item.durability,
            opacity         = opacity,
        )
        bar_offset_y -= container_slot_progress_bar_h
    }

    liquid_type := slot.item.liquid_container.type
    if liquid_type != .none {
        bar_rect := core.rect_bar_bottom(core.rect_inflated(rect, -1), container_slot_progress_bar_h)
        bar_rect.y += bar_offset_y
        #partial switch liquid_type {
        case .water, .blood:
            draw_rect_progress_bar_with_sips(bar_rect,
                value       = slot.liquid_amount,
                maximum     = slot.item.liquid_container.capacity,
                color_id    = liquid_type == .water ? .water : .blood,
                opacity     = opacity,
            )
        case .fuel:
            draw_rect_progress_bar(bar_rect,
                value       = slot.liquid_amount,
                maximum     = slot.item.liquid_container.capacity,
                color_id    = .water,
                opacity     = opacity,
            )
        }
    }
}

draw_rect_progress_bar_with_sips :: proc (rect: Rect, value, maximum: f32, color_id: colors.ID, opacity: f32) {
    sip_amount: f32
    switch {
    case maximum <= 500: sip_amount = 100
    case maximum <= 2500: sip_amount = 250
    case maximum <= 8000: sip_amount = 500
    case                : sip_amount = 1000
    }

    sip_gap := rect.h / 2
    sips := int(maximum) / int(sip_amount)
    sip_w := (rect.w - (f32(sips)-1)*sip_gap) / f32(sips)
    sip_rect := Rect { rect.x, rect.y, sip_w, rect.h }
    value_i := int(value) / int(sip_amount)

    empty_color := colors.get(color_id, alpha=opacity*.2)
    filled_color := colors.get(color_id, alpha=opacity)

    for i in 0..<sips {
        color := i < value_i ? filled_color : empty_color
        draw.rect(sip_rect, color)

        if i == value_i {
            sip_part := value - f32(i)*sip_amount
            sip_part_ratio := sip_part / sip_amount
            sip_part_rect := core.rect_scaled_top_left(sip_rect, {sip_part_ratio,1})
            draw.rect(sip_part_rect, filled_color)
        }

        sip_rect.x += sip_gap + sip_w
    }
}

draw_rect_progress_bar :: proc (rect: Rect, value, maximum: f32, color_id: colors.ID, opacity: f32) {
    empty_color := colors.get(color_id, brightness=-.8, alpha=opacity)
    draw.rect(rect, empty_color)

    filled_ratio := core.clamp_ratio(value, 0, maximum)
    filled_rect := core.rect_scaled_top_left(rect, {filled_ratio,1})
    filled_color := colors.get(color_id, alpha=opacity)
    draw.rect(filled_rect, filled_color)
}

draw_rect_progress_bar_durability :: proc (rect: Rect, value, unrepairable, maximum, opacity: f32) {
    draw_rect_progress_bar(rect, value, maximum, .primary, opacity)
    if unrepairable > 0 {
        unrepairable_ratio := core.clamp_ratio(unrepairable, 0, maximum)
        unrepairable_rect := core.rect_scaled_top_right(rect, {unrepairable_ratio,1})
        unrepairable_color := colors.get(.unrepairable, alpha=opacity)
        draw.rect(unrepairable_rect, unrepairable_color)
    }
}

draw_container_volume_bar :: proc (f: ^ui.Frame) {
    ln_thick :: 2
    ln_color := colors.get(.primary, brightness=-.2)

    draw.rect(core.rect_bar_right(f.rect, ln_thick), ln_color)
    draw.rect(core.rect_bar_top(f.rect, ln_thick), ln_color)
    draw.rect(core.rect_bar_bottom(f.rect, ln_thick), ln_color)

    con := ui.user_ptr(f, ^Container)
    vol_ratio := con != nil ? con.volume_ratio : 0

    bar_rect := core.rect_inflated(f.rect, -2)
    for i in ([?] struct { ratio: Vec2, pad: Vec2, color: colors.ID } {
        { ratio={0,.5}  , pad={2,0}, color=.vol_low },
        { ratio={.5,.75}, pad={2,2}, color=.vol_med },
        { ratio={.75,1} , pad={0,2}, color=.vol_high },
    }) {
        i_color := colors.get(i.color)
        i_rect := core.rect_fraction_vertical(bar_rect, 1-i.ratio[1], 1-i.ratio[0])
        i_rect = core.rect_padded_vertical(i_rect, i.pad[0], i.pad[1])

        i_color_empty := core.alpha(i_color, .2)
        draw.rect(i_rect, i_color_empty)

        if vol_ratio >= i.ratio[1] {
            draw.rect(i_rect, i_color)
        } else if vol_ratio >= i.ratio[0] {
            segment_ratio := core.clamp_ratio(vol_ratio, i.ratio[0], i.ratio[1])
            segment_rect := core.rect_scaled_bottom_left(i_rect, {1,segment_ratio})
            draw.rect(segment_rect, i_color)
        }
    }
}

draw_container_volume_bar_arrow :: proc (f: ^ui.Frame) {
    color := colors.get(.primary, brightness=-.2)
    draw_sprite("label_arrow_right", f.rect, tint=color)

    tx_pos := core.rect_right(f.rect) - {15,0}
    draw_text_aligned(f.text, tx_pos, {1,.5}, fonts.get(.text_4m), color)
}

draw_tooltip_image :: proc (f: ^ui.Frame) {
    slot := ui.user_ptr(f.parent, ^data.Container_Slot)
    assert(slot != nil && slot.item != nil)

    rect := core.rect_moved(f.rect, {0,1})
    draw_slot_origin(slot, rect, f.opacity)
    draw_slot_icon(slot, rect, f.opacity)
    draw_slot_tier(slot, rect, f.opacity)
    draw_slot_volume(slot, rect, f.opacity, in_tooltip=true)
}

draw_tooltip_durability :: proc (f: ^ui.Frame) {
    slot := ui.user_ptr(f.parent, ^data.Container_Slot)
    assert(slot != nil && slot.item != nil && slot.item.durability > 0)

    draw.rect(f.rect, colors.get(.primary, brightness=-.75, alpha=f.opacity))

    rect := core.rect_inflated(f.rect, {-15, -6})

    icon_rect := core.rect_bar_left(rect, rect.h)
    draw_sprite("settings", icon_rect, tint=colors.get(.primary, brightness=-.2, alpha=f.opacity))

    bar_rect := core.rect_bar_right(rect, rect.w-icon_rect.w-10)
    core.rect_inflate(&bar_rect, {0,-10})
    draw_rect_progress_bar_durability(bar_rect,
        value           = slot.durability.value,
        unrepairable    = slot.durability.unrepairable,
        maximum         = slot.item.durability,
        opacity         = f.opacity,
    )
}

draw_tooltip_liquid :: proc (f: ^ui.Frame) {
    slot := ui.user_ptr(f.parent, ^data.Container_Slot)
    assert(slot != nil && slot.item != nil)

    liquid_type := slot.item.liquid_container.type
    assert(liquid_type == .water || liquid_type == .blood)
    liquid_color_id: colors.ID = liquid_type == .water ? .water : .blood

    draw.rect(f.rect, colors.get(.primary, brightness=-.85, alpha=f.opacity))

    rect := core.rect_inflated(f.rect, {-15, -6})

    icon_rect := core.rect_bar_left(rect, rect.h)
    draw_sprite("water_drop", icon_rect, tint=colors.get(liquid_color_id, alpha=f.opacity))

    bar_rect := core.rect_bar_right(rect, rect.w-icon_rect.w-10)
    core.rect_inflate(&bar_rect, {0,-10})
    draw_rect_progress_bar_with_sips(bar_rect,
        value       = slot.liquid_amount,
        maximum     = slot.item.liquid_container.capacity,
        color_id    = liquid_color_id,
        opacity     = f.opacity,
    )
}

draw_attr_rect :: proc (f: ^ui.Frame) {
    i := ui.index(f)
    c := colors.get(.primary, brightness=i%2==0?-.75:-.85, alpha=f.opacity)
    draw.rect(f.rect, c)
}
