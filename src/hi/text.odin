package hi

import "core:strings"
import "core:strconv"

Text_Token :: struct {
    type: Text_Token_Type,
    text: string,       // Text or command name
    args: string,       // Command args, e.g. "primary" for "[color=primary]"
    size: Vec2,         // Occupied size, expected to be set by `Context.on_text_token` for anything that takes space (text, whitespace, icon)
    solved_pos: Vec2,   // Calculated by the wrapping algorithm
}

Text_Token_Type :: enum u8 {
    word,           // Continuous block of letters/numbers/punctuations
    whitespace,     // Spaces, tabs, new line characters
    line_break,     // Force line break. Normal `\n` doesn't break the line, and treated as whitespace
    tab_stop,       // Force horizontal gap. Jumps to an absolute X position on the current line.
    nowrap,
    align_left,
    align_right,
    align_center,
    command,        // Custom command, e.g. "[icon=sword]" or "[item=#1234]"
}

Text_Style :: struct {
    font    : string,
    color   : Color,
    align   : Text_Alignment,
}

Text_Alignment :: enum u8 { left, center, right }

_text_tokenize :: proc (ctx: ^Context, text: string) -> [] Text_Token #no_bounds_check {
    att_len := len(ctx.active_text_tokens)
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
                case "br":
                    append(&ctx.active_text_tokens, Text_Token { type=.line_break })
                case "tab":
                    v, _ := strconv.parse_f32(args)
                    append(&ctx.active_text_tokens, Text_Token { type=.tab_stop, size={v,0} })
                case "nowrap":
                    append(&ctx.active_text_tokens, Text_Token { type=.nowrap })
                case "left":
                    append(&ctx.active_text_tokens, Text_Token { type=.align_left })
                case "right":
                    append(&ctx.active_text_tokens, Text_Token { type=.align_right })
                case "center":
                    append(&ctx.active_text_tokens, Text_Token { type=.align_center })
                case:
                    append(&ctx.active_text_tokens, Text_Token { type=.command, text=cmd, args=args })
                }
            }

        case:
            j := i
            for j < text_len {
                c := text[j]
                if c==' ' || c=='\t' || c=='\n' || c=='[' do break
                j += 1
            }
            append(&ctx.active_text_tokens, Text_Token { type=.word, text=text[i:j] })
            i = j
        }
    }

    assert(len(ctx.active_text_tokens) != cap(ctx.active_text_tokens), "Most likely Context.active_text_tokens overflow")
    return ctx.active_text_tokens[att_len:]
}

_text_measure_tokens :: proc (ctx: ^Context, tokens: [] Text_Token) #no_bounds_check {
    has_on_text_token := ctx.on_text_token != nil
    style := Text_Style { align=.left, color={255,0,0,255} }
    for &tok in tokens do switch tok.type {
    case .word, .whitespace, .command:
        if has_on_text_token do ctx->on_text_token(&tok, &style)
    case .line_break, .tab_stop, .nowrap, .align_left, .align_right, .align_center:
        /**/ // control tokens, has no size (or it is dynamic)
    }
}

_text_wrap_tokens :: proc (ctx: ^Context, tokens: [] Text_Token, max_width: f32) #no_bounds_check {
    cursor_x        := f32(0)
    cursor_y        := f32(0)
    line_height     := f32(16) // ? Default line height
    line_start_i    := 0
    line_align      := Text_Alignment.left
    is_wrapping     := true

    for &tok, i in tokens {
        #partial switch tok.type {
        case .align_left    : line_align = .left; continue
        case .align_right   : line_align = .right; continue
        case .align_center  : line_align = .center; continue
        case .nowrap        : is_wrapping = false; continue
        case .tab_stop      : cursor_x = max(cursor_x, tok.size.x); continue
        }

        line_height = max(line_height, tok.size.y)
        is_overflow := is_wrapping && (cursor_x + tok.size.x > max_width)

        if tok.type == .line_break || is_overflow {
            if line_align != .left {
                _text_apply_line_alignment(tokens[line_start_i:i], max_width, cursor_x, line_align)
            }

            cursor_x = 0
            cursor_y += line_height
            line_height = 16 // ? Default line height
            line_start_i = i

            if is_overflow && tok.type == .whitespace do continue
        }

        tok.solved_pos = { cursor_x, cursor_y }
        cursor_x += tok.size.x
    }

    // align very last line
    if line_align != .left {
        _text_apply_line_alignment(tokens[line_start_i:], max_width, cursor_x, line_align)
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
