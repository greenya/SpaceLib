package hi

import "core:strings"
import "core:strconv"

// TODO: support multiple commands in a tag, and change `[` and `]` into rarely used `|`, example: |wrap,left|This is |c=#f0f,f=big|Big Pink Text!
// TODO: support stack of fonts and colors with simple [dynamic; N] T, so next is possible: |c=#fff|He|c=#ff0|ll|/c|o, World!

Text_Token :: struct {
    type: Text_Token_Type,
    text: string,       // Text or command name
    args: string,       // Command args, e.g. "primary" for "[color=primary]"
    size: Vec2,         // Occupied size, the value received from the `Context.on_measure_text()` and `Context.on_text_custom_command()`
    solved_pos: Vec2,   // Calculated by the wrapping algorithm
}

Text_Token_Type :: enum u8 {
    word,       // Continuous block of letters/numbers/punctuations between `.whitespace` tokens
    whitespace, // Spaces, tabs, new lines
    br,         // Line break. Normal `\n` doesn't break the line, and treated as `.whitespace`.
    tab,        // Tab stop
    wrap,       // Enable wrapping mode
    nowrap,     // Disable wrapping mode
    left,       // Align to the left
    right,      // Align to the right
    center,     // Align to the center
    custom,     // Custom/unknown command, e.g. "[icon=sword]" or "[item=#1234]"
}

Text_Style :: struct {
    font        : string,
    color       : Color,
    align       : Text_Alignment,
    wrapping    : bool,
    user_ptr    : rawptr,
    user_idx    : int,
}

Text_Style_Default := Text_Style { color={255,255,255,255}, wrapping=true }

Text_Alignment :: enum u8 { left, right, center }

_text_tokenize :: proc (ctx: ^Context, text: string) -> [] Text_Token #no_bounds_check {
    pool := &ctx.active_text_tokens
    pool_len := len(pool)
    text_len := len(text)

    for i := 0; i < text_len; /**/ {
        r := text[i]
        switch r {
        case ' ', '\t', '\n':
            j := i
            for j < text_len && (text[j]==' ' || text[j]=='\t' || text[j]=='\n') do j += 1
            append(&ctx.active_text_tokens, Text_Token { type=.whitespace, text=text[i:j] })
            i = j

        case '[':
            j := i + 1
            for j < text_len && text[j]!=']' do j += 1
            if j < text_len && text[j]==']' {
                tag_text := text[i+1:j] // Extract text between '[' and ']'
                i = j + 1 // Move cursor after ']'
                cmd, args := _text_parse_tag_text(tag_text)
                switch cmd {
                case "br"       : append(pool, Text_Token { type=.br })
                case "tab"      : v, _ := strconv.parse_f32(args)
                                  append(pool, Text_Token { type=.tab, size={v,0} })
                case "wrap"     : append(pool, Text_Token { type=.wrap })
                case "nowrap"   : append(pool, Text_Token { type=.nowrap })
                case "left"     : append(pool, Text_Token { type=.left })
                case "right"    : append(pool, Text_Token { type=.right })
                case "center"   : append(pool, Text_Token { type=.center })
                case            : append(pool, Text_Token { type=.custom, text=cmd, args=args })
                }
            }

        case:
            j := i
            for j < text_len {
                c := text[j]
                if c==' ' || c=='\t' || c=='\n' || c=='[' do break
                j += 1
            }
            append(pool, Text_Token { type=.word, text=text[i:j] })
            i = j
        }
    }

    assert(len(pool) != cap(pool), "Most likely Context.active_text_tokens overflow")
    return pool[pool_len:]
}

_text_measure_tokens :: proc (ctx: ^Context, tokens: [] Text_Token) #no_bounds_check {
    has_on_measure_text := ctx.on_measure_text != nil
    has_on_text_custom_command := ctx.on_text_custom_command != nil

    style := Text_Style_Default
    if ctx.on_text_style != nil do ctx->on_text_style(&style)

    for &tok in tokens do #partial switch tok.type {
    case .word, .whitespace:
        if has_on_measure_text {
            tok.size = ctx->on_measure_text(&style, tok.text, tok.type==.whitespace)
        }
    case .custom:
        if has_on_text_custom_command {
            tok.size = ctx->on_text_custom_command(&style, tok.text, tok.args)
        }
    }
}

_text_wrap_tokens :: proc (ctx: ^Context, tokens: [] Text_Token, max_width: f32) #no_bounds_check {
    style := Text_Style_Default
    if ctx.on_text_style != nil do ctx->on_text_style(&style)

    cursor_x        := f32(0)
    cursor_y        := f32(0)
    line_height     := f32(0)
    line_start_i    := 0
    align           := style.align
    wrapping        := style.wrapping

    for &tok, i in tokens {
        #partial switch tok.type {
        case .left      : align = .left     ; continue
        case .right     : align = .right    ; continue
        case .center    : align = .center   ; continue
        case .wrap      : wrapping = true   ; continue
        case .nowrap    : wrapping = false  ; continue
        case .tab       : cursor_x = max(cursor_x, tok.size.x); continue
        }

        line_height = max(line_height, tok.size.y)
        overflow := wrapping && (cursor_x + tok.size.x > max_width)

        if tok.type == .br || overflow {
            if align != .left {
                _text_apply_line_alignment(tokens[line_start_i:i], max_width, cursor_x, align)
            }

            cursor_x = 0
            cursor_y += line_height
            line_height = 0
            line_start_i = i

            if overflow && tok.type == .whitespace do continue
        }

        tok.solved_pos = { cursor_x, cursor_y }
        cursor_x += tok.size.x
    }

    // align very last line
    if align != .left {
        _text_apply_line_alignment(tokens[line_start_i:], max_width, cursor_x, align)
    }
}

_text_apply_line_alignment :: proc(line_tokens: [] Text_Token, max_width, line_width: f32, align: Text_Alignment) #no_bounds_check {
    assert(align != .left)

    rem_space := max_width - line_width
    if rem_space <= 0 do return

    shift_amount := align == .center\
        ? rem_space / 2\
        : rem_space

    for &tok in line_tokens do tok.solved_pos.x += shift_amount
}

_text_parse_tag_text :: proc (tag_text: string) -> (cmd, args: string) #no_bounds_check {
    i := strings.index_byte(tag_text, '=')
    if i >= 0   do return tag_text[0:i], tag_text[i+1:]
    else        do return tag_text, ""
}
