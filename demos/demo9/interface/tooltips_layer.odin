#+private
package interface

import "core:fmt"
import "core:math/ease"
import "core:strings"

import "spacelib:core"
import "spacelib:ui"

import "../data"
import "../events"
import "../partials"

tooltips: struct {
    layer   : ^ui.Frame,

    tooltip : struct {
        root            : ^ui.Frame,
        title           : ^ui.Frame,
        image           : ^ui.Frame,
        durability_bar  : ^ui.Frame,
        liquid_bar      : ^ui.Frame,
        liquid_cap      : ^ui.Frame,
        desc            : ^ui.Frame,
        attrs           : [16] ^ui.Frame,

        // we hold a copy (value) of the slot, so we can render its details even when its not available,
        // for example when slot moves (swapped); another approach would be to skip drawing parts which are
        // not avail, but that will lead to twitching of the tooltip (in rare specific cases for, but still)
        // so we need to keep rendering the tooltip for the duration it disappears;
        // the only thing references this value is tooltip.root.user_ptr, and it is used by drawing procs;
        // we clear this value when tooltip finishes disappearing
        data_container_slot: data.Container_Slot,
    },
}

add_tooltips_layer :: proc (order: int) {
    assert(tooltips.layer == nil)

    tooltips.layer = ui.add_frame(ui_.root, {
        name    = "tooltips_layer",
        flags   = {.pass},
        order   = order,
    }, { point=.top_left }, { point=.bottom_right })

    tt := &tooltips.tooltip

    tt.root = ui.add_frame(tooltips.layer, {
        name    = "tooltip",
        flags   = {.hidden},
        size    = {420,0},
        layout  = ui.Flow{ dir=.down, auto_size={.height} },
        text    = "primary_d8",
        draw    = partials.draw_color_rect,
    })

    tt.title = ui.add_frame(tt.root, {
        name        = "title",
        text_format = "<wrap,left,pad=8:2,font=text_4l,color=primary_d2>%s - %s\n<font=text_5m,color=primary_l4,gap=-.1>%s",
        flags       = {.terse,.terse_height},
        draw        = partials.draw_hexagon_rect_wide_hangout,
    })

    tt.image = ui.add_frame(tt.root, {
        name = "image",
        size = {0,150},
        draw = partials.draw_tooltip_image,
    })

    tt.durability_bar = ui.add_frame(tt.root, {
        name = "durability_bar",
        size = {0,40},
        draw = partials.draw_tooltip_durability,
    })

    tt.liquid_bar = ui.add_frame(tt.root, {
        name = "liquid_bar",
        size = {0,40},
        draw = partials.draw_tooltip_liquid,
    })

    tt.liquid_cap = add_tooltip_attr(tt.root, name="liquid_cap")

    tt.desc = ui.add_frame(tt.root, {
        name        = "desc",
        text_format = "<wrap,left,pad=10:5,font=text_4l,color=primary_l4>%s",
        flags       = {.terse,.terse_height},
        draw        = partials.draw_text_drop_shadow,
    })

    for &attr, i in tt.attrs do attr = add_tooltip_attr(tt.root, name=fmt.tprintf("attr_%i", i+1))

    events.listen(.show_tooltip, show_tooltip_listener)
    events.listen(.hide_tooltip, hide_tooltip_listener)
}

show_tooltip_listener :: proc (args: events.Args) {
    args := args.(events.Show_Tooltip)

    tt := &tooltips.tooltip
    assert(tt.root != nil)

    // ending potentially running anim_tooltip_disappear() now, as it does following on finalization:
    // - clears data_container_slot // we set later by setup_tooltip_for_container_slot()
    // - clears anchors // we set later by anchor_tooltip()
    ui.end_animation(tt.root)

    switch o in args.object {
    case ^data.Container_Slot   : setup_tooltip_for_container_slot(o)
    case                        : fmt.panicf("Unexpected object for the tooltip: any.id=%v", args.object.id)
    }

    anchor_tooltip(args.frame)
    ui.animate(tt.root, anim_tooltip_appear, .222)
    // fmt.println("show", ui.index(args.frame))
}

hide_tooltip_listener :: proc (args: events.Args) {
    args := args.(events.Hide_Tooltip)

    tt := &tooltips.tooltip
    assert(tt.root != nil)

    if .hidden in tt.root.flags do return
    if len(tt.root.anchors) == 0 do return
    if tt.root.anchors[0].rel_frame != args.frame do return

    ui.animate(tt.root, anim_tooltip_disappear, .222)
    // fmt.println("hide", ui.index(args.frame))
}

anchor_tooltip :: proc (rel_frame: ^ui.Frame) {
    tt := &tooltips.tooltip
    tt_rect := &tooltips.tooltip.root.rect
    safe_rect := core.rect_inflated(tooltips.layer.rect, {-30,-10})

    debug :: false
    if debug do fmt.println("------------------------+")
    if debug do fmt.println("layer\t\t\t:", core.rect_ltrb(safe_rect))

    ui.set_anchors(tt.root, { point=.top_left, rel_point=.top_right, rel_frame=rel_frame, offset={60,-10} })
    ui.update(tt.root, include_hidden=true, repeat=5)

    if debug do fmt.println("anchored to the right\t:", core.rect_ltrb(tt_rect^))

    is_offscreen_right := tt_rect.x+tt_rect.w > safe_rect.x+safe_rect.w
    if is_offscreen_right {
        ui.set_anchors(tt.root, { point=.top_right, rel_point=.top_left, rel_frame=rel_frame, offset={-60,-10} })
        ui.update(tt.root, include_hidden=true, repeat=5)
        if debug do fmt.println("anchored to the left\t:", core.rect_ltrb(tt_rect^))
    }

    offscreen_bottom_amount := tt_rect.y+tt_rect.h - (safe_rect.y+safe_rect.h)
    if offscreen_bottom_amount > 0 {
        tt.root.anchors[0].offset.y -= offscreen_bottom_amount
        ui.update(tt.root, include_hidden=true, repeat=5)
        if debug do fmt.println("moved up to fit in safe\t:", core.rect_ltrb(tt_rect^))
    }

    if debug do fmt.println("------------------------+")
}

anim_tooltip_appear :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 do ui.show(f)

    ratio := ease.cubic_out(f.anim.ratio)
    ui.set_opacity(f, ratio)
    f.offset = f.anchors[0].point == .top_left\
        ? {40*(1-ratio),0}\
        : {-40*(1-ratio),0}
}

anim_tooltip_disappear :: proc (f: ^ui.Frame) {
    ratio := ease.cubic_in(f.anim.ratio)
    ui.set_opacity(f, 1-ratio)
    f.offset = f.anchors[0].point == .top_left\
        ? {40*ratio,0}\
        : {-40*ratio,0}

    if f.anim.ratio == 1 {
        tooltips.tooltip.data_container_slot = {}
        f.offset = 0
        ui.clear_anchors(f)
        ui.hide(f)
    }
}

add_tooltip_attr :: proc (parent: ^ui.Frame, name: string, title := "") -> ^ui.Frame {
    row := ui.add_frame(parent, {
        name    = name,
        layout  = ui.Flow { dir=.down, auto_size={.height} },
        draw    = partials.draw_attr_rect,
    })

    title := ui.add_frame(row, {
        name        = "title",
        flags       = {.terse,.terse_height},
        size        = {300,0},
        text        = title,
        text_format = "<wrap,left,pad=10:4,font=text_4l,color=primary_d2>%s",
        draw        = partials.draw_text_drop_shadow,
    })

    ui.add_frame(row, {
        name        = "value",
        flags       = {.terse},
        text_format = "<right,pad=10:4,font=text_4l,color=primary_l4>%s",
        draw        = partials.draw_text_drop_shadow,
    },
        { point=.top_right },
        { point=.bottom_left, rel_point=.bottom_right, rel_frame=title },
    )

    return row
}

get_tooltip_next_attr_row :: proc () -> ^ui.Frame {
    for a in tooltips.tooltip.attrs do if .hidden in a.flags do return a
    panic("Tooltip max attribute rows overflow")
}

show_tooltip_attr_int :: proc (title: string, value: int, format := "", keep_zero := false, attr: ^ui.Frame = nil) {
    if value == 0 && !keep_zero do return
    attr := attr != nil ? attr : get_tooltip_next_attr_row()

    ui.set_text(ui.get(attr, "title"), title)

    value_text := format != ""\
        ? fmt.tprintf(format, value)\
        : core.format_int_tmp(value)
    ui.set_text(ui.get(attr, "value"), value_text)

    ui.show(attr)
}

show_tooltip_attr_f32 :: proc (title: string, value: f32, format := "", keep_zero := false, attr: ^ui.Frame = nil) {
    if value == 0 && !keep_zero do return
    attr := attr != nil ? attr : get_tooltip_next_attr_row()

    ui.set_text(ui.get(attr, "title"), title)

    value_text := format != ""\
        ? fmt.tprintf(format, value)\
        : core.format_f32_tmp(value, max_decimal_digits=2)
    ui.set_text(ui.get(attr, "value"), value_text)

    ui.show(attr)
}

show_tooltip_attr_any :: proc (title: string, value: any, attr: ^ui.Frame = nil) {
    attr := attr != nil ? attr : get_tooltip_next_attr_row()

    ui.set_text(ui.get(attr, "title"), title)

    value_text: string
    value_type_info := type_info_of(value.id)
    switch value_type_info.id {
    case data.Item_Stat_Type_Intensity:
        i := (cast (^data.Item_Stat_Type_Intensity) value.data)^
        value_text = data.item_stat_type_intensity_names[i]
    case data.Item_Stat_Type_Range:
        i := (cast (^data.Item_Stat_Type_Range) value.data)^
        value_text = data.item_stat_type_range_names[i]
    case data.Item_Stat_Type_Damage:
        i := (cast (^data.Item_Stat_Type_Damage) value.data)^
        value_text = data.item_stat_type_damage_names[i]
    case data.Item_Stat_Type_Fire_Mode:
        i := (cast (^data.Item_Stat_Type_Fire_Mode) value.data)^
        value_text = data.item_stat_type_fire_mode_names[i]
    case:
        value_text = fmt.tprint(value)
    }

    ui.set_text(ui.get(attr, "value"), value_text)

    ui.show(attr)
}

setup_tooltip_for_container_slot :: proc (slot: ^data.Container_Slot) {
    assert(slot.item != nil)

    tt := &tooltips.tooltip
    tt.data_container_slot = slot^
    ui.set_user_ptr(tt.root, &tt.data_container_slot)

    ui.hide_children(tt.root)

    item_cat, item_sub_cat := data.get_item_category(slot.item)
    item_cat = strings.to_upper(item_cat, context.temp_allocator)
    item_sub_cat = strings.to_upper(item_sub_cat, context.temp_allocator)
    ui.set_text(tt.title, item_cat, item_sub_cat, slot.item.name, shown=true)

    ui.show(tt.image)

    if slot.item.durability > 0 do ui.show(tt.durability_bar)

    liquid_type := slot.item.liquid_container.type
    if liquid_type == .water || liquid_type == .blood {
        ui.show(tt.liquid_bar)
        title := .stillsuits in slot.item.tags\
            ? "Catchpocket Size"\
            : "Container Capacity"
        show_tooltip_attr_int(title, int(slot.item.liquid_container.capacity), attr=tt.liquid_cap)
    }

    item_desc := data.text_to_string(slot.item.desc, context.temp_allocator)
    if item_desc != "" do ui.set_text(tt.desc, item_desc, shown=true)

    switch s in slot.item.stats {
    case data.Item_Stats_Belt:
        show_tooltip_attr_any("Worm Attraction Intensity", s.worm_attraction_intensity)
        show_tooltip_attr_f32("Power Drain", s.power_drain)

    case data.Item_Stats_Compactor:
        show_tooltip_attr_any("Gather Rate", s.gather_rate)
        show_tooltip_attr_any("Power Consumption", s.power_consumption)
        show_tooltip_attr_any("Worm Attraction Intensity", s.worm_attraction_intensity)

    case data.Item_Stats_Cutteray:
        show_tooltip_attr_any("Power Consumption (per second)", s.power_consumption_per_second)

    case data.Item_Stats_Garment:
        show_tooltip_attr_f32("Armor Value", s.armor_value)

        show_tooltip_attr_f32("Dash Stamina Cost", s.dash_stamina_cost, format="%+.1f%%")
        show_tooltip_attr_f32("Climbing Stamina Cost", s.climbing_stamina_cost, format="%+.1f%%")
        show_tooltip_attr_f32("Worm Threat", s.worm_threat, format="%+.1f%%")
        show_tooltip_attr_f32("Sun Stroke Rate", s.sun_stroke_rate, format="%+.1f%%")

        show_tooltip_attr_f32("Blade Mitigation", s.blade_mitigation, format="%+.1f%%")
        show_tooltip_attr_f32("Light Dart Mitigation", s.light_dart_mitigation, format="%+.1f%%")
        show_tooltip_attr_f32("Heavy Dart Mitigation", s.heavy_dart_mitigation, format="%+.1f%%")
        show_tooltip_attr_f32("Energy Mitigation", s.energy_mitigation, format="%+.1f%%")
        show_tooltip_attr_f32("Fire Mitigation", s.fire_mitigation, format="%+.1f%%")
        show_tooltip_attr_f32("Poison Mitigation", s.poison_mitigation, format="%+.1f%%")
        show_tooltip_attr_f32("Radiation Mitigation", s.radiation_mitigation, format="%+.1f%%")
        show_tooltip_attr_f32("Concussive Mitigation", s.concussive_mitigation, format="%+.1f%%")

        show_tooltip_attr_f32("Hydration Capture", s.hydration_capture, format="%+.1f%%")
        show_tooltip_attr_f32("Heat Protection", s.heat_protection)

    case data.Item_Stats_Healkit:
        show_tooltip_attr_f32("Health Restoration Over Time", s.health_restoration_over_time)
        show_tooltip_attr_f32("Instant Health Restoration", s.instant_health_restoration)

    case data.Item_Stats_Power_Pack:
        show_tooltip_attr_any("Regen (per second)", s.regen_per_second)
        show_tooltip_attr_any("Power Pool", s.power_pool)

    case data.Item_Stats_Shield:
        show_tooltip_attr_any("Worm Attraction Intensity", s.worm_attraction_intensity)
        show_tooltip_attr_f32("Shield Refresh Time", s.shield_refresh_time)
        show_tooltip_attr_f32("Power Drain (%)", s.power_drain_percent)

    case data.Item_Stats_Stilltent:
        show_tooltip_attr_f32("Water Gather Rate", s.water_gather_rate)

    case data.Item_Stats_Weapon_Melee:
        show_tooltip_attr_any("Damage Type", s.damage_type)
        show_tooltip_attr_f32("Damage Per Hit", s.damage_per_hit)
        show_tooltip_attr_f32("Attack Speed", s.attack_speed)

    case data.Item_Stats_Weapon_Ranged:
        show_tooltip_attr_any("Damage Type", s.damage_type)
        show_tooltip_attr_any("Fire Mode", s.fire_mode)
        show_tooltip_attr_f32("Damage Per Shot", s.damage_per_shot)
        show_tooltip_attr_int("Rate of Fire", s.rate_of_fire, format="%i RPM")
        show_tooltip_attr_int("Clip Size", s.clip_size)
        show_tooltip_attr_f32("Reload Speed", s.reload_speed, format="%.1f s")
        show_tooltip_attr_f32("Effective Range", s.effective_range, format="%.1f m")
        show_tooltip_attr_f32("Accuracy", s.accuracy)
        show_tooltip_attr_f32("Stability", s.stability)

    case data.Item_Stats_Welding_Torch:
        show_tooltip_attr_any("Range", s.range)
        show_tooltip_attr_f32("Repair Quality", s.repair_quality, format="%.1f%%")
        show_tooltip_attr_f32("Repair Speed", s.repair_speed, format="%.1f")
        show_tooltip_attr_f32("Detach Speed", s.detach_speed, format="%.1f")
        show_tooltip_attr_any("Power Consumption (per second)", s.power_consumption_per_second)
    }
}
