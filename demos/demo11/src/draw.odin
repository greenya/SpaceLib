package main

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
}

draw_panel :: proc (f: ^ui.Frame) {
    draw.rect_gradient_horizontal(f.rect, res.color(.teal, a=f.opacity), res.color(.teal, a=0))
    left_bar := core.rect_bar_left(f.rect, 3)
    draw.rect(left_bar, res.color(.turquoise))
}

draw_button :: proc (f: ^ui.Frame) {
    bg_rect := core.rect_inflated(f.rect, f.captured ? {1,1} : {-1,1})
    draw.rect_rounded(bg_rect, .5, 8, res.color(.teal, a=f.opacity, b=-.3))

    if f.entered {
        draw.rect_rounded_lines(core.rect_inflated(f.rect, 3), .3, 8, 4, res.color(.amber, a=f.opacity))
    }

    offset: Vec2 = f.captured ? {0,0} : {0,-5}
    face_rect := core.rect_moved(f.rect, offset)
    face_color := res.color(f.selected ? .magenta : .teal, a=f.opacity)
    draw.rect_rounded(face_rect, .3, 8, face_color)

    draw.rect_rounded_lines(face_rect, .3, 8, 2, res.color(.turquoise, a=f.opacity))

    if .terse in f.flags {
        draw_terse_frame(f, offset=offset, color=res.color(.white))
    }
}
