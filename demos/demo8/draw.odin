package demo8

import "core:fmt"
import "core:math"
import "core:strings"
import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"

draw_sprite :: proc (name: string, rect: Rect, tint: Color) {
    sprite_ := sprite(name)
    switch info in sprite_.info {
    case Rect   : if sprite_.wrap   do draw.texture_wrap    (sprite_.texture, rect, info, tint=tint)
                  else              do draw.texture         (sprite_.texture, rect, info, tint=tint)
    case Patch  :                      draw.texture_patch   (sprite_.texture, rect, info, tint=tint)
    }
}

draw_text_center :: proc (text: string, rect: Rect, font_name: string, color: Color) {
    font_tr := &font(font_name).font_tr
    draw.text(text, core.rect_center(rect), .5, font_tr, color)
}

draw_text_right :: proc (text: string, pos: Vec2, font_name: string, color: Color) {
    font_tr := &font(font_name).font_tr
    draw.text(text, pos, {1,0}, font_tr, color)
}

draw_icon_key :: proc (text: string, rect: Rect, opacity: f32) {
    bg_color := color("bw_1a", a=opacity)
    draw.rect(rect, bg_color)
    tx_color := color("bw_6c", a=opacity)
    draw_text_center(text, rect, "text_24", tx_color)
}

draw_icon_card :: proc (name: string, rect: Rect, opacity: f32) {
    bg_color := color("bw_40", a=opacity)
    draw_sprite("hexagon", core.rect_inflated(rect, -2), bg_color)
    sp_color := color("bw_bc", a=opacity)
    draw_sprite(name, rect, sp_color)
}

draw_terse :: proc (f: ^ui.Frame, override_color := "", offset := Vec2 {}) {
    assert(f.terse != nil)
    for word in f.terse.words {
        rect := offset != {} ? core.rect_moved(word.rect, offset) : word.rect
        tint := override_color != "" ? color(override_color) : word.color
        tint = core.alpha(tint, f.opacity)
        if word.is_icon {
            has_prefix :: strings.has_prefix
            if has_prefix(word.text, "key.")        do draw_icon_key(word.text[4:], rect, f.opacity) // 4 == len("key.")
            else if has_prefix(word.text, "card.")  do draw_icon_card(word.text[5:], rect, f.opacity) // 5 == len("card.")
            else                                    do draw_sprite(word.text, rect, tint)
        } else if word.text != " " {
            pos := Vec2 { rect.x, rect.y }
            draw.text(word.text, pos, 0, word.font, tint)
        }
    }
}

draw_color_rect :: proc (f: ^ui.Frame) {
    color := color(f.text, a=f.opacity)
    draw.rect(f.rect, color)
}

draw_menu_item :: proc (f: ^ui.Frame) {
    tx_color := color(f.selected ? "bw_da" : "bw_59", a=f.opacity)
    draw_text_center(f.text, f.rect, "text_20", tx_color)
    if f.selected {
        ln_color := color("bw_1a", a=f.opacity)
        draw.rect(core.rect_bar_bottom(f.rect, 4), ln_color)
    }
}

draw_menu_item_nav :: proc (f: ^ui.Frame) {
    offset := f.captured ? Vec2 {0,2} : {}
    tx_color := f.entered ? "bw_da" : "bw_6c"
    draw_terse(f, override_color=tx_color, offset=offset)

    if f.entered {
        ln_color := color("bw_59", a=f.opacity)
        ln_rect := core.rect_moved(core.rect_inflated(f.rect, 5), offset)
        draw.rect_lines(ln_rect, 2, ln_color)
    }
}

draw_art_ring :: proc (f: ^ui.Frame) {
    color := color("bw_40", a=.2*f.opacity)
    center := core.rect_center(f.rect)
    radius := f.rect.h/2
    draw.ring(center, radius, radius+8, 0, 2*math.π, 64, color)
}

draw_player_title :: proc (f: ^ui.Frame) {
    tx_color := color("bw_bc", a=f.opacity)
    draw_text_center(f.text, f.rect, "text_24_sparse", tx_color)
    ln_color := color("bw_59", a=f.opacity)
    ln_rect := core.rect_bar_bottom(f.rect, 3)
    draw.rect(ln_rect, ln_color)
}

draw_slot_hover_state :: proc (f: ^ui.Frame) {
    if f.entered {
        hb_color := color("bw_95", a=f.opacity)
        draw.rect_lines(core.rect_inflated(f.rect, 3), 2, hb_color)
    }
}

draw_slot_ring :: proc (f: ^ui.Frame) {
    bg_color := color("bw_11", a=f.opacity)
    br_color := color("bw_40", a=f.opacity)
    center := core.rect_center(f.rect)
    radius := f.rect.h/2
    draw.circle(center, radius, bg_color)
    draw.ring(center, radius, radius+2, 0, 2*math.π, 32, br_color)
}

draw_slot_round :: proc (f: ^ui.Frame) {
    draw_slot_ring(f)
    sp_color := color("bw_bc", a=f.opacity)
    draw_sprite(f.text, f.rect, sp_color)
}

draw_slot_round_level :: proc (f: ^ui.Frame) {
    draw_slot_ring(f)
    tx_color := color("bw_da", a=f.opacity)
    draw_text_center(f.text, f.rect, "text_24", tx_color)
}

draw_slot_rect :: proc (f: ^ui.Frame) {
    bg_color := color("bw_11", a=f.opacity)
    br_color := color("bw_40", a=f.opacity)
    draw.rect(f.rect, bg_color)
    draw.rect_lines(f.rect, 2, br_color)
}

draw_slot_box_wide :: proc (f: ^ui.Frame) {
    draw_slot_rect(f)
    if f.text != "" {
        sp_color := color("bw_bc", a=f.opacity)
        rect := f.rect
        rect.w = rect.h
        draw_sprite(f.text, core.rect_inflated(rect, -8), sp_color)
    }
}

draw_perk :: proc (name: string, rect: Rect, opacity: f32) {
    bg_color := color("bw_bc", a=opacity)
    draw.rect(rect, bg_color)

    br_color := color("bw_40", a=opacity)
    draw.rect_lines(rect, 2, br_color)

    sp_color := color("bw_1a", a=opacity)
    draw_sprite(name, core.rect_inflated(rect, -8), sp_color)
}

draw_perk_cat :: proc (name: string, perk_rect: Rect, opacity: f32) {
    cat_color := color("bw_bc", a=opacity)
    cat_rect := core.rect_from_center(core.rect_center(perk_rect)-{0,perk_rect.h/1.1}, {perk_rect.w,perk_rect.h}/1.7)
    draw_sprite(name, cat_rect, cat_color)
}

draw_slot_perk :: proc (f: ^ui.Frame) {
    draw_perk(f.text, f.rect, f.opacity)
}

draw_slot_perk_with_cat :: proc (f: ^ui.Frame) {
    rect := f.rect
    rect.y += rect.h-rect.w
    rect.h = rect.w
    draw_perk(f.text, rect, f.opacity)
    draw_perk_cat("graduate-cap", rect, f.opacity)
}

draw_slot_trait :: proc (f: ^ui.Frame) {
    if f.text == "" {
        br_color := color("bw_1a", a=f.opacity)
        draw.rect_lines(f.rect, 2, br_color)
        return
    }

    trait := app.data.traits[f.text]
    is_flat := strings.has_suffix(f.name, ".flat")

    bg_color := color("bw_1a", a=f.opacity)
    draw.rect(f.rect, bg_color)

    rect := f.rect
    rect.y += (rect.h-rect.w)/2
    rect.h = rect.w
    sp_color := color(trait.active ? "trait_hl" : "bw_95", a=f.opacity)
    hover_ratio := is_flat ? 1 : 1-ui.hover_ratio(f, .Exponential_Out, .333, .Exponential_In, .555)
    draw_sprite(trait.icon, core.rect_inflated(rect, -8*hover_ratio), sp_color)

    if !is_flat {
        nm_rect := core.rect_bar_bottom(core.rect_inflated(f.rect, -8), 48)
        draw_text_center(trait.name, nm_rect, "text_16", sp_color)

        for lv := max_trait_levels; lv > 0; lv -= 1 {
            pr_rect := core.rect_bar_bottom(nm_rect, nm_rect.w/max_trait_levels)
            pr_rect.w /= max_trait_levels
            pr_rect.x += f32(lv-1)*pr_rect.w

            pr_color_name := "bw_40"
            if lv <= trait.levels_granted+trait.levels_bought   do pr_color_name = "bw_95"
            if lv <= trait.levels_granted                       do pr_color_name = "res_fire"
            pr_color := color(pr_color_name, a=f.opacity)

            draw_sprite("round-star", core.rect_inflated(pr_rect, 4), pr_color)
        }
    }

    br_color := color("bw_20", a=f.opacity)
    draw.rect_lines(f.rect, 2, br_color)

    if !is_flat do draw_slot_hover_state(f)
}

draw_slot_skill :: proc (f: ^ui.Frame) {
    assert(f.text != "")

    skill := app.data.skills[f.text]

    draw_slot_rect(f)

    if skill.selected && f.order == 0 {
        sl_color := color("bw_95", a=f.opacity)
        draw.rect_lines(f.rect, 4, sl_color)
    }

    sp_color := color("bw_bc", a=f.opacity)
    draw_sprite(skill.icon, core.rect_inflated(f.rect, -8), sp_color)

    draw_slot_hover_state(f)
}

draw_slot_item :: proc (f: ^ui.Frame) {
    if f.text == "" {
        br_color := color("bw_1a", a=f.opacity)
        draw.rect_lines(f.rect, 2, br_color)
        return
    }

    item := app.data.items[f.text]
    is_gear := f.name == "slot_gear"

    bg_color_name := is_gear ? "bw_11" : "bw_1a"
    bg_color := color(bg_color_name, a=f.opacity)
    draw.rect(f.rect, bg_color)

    sp_color := color("bw_bc", a=f.opacity)
    draw_sprite(item.icon, core.rect_inflated(f.rect, -8), sp_color)

    if !is_gear && item.count > 1 {
        count_text := fmt.tprintf("x%i", item.count)
        count_pos := Vec2 { f.rect.x+f.rect.w, f.rect.y } + {-4,4}
        count_color := color("bw_95", a=f.opacity)
        count_color_shadow := color("bw_1a", a=f.opacity)
        draw_text_right(count_text, count_pos+{-2,1}, "text_18_bold", count_color_shadow)
        draw_text_right(count_text, count_pos, "text_18_bold", count_color)
    }

    br_color := color("bw_20", a=f.opacity)
    draw.rect_lines(f.rect, 2, br_color)

    draw_slot_hover_state(f)
}

draw_tooltip_bg :: proc (f: ^ui.Frame) {
    color := color("bw_40", a=f.opacity)
    draw_sprite("stripes-diagonal", f.rect, color)
}

draw_tooltip_title :: proc (f: ^ui.Frame) {
    bg_color := color("bw_00", a=.8*f.opacity)
    draw.rect(f.rect, bg_color)
    draw_terse(f)
}

draw_tooltip_subtitle :: proc (f: ^ui.Frame) {
    bg_color := color("bw_11", a=.9*f.opacity)
    draw.rect(f.rect, bg_color)
    draw_terse(f)
}

draw_tooltip_desc :: proc (f: ^ui.Frame) {
    bg_color := color("bw_20", a=.9*f.opacity)
    draw.rect(f.rect, bg_color)
    draw_terse(f)
}

draw_tooltip_body :: proc (f: ^ui.Frame) {
    bg_color := color("bw_2c", a=.9*f.opacity)
    draw.rect(f.rect, bg_color)
    draw_terse(f)
}

draw_tooltip_image :: proc(f: ^ui.Frame) {
    bg_color := color("bw_1a", a=f.opacity)
    draw_sprite("criss-cross", f.rect, bg_color)

    sp_color := color("bw_bc", a=f.opacity)
    rect := core.rect_from_center(core.rect_center(f.rect), 128)
    draw_sprite(f.text, rect, sp_color)
}

draw_tooltip_stats :: proc (f: ^ui.Frame) {
    bg_color := color("bw_18", a=.9*f.opacity)
    draw.rect(f.rect, bg_color)
}

draw_tooltip_resists :: proc (f: ^ui.Frame) {
    bg_color := color("bw_2c", a=.9*f.opacity)
    draw.rect(f.rect, bg_color)
}

draw_tooltip_resists_item :: proc (f: ^ui.Frame) {
    sp_color := color("bw_95", a=f.opacity)
    sp_rect := f.rect
    sp_rect.h = sp_rect.w
    sp_rect = core.rect_moved(core.rect_inflated(sp_rect, -6), {0,-4})

    sp_name := "???"
    switch f.name {
    case "bleed"    : sp_name = "water-drop"
    case "fire"     : sp_name = "candlebright"
    case "lightning": sp_name = "power-lightning"
    case "poison"   : sp_name = "crossed-bones"
    case "blight"   : sp_name = "harry-potter-skull"
    }

    draw_sprite(sp_name, sp_rect, sp_color)

    tx_color := color("bw_da", a=f.opacity)
    tx_rect := core.rect_moved(sp_rect, {0, sp_rect.h+8})
    draw_text_center(f.text, tx_rect, "text_32", tx_color)
}

draw_tooltip_actions :: proc (f: ^ui.Frame) {
    bg_color := color("bw_00", a=.8*f.opacity)
    draw.rect(f.rect, bg_color)
    draw_terse(f)
}
