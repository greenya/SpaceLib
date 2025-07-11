package demo9_interface

import "core:fmt"

import "spacelib:core"
import "spacelib:ui"

import "../events"
import "partials"

@private dropdown_layer : ^ui.Frame
@private dropdown_data  : map [^ui.Frame] struct { names, titles: [] string }

@private
add_dropdown_layer :: proc () {
    assert(dropdown_layer == nil)

    dropdown_layer = ui.add_frame(ui_.root, {
        name    = "dropdown_layer",
        flags   = {.hidden,.block_wheel},
        order   = 4,
        click   = proc (f: ^ui.Frame) {
            dropdown := ui.get(f, "dropdown")
            if ui.animating(dropdown) do return
            target := dropdown.anchors[0].rel_frame
            ui.click(target)
        },
    }, { point=.top_left }, { point=.bottom_right })

    ui.add_frame(dropdown_layer, {
        name    = "dropdown",
        layout  = {dir=.down,auto_size=.dir},
        draw    = partials.draw_button_dropdown_rect,
    })

    events.listen("set_dropdown_data", set_dropdown_data_listener)
    events.listen("open_dropdown", open_dropdown_listener)
    events.listen("close_dropdown", close_dropdown_listener)
}

@private
set_dropdown_data_listener :: proc (args: events.Args) {
    target, names, titles := args.frame1[0], args.s1, args.s2
    // fmt.printfln("set dropdown data: target=%s, names=%v, titles=%v", target.name, names, titles)

    assert(len(names) > 0)
    assert(len(titles) > 0)
    assert(len(names) == len(titles))
    assert(ui.find(target, "title") != nil, "Target must have \"title\" frame")

    dropdown_data[target] = { names=names, titles=titles }
}

@private
open_dropdown_listener :: proc (args: events.Args) {
    target := args.frame1[0]
    assert(target != nil)
    assert(target in dropdown_data)

    names, titles := dropdown_data[target].names, dropdown_data[target].titles
    // fmt.printfln("open dropdown: target=%s, names=%v, titles=%v", target.name, names, titles)

    dropdown := ui.get(dropdown_layer, "dropdown")

    // add items if needed
    for i:=len(dropdown.children); i<len(names); i+=1 {
        ui.add_frame(dropdown, {
            text_format = "<pad=15:0,left,font=text_4l,color=primary_d2>%s",
            flags       = {.terse,.terse_height},
            draw        = partials.draw_button_dropdown_item,
            click       = proc (f: ^ui.Frame) {
                dropdown := ui.get(f, "..")
                target := dropdown.anchors[0].rel_frame
                title := ui.get(target, "title")
                ui.set_text(title, dropdown_data[target].titles[ui.index(f)])
                ui.click(target)
            },
        })
    }

    // setup items
    for child, i in dropdown.children {
        if i < len(names) {
            child.name = names[i]
            ui.set_text(child, titles[i], shown=true)
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

    ui.update(dropdown_layer, repeat=2)
    if debug do fmt.println("[1] rect", dropdown.rect)

    can_fit_down := target.rect.y+target.rect.h+dropdown.rect.h < ui_.root.rect.y+ui_.root.rect.h
    if !can_fit_down {
        if debug do fmt.println("reposition to the top")
        ui.set_anchors(dropdown,
            { point=.bottom_left, rel_point=.top_left, rel_frame=target },
            { point=.bottom_right, rel_point=.top_right, rel_frame=target },
        )
        ui.update(dropdown_layer)
        if debug do fmt.println("[2] rect", dropdown.rect)

        // scroll bar experiments {{{
        // offscreen_top_amount := -dropdown.rect.y
        // if offscreen_top_amount > 0 {
        //     dropdown.size.y = dropdown.rect.h - offscreen_top_amount
        //     dropdown.layout.auto_size = .none
        //     dropdown.layout.scroll.step = 10
        //     dropdown.flags += { .scissor }
        //     ui.update(dropdown_layer)
        // }
        // }}}

        // for now just offset dropdown down, ugly and easy

        offscreen_top_amount := -dropdown.rect.y
        if offscreen_top_amount > 0 {
            if debug do fmt.println("offscreen_top_amount", offscreen_top_amount)
            dropdown.anchors[0].offset.y += offscreen_top_amount
            dropdown.anchors[1].offset.y += offscreen_top_amount
            ui.update(dropdown_layer)
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
        ui.update(dropdown_layer)
        if debug do fmt.println("[4] rect", dropdown.rect)
    }

    ui.animate(dropdown, anim_dropdown_appear, .222)
}

@private
close_dropdown_listener :: proc (args: events.Args) {
    target := args.frame1[0]
    // fmt.printfln("close dropdown: target=%s", target != nil ? target.name : "<not set>")

    current_target := ui.get(dropdown_layer, "dropdown").anchors[0].rel_frame
    assert(current_target != nil)
    if target != nil && current_target != target {
        fmt.panicf("Dropdown target mismatch: current target=%s, requested target=%s", current_target.name, target.name)
    }

    dropdown := ui.get(dropdown_layer, "dropdown")
    ui.animate(dropdown, anim_dropdown_disappear, .222)
}

@private
anim_dropdown_appear :: proc (f: ^ui.Frame) {
    if f.anim.ratio == 0 {
        ui.show(dropdown_layer)
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

@private
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
        ui.hide(dropdown_layer)
    }
}
