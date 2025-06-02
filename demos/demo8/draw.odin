package demo8

import "core:fmt"
import "core:strings"
import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"
import "spacelib:terse"
import rl "vendor:raylib"

draw_sprite :: proc (name: string, rect: Rect, tint: Color) {
    fmt.assertf(name in app.res.sprites, "Unknown sprite: \"%s\"", name)

    sprite := app.res.sprites[name]
    tex_rl := app.res.textures[sprite.texture].texture_rl

    switch info in sprite.info {
    case Rect           : if sprite.wrap    do draw.texture_wrap    (tex_rl, info, rect, tint=tint)
                          else              do draw.texture         (tex_rl, info, rect, tint=tint)
    case rl.NPatchInfo  :                      draw.texture_npatch  (tex_rl, info, rect, tint=tint)
    }
}

draw_text_center :: proc (text: string, rect: Rect, font_name: string, color: Color) {
    font_tr := &app.res.fonts[font_name].font_tr
    draw.text_center(text, core.rect_center(rect), font_tr, color)
}

draw_text_right :: proc (text: string, pos: Vec2, font_name: string, color: Color) {
    font_tr := &app.res.fonts[font_name].font_tr
    draw.text_right(text, pos, font_tr, color)
}

draw_icon_key :: proc (text: string, rect: Rect, opacity: f32) {
    bg_color := core.alpha(app.res.colors["bw_1a"].value, opacity)
    draw.rect(rect, bg_color)
    tx_color := core.alpha(app.res.colors["bw_6c"].value, opacity)
    draw_text_center(text, rect, "text_24", tx_color)
}

draw_icon_card :: proc (name: string, rect: Rect, opacity: f32) {
    bg_color := core.alpha(app.res.colors["bw_40"].value, opacity)
    draw_sprite("hexagon", core.rect_inflated(rect, -2), bg_color)
    sp_color := core.alpha(app.res.colors["bw_bc"].value, opacity)
    draw_sprite(name, rect, sp_color)
}

draw_terse :: proc (t: ^terse.Terse, override_color := "", offset := Vec2 {}) {
    for word in t.words {
        // if word.in_group do continue

        rect := offset != {} ? core.rect_moved(word.rect, offset) : word.rect
        tint := override_color != "" ? app.res.colors[override_color].value : word.color
        tint = core.alpha(tint, t.opacity)
        if word.is_icon {
            has_prefix :: strings.has_prefix
            if has_prefix(word.text, "key.")        do draw_icon_key(word.text[4:], rect, t.opacity)
            else if has_prefix(word.text, "card.")  do draw_icon_card(word.text[5:], rect, t.opacity)
            else                                    do draw_sprite(word.text, rect, tint)
        } else if word.text != " " {
            pos := Vec2 { rect.x, rect.y }
            font := word.font
            font_rl := (cast (^rl.Font) font.font_ptr)^
            draw.text(word.text, pos, font_rl, font.height, font.rune_spacing, tint)
        }
    }

    if app.debug_drawing do draw.debug_terse(t)
}

draw_color_rect :: proc (f: ^ui.Frame) {
    color := core.alpha(app.res.colors[f.text], f.opacity)
    draw.rect(f.rect, color)
}

draw_menu_item :: proc (f: ^ui.Frame) {
    tx_color := core.alpha(app.res.colors[f.selected ? "bw_da" : "bw_59"], f.opacity)
    draw_text_center(f.text, f.rect, "text_20", tx_color)
    if f.selected {
        ln_color := core.alpha(app.res.colors["bw_1a"].value, f.opacity)
        draw.rect(core.rect_line_bottom(f.rect, 4), ln_color)
    }
}

draw_art_ring :: proc (f: ^ui.Frame) {
    color := core.alpha(app.res.colors["bw_40"].value, .2*f.opacity)
    center := core.rect_center(f.rect)
    radius := f.rect.h/2
    draw.ring(center, radius, radius+8, 0, 360, 64, color)
}

draw_player_title :: proc (f: ^ui.Frame) {
    tx_color := core.alpha(app.res.colors["bw_bc"].value, f.opacity)
    draw_text_center(f.text, f.rect, "text_24_sparse", tx_color)
    ln_color := core.alpha(app.res.colors["bw_59"].value, f.opacity)
    ln_rect := core.rect_line_bottom(f.rect, 3)
    draw.rect(ln_rect, ln_color)
}

draw_slot_ring :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(app.res.colors["bw_11"].value, f.opacity)
    br_color := core.alpha(app.res.colors["bw_40"].value, f.opacity)
    center := core.rect_center(f.rect)
    radius := f.rect.h/2
    draw.circle(center, radius, bg_color)
    draw.ring(center, radius, radius+2, 0, 360, 32, br_color)
}

draw_slot_round :: proc (f: ^ui.Frame) {
    draw_slot_ring(f)
    sp_color := core.alpha(app.res.colors["bw_bc"].value, f.opacity)
    draw_sprite(f.text, f.rect, sp_color)
}

draw_slot_round_level :: proc (f: ^ui.Frame) {
    draw_slot_ring(f)
    tx_color := core.alpha(app.res.colors["bw_da"], f.opacity)
    draw_text_center(f.text, f.rect, "text_24", tx_color)
}

draw_slot_rect :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(app.res.colors["bw_11"].value, f.opacity)
    br_color := core.alpha(app.res.colors["bw_40"].value, f.opacity)
    draw.rect(f.rect, bg_color)
    draw.rect_lines(f.rect, 2, br_color)
}

draw_slot_box :: proc (f: ^ui.Frame) {
    draw_slot_rect(f)
    if f.text != "" {
        sp_color := core.alpha(app.res.colors["bw_bc"].value, f.opacity)
        draw_sprite(f.text, core.rect_inflated(f.rect, -8), sp_color)
    }
}

draw_slot_box_wide :: proc (f: ^ui.Frame) {
    draw_slot_rect(f)
    if f.text != "" {
        sp_color := core.alpha(app.res.colors["bw_bc"].value, f.opacity)
        rect := f.rect
        rect.w = rect.h
        draw_sprite(f.text, core.rect_inflated(rect, -8), sp_color)
    }
}

draw_perk :: proc (name: string, rect: Rect, opacity: f32) {
    bg_color := core.alpha(app.res.colors["bw_bc"].value, opacity)
    draw.rect(rect, bg_color)

    br_color := core.alpha(app.res.colors["bw_40"].value, opacity)
    draw.rect_lines(rect, 2, br_color)

    sp_color := core.alpha(app.res.colors["bw_1a"].value, opacity)
    draw_sprite(name, core.rect_inflated(rect, -8), sp_color)
}

draw_perk_cat :: proc (name: string, perk_rect: Rect, opacity: f32) {
    cat_color := core.alpha(app.res.colors["bw_bc"].value, opacity)
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
        br_color := core.alpha(app.res.colors["bw_1a"].value, f.opacity)
        draw.rect_lines(f.rect, 2, br_color)
        return
    }

    trait := app.data.traits[f.text]

    bg_color := core.alpha(app.res.colors["bw_1a"].value, f.opacity)
    draw.rect(f.rect, bg_color)

    rect := f.rect
    rect.y += (rect.h-rect.w)/2
    rect.h = rect.w
    sp_color := core.alpha(app.res.colors[trait.active ? "trait_hl" : "bw_95"].value, f.opacity)
    draw_sprite(trait.icon, core.rect_inflated(rect, -8), sp_color)

    if strings.has_suffix(f.name, ".ex") {
        nm_rect := core.rect_line_bottom(core.rect_inflated(f.rect, -8), 48)
        draw_text_center(trait.name, nm_rect, "text_16", sp_color)

        for lv := max_trait_levels; lv > 0; lv -= 1 {
            pr_rect := core.rect_line_bottom(nm_rect, nm_rect.w/max_trait_levels)
            pr_rect.w /= max_trait_levels
            pr_rect.x += f32(lv-1)*pr_rect.w

            pr_color_name := "bw_40"
            if lv <= trait.levels_granted+trait.levels_bought   do pr_color_name = "bw_95"
            if lv <= trait.levels_granted                       do pr_color_name = "res_fire"
            pr_color := core.alpha(app.res.colors[pr_color_name].value, f.opacity)

            draw_sprite("round-star", core.rect_inflated(pr_rect, 4), pr_color)
        }
    }

    br_color := core.alpha(app.res.colors["bw_20"].value, f.opacity)
    draw.rect_lines(f.rect, 2, br_color)
}

draw_slot_item :: proc (f: ^ui.Frame) {
    if f.text == "" {
        br_color := core.alpha(app.res.colors["bw_1a"].value, f.opacity)
        draw.rect_lines(f.rect, 2, br_color)
        return
    }

    item := app.data.items[f.text]

    bg_color := core.alpha(app.res.colors["bw_1a"].value, f.opacity)
    draw.rect(f.rect, bg_color)

    sp_color := core.alpha(app.res.colors["bw_bc"].value, f.opacity)
    draw_sprite(item.icon, core.rect_inflated(f.rect, -8), sp_color)

    if item.count > 1 {
        count_text := fmt.tprintf("x%i", item.count)
        count_pos := Vec2 { f.rect.x+f.rect.w, f.rect.y } + {-4,4}
        count_color := core.alpha(app.res.colors["bw_95"].value, f.opacity)
        count_color_shadow := core.alpha(app.res.colors["bw_1a"].value, f.opacity)
        draw_text_right(count_text, count_pos+{-2,1}, "text_18_bold", count_color_shadow)
        draw_text_right(count_text, count_pos, "text_18_bold", count_color)
    }

    br_color := core.alpha(app.res.colors["bw_20"].value, f.opacity)
    draw.rect_lines(f.rect, 2, br_color)
}

draw_tooltip_before :: proc (f: ^ui.Frame) {
    draw_sprite("stripes-diagonal", f.rect, {80,80,80,255})
}

draw_tooltip_after :: proc (f: ^ui.Frame) {
    ln_color := core.alpha(app.res.colors["bw_2c"].value, f.opacity)
    draw.rect(core.rect_line_top(f.rect, 4), ln_color)
    draw.rect(core.rect_line_bottom(f.rect, 4), ln_color)
}

draw_tooltip_title :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(app.res.colors["bw_00"].value, .8* f.opacity)
    draw.rect(f.rect, bg_color)
    draw_terse(f.terse)
}

draw_tooltip_subtitle :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(app.res.colors["bw_11"].value, .9* f.opacity)
    draw.rect(f.rect, bg_color)
    draw_terse(f.terse)
}

draw_tooltip_desc :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(app.res.colors["bw_20"].value, .9* f.opacity)
    draw.rect(f.rect, bg_color)
    draw_terse(f.terse)
}

draw_tooltip_body :: proc (f: ^ui.Frame) {
    bg_color := core.alpha(app.res.colors["bw_2c"].value, .9* f.opacity)
    draw.rect(f.rect, bg_color)
    draw_terse(f.terse)
}
