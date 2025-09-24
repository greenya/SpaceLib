package demo10

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:terse"
import "spacelib:ui"

Rect    :: core.Rect
Color   :: core.Color

draw_terse :: proc (t: ^terse.Terse, opacity := f32(1), color: Color = {}, offset := [2] f32 {}, scissor: Rect = {}) {
    for w in t.words {
        rect := offset != {} ? core.rect_moved(w.rect, offset) : w.rect
        if scissor != {} && !core.rects_intersect(rect, scissor) do continue

        tint := color.a > 0 ? color : w.color
        tint = core.alpha(tint, opacity)

        draw.text(w.text, {rect.x,rect.y}, w.font, tint)
    }
}

draw_after_tab_content :: proc (f: ^ui.Frame) {
    draw.rect(core.rect_bar_top(f.rect, 2), color_hl)
}

draw_tab_button :: proc (f: ^ui.Frame) {
    if f.selected do draw.rect(core.rect_bar_bottom(f.rect, 8), color_hl)
    draw_terse(f.terse, color=f.selected?color_hl:{})
    if f.entered do draw.rect_lines(f.rect, 2, color_hl)
}

draw_button :: proc (f: ^ui.Frame) {
    draw.rect_lines(f.rect, 2, color_panel)
    if f.selected do draw.rect(f.rect, color_panel)
    draw_terse(f.terse)
    if f.entered do draw.rect_lines(f.rect, 2, color_hl)
}

draw_scrollbar_track :: proc (f: ^ui.Frame) {
    if .disabled in f.children[0].flags do return
    draw.rect(f.rect, core.alpha(color_text, .2*f.opacity))
}

draw_scrollbar_thumb :: proc (f: ^ui.Frame) {
    if .disabled in f.flags do return
    draw.diamond(f.rect, f.entered||f.captured?color_hl:color_text)
}

draw_grid_bit :: proc (f: ^ui.Frame) {
    if f.selected do draw.rect(f.rect, color_panel)
    draw_terse(f.terse)
    if f.entered do draw.rect_lines(f.rect, 2, color_hl)
}

draw_leaderboard_bg :: proc (f: ^ui.Frame) {
    draw.rect_lines(f.rect, 2, color_panel)
}
