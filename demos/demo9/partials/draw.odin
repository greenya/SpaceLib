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

draw_text_aligned :: proc (text: string, pos, align: Vec2, font: ^fonts.Font, color: Color) {
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

    if raylib.IsKeyDown(.LEFT_CONTROL) do draw.debug_terse(f.terse)
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
    assert(f.user_ptr != nil)
    slot := cast (^data.Container_Slot) f.user_ptr

    br_color := colors.get(.primary, alpha=.2)

    if slot.item != nil {
        draw_item_origin_rect(f.rect, slot.item.origin)
        draw_item_icon(f.rect, slot.item.icon)
        draw_item_tier(f.rect, slot.item.tier)

        if slot.item.stack == 1 do draw_item_durability_and_liquid_levels(f.rect, slot)
        else                    do draw_item_stack_count(f.rect, slot.count)

        br_color_hovered := colors.get(.accent)
        hv_ratio := ui.hover_ratio(f, .Linear, .3, .Linear, .3)
        br_color = core.ease_color(br_color, br_color_hovered, hv_ratio, .Linear)
    } else {
        empty_sp_rect := core.rect_scaled(f.rect, .65)
        empty_sp_color := colors.get(.primary, alpha=.1)
        draw_sprite("add", empty_sp_rect, tint=empty_sp_color)
    }

    draw.rect_lines(f.rect, 1, br_color)
}

draw_item_origin_rect :: proc (rect: Rect, origin: data.Item_Origin) {
    t, b: Color
    switch origin {
    case .none      : t=colors.get(.primary, brightness=-.9)    ; b=colors.get(.primary, brightness=-.7)
    case .imperial  : t=colors.get(.imperial, brightness=-.9)   ; b=colors.get(.imperial, brightness=-.6)
    case .house     : t=colors.get(.house, brightness=-.9)      ; b=colors.get(.house, brightness=-.6)
    case .fremen    : t=colors.get(.fremen, brightness=-.9)     ; b=colors.get(.fremen, brightness=-.6)
    case .unique    : t=colors.get(.unique)                     ; b=colors.get(.unique, brightness=-.9)
    case .special   : t=colors.get(.special)                    ; b=colors.get(.special, brightness=-.9)
    }
    draw.rect_gradient_vertical(rect, t, b)
}

draw_item_tier :: proc (rect: Rect, tier: int) {
    text_tiers := [?] string { "", "I", "II", "III", "IV", "V", "VI" }
    if tier < 1 || tier >= len(text_tiers) do return

    text := text_tiers[tier]
    text_pos := core.rect_top_right(rect) + {-8,2}
    text_font := fonts.get(.text_4l)
    text_color := colors.get(.primary, brightness=-.4)
    draw_text_aligned(text, text_pos, {1,0}, text_font, text_color)
}

draw_item_icon :: proc (rect: Rect, icon: string) {
    icon := icon != "" ? icon : "question_mark"
    icon_rect := core.rect_scaled(rect, .8)
    draw_sprite(icon, core.rect_moved(icon_rect, {3,4}), tint=colors.get(.bg1))
    draw_sprite(icon, icon_rect)
}

draw_item_stack_count :: proc (rect: Rect, count: int) {
    if count < 1 do return

    text := core.format_int(count, allocator=context.temp_allocator)
    text_pos := core.rect_bottom_right(rect) - {8,2}
    text_font := fonts.get(.text_4r)
    draw_text_aligned(text, text_pos+{1,2}, 1, text_font, colors.get(.bg0, alpha=.6))
    draw_text_aligned(text, text_pos, 1, text_font, colors.get(.primary))
}

draw_item_durability_and_liquid_levels :: proc (rect: Rect, slot: ^data.Container_Slot) {
    assert(slot.item.stack == 1)

    bar_h :: 4
    bar_offset_y := f32(0)

    if slot.item.durability > 0 {
        bar_rect := core.rect_bar_bottom(core.rect_inflated(rect, -1), bar_h)
        draw_rect_progress_bar_durability(bar_rect,
            value           = slot.durability.value,
            unrepairable    = slot.durability.unrepairable,
            maximum         = slot.item.durability,
        )
        bar_offset_y -= bar_h
    }

    liquid_type := slot.item.liquid_container.type
    if liquid_type != .none {
        bar_rect := core.rect_bar_bottom(core.rect_inflated(rect, -1), bar_h)
        bar_rect.y += bar_offset_y
        #partial switch liquid_type {
        case .water, .blood:
            draw_rect_progress_bar_with_sips(bar_rect,
                value       = slot.liquid_amount,
                maximum     = slot.item.liquid_container.capacity,
                color_id    = liquid_type == .water ? .water : .blood,
            )
        case .fuel:
            draw_rect_progress_bar(bar_rect,
                value       = slot.liquid_amount,
                maximum     = slot.item.liquid_container.capacity,
                color_id    = .water,
            )
        }
    }
}

draw_rect_progress_bar_with_sips :: proc (rect: Rect, value, maximum: f32, color_id: colors.ID) {
    sip_amount :: 250
    sip_gap := rect.h / 2
    sips := int(maximum) / sip_amount
    sip_w := (rect.w - (f32(sips)-1)*sip_gap) / f32(sips)
    sip_rect := Rect { rect.x, rect.y, sip_w, rect.h }
    value_i := int(value) / sip_amount

    empty_color := colors.get(color_id, alpha=.2)
    filled_color := colors.get(color_id)

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

draw_rect_progress_bar :: proc (rect: Rect, value, maximum: f32, color_id: colors.ID) {
    empty_color := colors.get(color_id, brightness=-.8)
    draw.rect(rect, empty_color)

    filled_ratio := core.clamp_ratio(value, 0, maximum)
    filled_rect := core.rect_scaled_top_left(rect, {filled_ratio,1})
    filled_color := colors.get(color_id)
    draw.rect(filled_rect, filled_color)
}

draw_rect_progress_bar_durability :: proc (rect: Rect, value, unrepairable, maximum: f32) {
    draw_rect_progress_bar(rect, value, maximum, .primary)
    if unrepairable > 0 {
        unrepairable_ratio := core.clamp_ratio(unrepairable, 0, maximum)
        unrepairable_rect := core.rect_scaled_top_right(rect, {unrepairable_ratio,1})
        unrepairable_color := colors.get(.unrepairable)
        draw.rect(unrepairable_rect, unrepairable_color)
    }
}

draw_container_volume_bar :: proc (f: ^ui.Frame) {
    ln_thick :: 2
    ln_color := colors.get(.primary, brightness=-.2)

    draw.rect(core.rect_bar_right(f.rect, ln_thick), ln_color)
    draw.rect(core.rect_bar_top(f.rect, ln_thick), ln_color)
    draw.rect(core.rect_bar_bottom(f.rect, ln_thick), ln_color)

    vol_ratio: f32 = f.user_ptr != nil ? (cast (^f32) f.user_ptr)^ : 0

    bar_rect := core.rect_inflated(f.rect, -2)
    for i in ([] struct { ratio: Vec2, pad: Vec2, color: colors.ID } {
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
