package spacelib

import "core:fmt"
import rl "vendor:raylib"

Text :: struct {
    text    : string,
    font    : ^Font,
    color   : Color,
}

add_text :: proc (parent: ^Frame, font: ^Font = nil, text := "", color := WHITE, size := Vec2 {}) -> ^Frame {
    frame := add_frame(parent, size=size)
    frame.var = Text { font=font, color=color }
    set_text(frame, text)
    return frame
}

set_text :: proc (f: ^Frame, text: string) {
    var := &f.var.(Text)
    var.text = text
    f.size = rl.MeasureTextEx(
        var.font.obj,
        fmt.ctprint(text),
        var.font.size,
        var.font.spacing,
    )
}

draw_text :: proc (f: ^Frame) {
    rect := get_rect(f)
    var := &f.var.(Text)
    rl.DrawTextEx(
        var.font.obj,
        fmt.ctprint(var.text),
        { rect.x, rect.y },
        var.font.size,
        var.font.spacing,
        var.color,
    )
}
