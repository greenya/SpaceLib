#+private
package interface

import "core:fmt"
import "core:math/ease"

import "spacelib:ui"

import "../data"
import "../events"
import "../partials"

tooltips: struct {
    layer   : ^ui.Frame,

    tooltip : struct {
        root        : ^ui.Frame,
        title       : ^ui.Frame,
        image       : ^ui.Frame,
        durability  : ^ui.Frame,
        liquid      : ^ui.Frame,
        desc        : ^ui.Frame,

        // we hold a copy (value) of the slot, so we can render its details even when its not available,
        // for example when slot moves (swapped); another approach would be to skip drawing parts which are
        // not avail, but that will lead to twitching of the tooltip (in rare specific cases for, but still)
        // so we need to keep rendering the tooltip for the duration it disappears;
        // the only thing references this value is tooltip.root.user_ptr, and it is used by drawing procs;
        // we clear this value when tooltip finishes disappearing
        // note: the issue probably will be when showing the tooltip and the slot state changes, like stack size,
        // durability, liquid level etc. -- the tooltip will keep showing old state
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
        size    = {450,0},
        layout  = ui.Flow{ dir=.down, auto_size={.height} },
        text    = "primary_d7",
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

    tt.durability = ui.add_frame(tt.root, {
        name = "durability",
        size = {0,44},
        draw = partials.draw_tooltip_durability,
    })

    tt.liquid = ui.add_frame(tt.root, {
        name = "liquid",
        size = {0,44},
        draw = partials.draw_tooltip_liquid,
    })

    tt.desc = ui.add_frame(tt.root, {
        name        = "desc",
        text_format = "<wrap,left,pad=10:5,font=text_4l,color=primary_l4>%s",
        flags       = {.terse,.terse_height},
        draw        = partials.draw_text_drop_shadow,
    })

    events.listen(.show_tooltip, show_tooltip_listener)
    events.listen(.hide_tooltip, hide_tooltip_listener)
}

show_tooltip_listener :: proc (args: events.Args) {
    args := args.(events.Show_Tooltip)

    tt := &tooltips.tooltip
    assert(tt.root != nil)

    // ending potentially running anim_tooltip_disappear() now, as it does following on finalization:
    // - clears data_container_slot // set later by setup_tooltip_for_container_slot()
    // - clears anchors // set later by anchor_tooltip()
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

    ui.set_anchors(tt.root, { point=.top_left, rel_point=.top_right, rel_frame=rel_frame, offset={20,0} })
    ui.update(tt.root, include_hidden=true, repeat=2)
}

anim_tooltip_appear :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 do ui.show(f)

    ratio := ease.cubic_out(f.anim.ratio)
    ui.set_opacity(f, ratio)
    f.offset = {40*(1-ratio),0}
}

anim_tooltip_disappear :: proc (f: ^ui.Frame) {
    ratio := ease.cubic_in(f.anim.ratio)
    ui.set_opacity(f, 1-ratio)
    f.offset = {40*ratio,0}

    if f.anim.ratio == 1 {
        tooltips.tooltip.data_container_slot = {}
        ui.clear_anchors(f)
        ui.hide(f)
    }
}

setup_tooltip_for_container_slot :: proc (slot: ^data.Container_Slot) {
    assert(slot.item != nil)

    tt := &tooltips.tooltip
    tt.data_container_slot = slot^
    ui.set_user_ptr(tt.root, &tt.data_container_slot)

    ui.hide_children(tt.root)

    item_cat, item_sub_cat := data.get_item_category(slot.item)
    ui.set_text(tt.title, item_cat, item_sub_cat, slot.item.name, shown=true)

    ui.show(tt.image)

    if slot.item.durability > 0 do ui.show(tt.durability)

    liquid_type := slot.item.liquid_container.type
    if liquid_type == .water || liquid_type == .blood do ui.show(tt.liquid)

    item_desc := data.text_to_string(slot.item.desc, context.temp_allocator)
    if item_desc != "" do ui.set_text(tt.desc, item_desc, shown=true)
}
