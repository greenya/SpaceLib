package hi

Text_Token :: struct {
    kind: Text_Token_Kind,
    str_: string,
    f32_: f32,
}

Text_Token_Kind :: enum u8 {
    word,       // Continuous block of letters/numbers
    whitespace, // Spaces and tabs
    line_break, // Forced new line
    tab_stop,   // Forced horizontal gap. Jumps to an absolute X position on the current line.
    icon,       // Inline icon
}

Text_State :: struct {
    font        : string,
    color       : Color,
    align       : Text_Alignment,
    line_height : f32,
}

Text_Alignment :: enum u8 { left, center, right }

Text_Measure_Proc :: proc (ctx: ^Context, text, font: string)
Text_Command_Proc :: proc (ctx: ^Context, command, args: string, state: ^Text_State)
