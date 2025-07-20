#+private
package interface

import "core:fmt"

import "spacelib:core"
import "spacelib:ui"

import "../events"
import "../partials"

dropdowns: struct {
    layer       : ^ui.Frame,
    dropdown    : ^ui.Frame,
    data        : map [^ui.Frame] events.Set_Dropdown_Data,
    target      : ^ui.Frame,
}

add_dropdowns_layer :: proc (order: int) {
    assert(dropdowns.layer == nil)

    dropdowns.layer = ui.add_frame(ui_.root, {
        name    = "dropdowns_layer",
        flags   = {.hidden,.block_wheel},
        order   = order,
        click   = proc (f: ^ui.Frame) {
            if !ui.animating(dropdowns.dropdown) {
                ui.click(dropdowns.target)
            }
        },
    }, { point=.top_left }, { point=.bottom_right })

    dropdowns.dropdown = ui.add_frame(dropdowns.layer, {
        name    = "dropdown",
        layout  = ui.Flow { dir=.down, auto_size=.dir },
        draw    = partials.draw_button_dropdown_rect,
    })

    events.listen(.set_dropdown_data, set_dropdown_data_listener)
    events.listen(.open_dropdown, open_dropdown_listener)
    events.listen(.close_dropdown, close_dropdown_listener)
}

set_dropdown_data_listener :: proc (args: events.Args) {
    data := args.(events.Set_Dropdown_Data)
    assert(data.target != nil)
    assert(data.selected != nil)
    assert(len(data.names) > 0)
    assert(len(data.titles) > 0)
    assert(len(data.names) == len(data.titles))
    dropdowns.data[data.target] = data
}

open_dropdown_listener :: proc (args: events.Args) {
    args := args.(events.Open_Dropdown)
    target := args.target
    assert(target != nil)
    assert(target in dropdowns.data)

    data := dropdowns.data[target]
    // fmt.printfln("open dropdown: target=%s, selected=%s, names=%v, titles=%v", target.name, selected.name, names, titles)

    dropdown := ui.get(dropdowns.layer, "dropdown")

    // add items if needed
    for i:=len(dropdown.children); i<len(data.names); i+=1 {
        ui.add_frame(dropdown, {
            text_format = "<pad=15:0,left,font=text_4l,color=primary_d2>%s",
            flags       = {.radio,.terse,.terse_height},
            draw        = partials.draw_button_dropdown_item,
            click       = proc (f: ^ui.Frame) {
                data    := dropdowns.data[dropdowns.target]
                f_idx   := ui.index(f)
                ui.set_name(data.selected, data.names[f_idx])
                ui.set_text(data.selected, data.titles[f_idx])
                ui.click(dropdowns.target)
            },
        })
    }

    // setup items
    for child, i in dropdown.children {
        if i < len(data.names) {
            ui.set_name(child, data.names[i])
            ui.set_text(child, data.titles[i], shown=true)
            child.selected = data.selected.name == data.names[i]
        } else {
            ui.hide(child)
        }
    }

    debug :: false
    if debug do fmt.println("---------------------------")

    // anchor dropdown to the bottom of the target
    ui.set_anchors(dropdown,
        { point=.top_left, rel_point=.bottom_left, rel_frame=target },
        { point=.top_right, rel_point=.bottom_right, rel_frame=target },
    )

    ui.update(dropdowns.layer, repeat=2)
    if debug do fmt.println("[1] rect", dropdown.rect)

    can_fit_down := target.rect.y+target.rect.h+dropdown.rect.h < ui_.root.rect.y+ui_.root.rect.h
    if !can_fit_down {
        if debug do fmt.println("reposition to the top")
        ui.set_anchors(dropdown,
            { point=.bottom_left, rel_point=.top_left, rel_frame=target },
            { point=.bottom_right, rel_point=.top_right, rel_frame=target },
        )
        ui.update(dropdowns.layer)
        if debug do fmt.println("[2] rect", dropdown.rect)

        // scroll bar experiments {{{
        // offscreen_top_amount := -dropdown.rect.y
        // if offscreen_top_amount > 0 {
        //     dropdown.size.y = dropdown.rect.h - offscreen_top_amount
        //     dropdown.layout.auto_size = .none
        //     dropdown.layout.scroll.step = 10
        //     dropdown.flags += { .scissor }
        //     ui.update(dropdowns_layer)
        // }
        // }}}

        // for now just offset dropdown down, ugly and easy

        offscreen_top_amount := -dropdown.rect.y
        if offscreen_top_amount > 0 {
            if debug do fmt.println("offscreen_top_amount", offscreen_top_amount)
            dropdown.anchors[0].offset.y += offscreen_top_amount
            dropdown.anchors[1].offset.y += offscreen_top_amount
            ui.update(dropdowns.layer)
            if debug do fmt.println("[3] rect", dropdown.rect)
        }
    }

    // tweak dropdown width if necessary
    // note: Settings -> Audio -> last 2 settings are good for testing this logic

    dropdown_w_desired := f32(0)
    for child in dropdown.children {
        if .hidden in child.flags do continue
        aox :: partials.draw_button_dropdown_item_anim_offset_x
        dropdown_w_desired = max(dropdown_w_desired, child.terse.rect.w+aox)
    }

    dropdown_w_extra := dropdown_w_desired-dropdown.rect.w
    if dropdown_w_extra > 0 {
        if debug do fmt.println("dropdown_w_extra", dropdown_w_extra)
        dropdown.anchors[1].offset.x = dropdown_w_extra
        ui.update(dropdowns.layer)
        if debug do fmt.println("[4] rect", dropdown.rect)
    }

    dropdowns.target = target
    ui.animate(dropdown, anim_dropdown_appear, .222)
}

close_dropdown_listener :: proc (args: events.Args) {
    args := args.(events.Close_Dropdown)
    assert(args.target != nil)
    assert(args.target == dropdowns.target)

    dropdowns.target = nil
    ui.animate(dropdowns.dropdown, anim_dropdown_disappear, .222)
}

anim_dropdown_appear :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 {
        ui.show(dropdowns.layer)
        f.flags += {.pass}
    }

    ui.set_opacity(f, f.anim.ratio)
    dir := f.anchors[0].point == .top_left ? f32(-1): f32(1)
    f.offset = { 0, dir * 40 * (1 - core.ease_ratio(f.anim.ratio, .Cubic_Out)) }

    if f.anim.ratio == 1 {
        f.flags -= {.pass}
        f.offset = 0
        ui.set_opacity(f, 1)
    }
}

anim_dropdown_disappear :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 {
        f.flags += {.pass}
    }

    ui.set_opacity(f, 1-f.anim.ratio)
    dir := f.anchors[0].point == .top_left ? f32(1): f32(-1)
    f.offset = { 0, dir * 40 * core.ease_ratio(f.anim.ratio, .Cubic_In) }

    if f.anim.ratio == 1 {
        f.flags -= {.pass}
        f.offset = 0
        ui.hide(dropdowns.layer)
    }
}
