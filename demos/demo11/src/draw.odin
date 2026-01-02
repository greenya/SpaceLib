package main

import "core:strings"
import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:terse"
import "spacelib:ui"
import "res"

draw_terse :: proc (terse_: ^terse.Terse, offset := Vec2{}, color := Color{}, opacity := f32(1), scissor := Rect{}) {
    for &line in terse_.lines {
        if scissor != {} && !core.rects_intersect(line.rect, scissor) do continue

        for word in line.words {
            rect := offset != {} ? core.rect_moved(word.rect, offset) : word.rect
            if scissor != {} && !core.rects_intersect(rect, scissor) do continue

            tint := color.a > 0 ? color : word.color
            tint = core.alpha(tint, opacity)

            draw.text(word.text, {rect.x,rect.y}, 0, word.font, tint)
        }
    }
}

draw_terse_frame :: proc (f: ^ui.Frame, offset := Vec2{}, color := Color{}) {
    assert(f.terse != nil)
    draw_terse(f.terse, offset, color, f.opacity, f.ui.scissor_rect)

    hit_group := terse.group_hit(f.terse, f.ui.mouse.pos)

    for &g in f.terse.groups {
        if !strings.has_prefix(g.name, "link_") do continue
        link_rects := terse.group_rects(g, context.temp_allocator)
        link_color := &g == hit_group ? res.color(.amber) : res.color(.amber, a=.4)
        for r in link_rects {
            draw.rect(core.rect_bar_bottom(r, 2), link_color)
        }
    }
}

draw_panel :: proc (f: ^ui.Frame) {
    draw.rect_gradient_horizontal(f.rect, res.color(.teal), res.color(.teal, a=0))
    left_bar := core.rect_bar_left(f.rect, 3)
    draw.rect(left_bar, res.color(.turquoise))
}

draw_button :: proc (f: ^ui.Frame) {
    bg_rect := core.rect_inflated(f.rect, f.captured ? {1,1} : {-1,1})
    draw.rect_rounded(bg_rect, .5, 8, res.color(.teal, b=-.3))

    face_offset := Vec2 {0,-5}

    if .disabled in f.flags {
        face_rect := core.rect_moved(f.rect, face_offset)
        face_color := res.color(.teal, b=-.2)
        draw.rect_rounded(face_rect, .3, 8, face_color)

        face_br_color := res.color(.turquoise, b=-.2)
        draw.rect_rounded_lines(face_rect, .3, 8, 2, face_br_color)

        if f.terse != nil {
            draw_terse_frame(f, offset=face_offset, color=res.color(.cyan))
        }
    } else {
        if f.entered {
            draw.rect_rounded_lines(core.rect_inflated(f.rect, 3), .3, 8, 4, res.color(.amber))
        }

        if f.captured {
            face_offset = {}
        }

        face_rect := core.rect_moved(f.rect, face_offset)
        face_color := res.color(f.selected ? .magenta : .teal)
        draw.rect_rounded(face_rect, .3, 8, face_color)

        face_br_color := res.color(.turquoise, b=-.2)
        draw.rect_rounded_lines(face_rect, .3, 8, 2, face_br_color)

        if f.terse != nil {
            draw_terse_frame(f, offset=face_offset)
        }
    }
}

draw_scrollbar_track :: proc (f: ^ui.Frame) {
    if .disabled in f.children[0].flags do return
    draw.rect(f.rect, res.color(.teal))
}

draw_scrollbar_thumb :: proc (f: ^ui.Frame) {
    if .disabled in f.flags do return
    draw.rect_rounded(f.rect, .4, 8, res.color(.teal))
    if f.entered || f.captured {
        draw.rect_rounded_lines(f.rect, .4, 8, 2, res.color(.turquoise))
    }
}

draw_github_user_avatar :: proc (f: ^ui.Frame) {
    assert(f.name != "")
    assert(f.name in github_page.user_avatars)
    texture := github_page.user_avatars[f.name].texture

    if texture.id != 0 {
        draw.texture_all(texture, f.rect)
    }

    br_color := f.entered ? res.color(.amber) : res.color(.turquoise)
    draw.rect_lines(f.rect, 2, br_color)
}

draw_animation_panel :: proc (f: ^ui.Frame) {
    count       :: 40
    speed       :: 40
    color_from  := res.color(.teal)
    color_to    := res.color(.amber)
    center      := core.rect_center(f.rect)
    dt          := app.ui.clock.time
    for i in 0..<count {
        orbit_radius := f32(count-i)*1.456 + f32(count)/2.345
        draw.circle(
            center  = core.vec_orbited_around_vec(center+{0,orbit_radius}, center, speed, dt),
            radius  = f32(i/2) + 5,
            color   = core.ease_color(color_from, color_to, f32(i)/count),
        )
    }
}
