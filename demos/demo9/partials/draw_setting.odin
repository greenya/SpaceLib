package partials

import "spacelib:core"
import "spacelib:raylib/draw"
import "spacelib:ui"

import "../colors"

draw_setting_card :: proc (f: ^ui.Frame) {
    hv_ratio := ui.hover_ratio(f, .Cubic_Out, .333, .Cubic_In, .333)

    bg_color := core.ease_color(colors.bg2, colors.accent, hv_ratio)
    bg_color = core.alpha(core.brightness(bg_color, -.8), f.opacity*.3 + hv_ratio*.2)
    draw.rect(f.rect, bg_color)

    ln_color := core.ease_color(colors.primary, colors.accent, hv_ratio)
    ln_color = core.alpha(ln_color, f.opacity * .5)
    draw.rect_lines(f.rect, 1, ln_color)
}
