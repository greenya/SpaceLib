package hi

import "core:strings"
import "core:strconv"

Text_Token :: struct {
    type: Text_Token_Type,
    text: string,       // Text of the `.word` or `.whitespace`, or the name of a `.custom` command (e.g., "color" for "|color=primary|")
    args: string,       // `.custom` command arguments (e.g., "primary" for "|color=primary|")
    size: Vec2,         // Occupied size received from `Context.on_text_measure()` and `Context.on_text_custom_command()`
    solved_pos: Vec2,   // Calculated by the wrapping algorithm
}

Text_Token_Type :: enum u8 {
    // Content

    word,       // Continuous block of letters/numbers/punctuations between other tokens
    whitespace, // Continuous block of spaces `" "` or tabs `"\t"`
    br,         // Newline `"\n"` or Line break command `|br|`

    // Commands

    left,       // `|left|` Align to the left
    right,      // `|right|` Align to the right
    center,     // `|center|` Align to the center
    wrap,       // `|wrap|` Enable wrapping mode
    nowrap,     // `|nowrap|` Disable wrapping mode
    tab,        // `|tab=XXX|` Tab stop. Moves cursor X position to XXX if it is lower than XXX.
    custom,     // Custom/unknown command, e.g., `|icon=sword|` or `|item=#1234|`. Values are stored in `Text_Token.text` and `Text_Token.args`, and should be processed in `Context.on_text_custom_command()`.

    // Internal (these tokens are here only for documentation purposes and are never added to the result stream of tokens)

    raw_start,  // `|-raw-|` Raw mode start. In raw mode, tags are not parsed and are treated as text (expecting only `.word`, `.whitespace`, and `.br` tokens). The only tag parsed is the end of raw mode. Note: the tokenizer never adds this token type to the result stream.
    raw_end,    // `|-/raw-|` Raw mode end. Note: the tokenizer never adds this token type to the result stream.
}

Text_Style :: struct {
    font        : string,
    font_scale  : f32, // Font height scale of the `font`
    color       : Color,
    align       : Text_Alignment,
    wrapping    : bool,
    user_ptr    : rawptr,
    user_idx    : int,
}

Text_Style_Default :: Text_Style {
    font_scale  = 1.0,
    color       = {255,255,255,255},
    wrapping    = true,
}

Text_Alignment :: enum u8 { left, right, center }

// Tokenizes given text.
// Appends to the `pool` and returns slice of just appended tokens.
_text_tokenize :: proc (pool: ^[dynamic] Text_Token, text: string, is_literal: bool) -> [] Text_Token #no_bounds_check {
    pool_len_start := len(pool)
    text_len := len(text)
    raw_mode := is_literal

    for i := 0; i < text_len; /**/ {
        r := text[i]

        raw_end_tag :: "|-/raw-|"
        if raw_mode && !is_literal && r == '|' && i + len(raw_end_tag) <= text_len {
            if text[i:i+len(raw_end_tag)] == raw_end_tag {
                i += len(raw_end_tag)
                raw_mode = false
                continue
            }
        }

        switch r {
        case ' ', '\t':
            j := i
            for j < text_len && (text[j]==' ' || text[j]=='\t') do j += 1
            append(pool, Text_Token { type=.whitespace, text=text[i:j] })
            i = j

        case '\n':
            append(pool, Text_Token { type=.br, text="\n" })
            i += 1

        case '|':
            if raw_mode {
                append(pool, Text_Token { type=.word, text=text[i:i+1] })
                i += 1
                continue
            }

            j := i + 1
            for j < text_len && text[j]!='|' && text[j]!='\n' do j += 1

            if j < text_len && text[j]=='|' {
                tag_text := text[i+1:j]
                cmd, args := _text_parse_tag_text(tag_text)
                switch cmd {
                case ""         : append(pool, Text_Token { type=.word, text=text[i:i+1] }) // double pipe ("||")

                case "br"       : append(pool, Text_Token { type=.br, text="\n" })

                case "left"     : append(pool, Text_Token { type=.left })
                case "right"    : append(pool, Text_Token { type=.right })
                case "center"   : append(pool, Text_Token { type=.center })

                case "wrap"     : append(pool, Text_Token { type=.wrap })
                case "nowrap"   : append(pool, Text_Token { type=.nowrap })

                case "tab"      : v, _ := strconv.parse_f32(args)
                                  append(pool, Text_Token { type=.tab, size={v,0} })

                case "-raw-"    : raw_mode = true

                case            : append(pool, Text_Token { type=.custom, text=cmd, args=args })
                }
                i = j + 1 // Move cursor after closing '|'
            } else {
                // No closing '|' found; treat '|' as .word and continue
                append(pool, Text_Token { type=.word, text=text[i:i+1] })
                i += 1
            }

        case:
            j := i
            for j < text_len {
                c := text[j]
                if c==' ' || c=='\t' || c=='\n' || c=='|' do break
                j += 1
            }
            append(pool, Text_Token { type=.word, text=text[i:j] })
            i = j
        }
    }

    return pool[pool_len_start:]
}

// Measures given tokens.
// Updates each `Text_Token.size`.
_text_measure_tokens :: proc (ctx: ^Context, tokens: [] Text_Token) #no_bounds_check {
    has_on_text_measure := ctx.on_text_measure != nil
    has_on_text_custom_command := ctx.on_text_custom_command != nil

    style := Text_Style_Default
    if ctx.on_text_style != nil do ctx->on_text_style(&style)

    for &tok in tokens do #partial switch tok.type {
    case .word, .whitespace:
        if has_on_text_measure {
            tok.size = ctx->on_text_measure(style, tok.type, tok.text)
        }
    case .br:
        tok.size.y = style.font_scale * ctx.ref_font_height
    case .custom:
        if has_on_text_custom_command {
            tok.size = ctx->on_text_custom_command(&style, tok.text, tok.args)
        }
    }
}

// Wraps and aligns given tokens.
// - Updates each `Text_Token.solved_pos`.
// - Automatic wrapping is applied if `limit_x > 0`.
// - Returns total `extent` fitting all the tokens; expect `extent.x >= limit_x`.
//
// Note: Currently mutates `.tab` token `size.x` from tab stop into solved tab advance.
// This works for now as we always re-measure before wrapping; cached re-wrap would need separate storage, e.g. Text_Token.solved_width.
_text_wrap_tokens :: proc (ctx: ^Context, tokens: [] Text_Token, limit_x: f32) -> (extent: Vec2) #no_bounds_check {
    cursor_x: f32
    cursor_y: f32
    line_height: f32
    line_start_i: int

    style := Text_Style_Default
    if ctx.on_text_style != nil do ctx->on_text_style(&style)

    extent.x = limit_x

    for &tok, i in tokens {
        #partial switch tok.type {
        case .left      : style.align = .left       ; continue
        case .right     : style.align = .right      ; continue
        case .center    : style.align = .center     ; continue
        case .wrap      : style.wrapping = true     ; continue
        case .nowrap    : style.wrapping = false    ; continue

        case .tab:
            next_x := max(cursor_x, tok.size.x)
            tok.solved_pos = { cursor_x, cursor_y }
            tok.size.x = next_x - cursor_x
            cursor_x = next_x
            continue

        case .custom:
            ctx->on_text_custom_command(&style, tok.text, tok.args)
        }

        line_height = max(line_height, tok.size.y)
        overflow := style.wrapping && limit_x > 0 && cursor_x > 0 && (cursor_x + tok.size.x > limit_x)

        if overflow || tok.type == .br {
            extent.x = max(extent.x, _text_apply_line_alignment(tokens[line_start_i:i], limit_x, style.align))

            cursor_x = 0
            cursor_y += line_height == 0 ? tok.size.y : line_height
            line_height = 0
            line_start_i = tok.type == .br ? i + 1 : i

            if overflow && tok.type == .whitespace do continue
            if tok.type == .br do continue
        }

        tok.solved_pos = { cursor_x, cursor_y }
        cursor_x += tok.size.x
    }

    // align very last line and set the total height
    extent.x = max(extent.x, _text_apply_line_alignment(tokens[line_start_i:], limit_x, style.align))
    extent.y = cursor_y + line_height
    return
}

_text_apply_line_alignment :: proc (line_tokens: [] Text_Token, limit_x: f32, align: Text_Alignment) -> (extent_x: f32) #no_bounds_check {
    if len(line_tokens) == 0 do return

    start_i: int
    end_i := len(line_tokens) - 1

    for start_i <= end_i {
        tok := &line_tokens[start_i]
        if _tok_is_non_printable(tok) do start_i += 1
        else                          do break
    }

    for end_i >= start_i {
        tok := &line_tokens[end_i]
        if _tok_is_non_printable(tok) do end_i -= 1
        else                          do break
    }

    if start_i > end_i {
        // the line has no printable tokens -- reset all positions
        for &tok in line_tokens do tok.solved_pos = {}
        return
    }

    printable_line_width: f32
    for i in start_i..=end_i {
        printable_line_width += line_tokens[i].size.x
    }

    shift_amount: f32
    if limit_x > 0 {
        switch align {
        case .left  : /**/
        case .right : shift_amount =  limit_x - printable_line_width
        case .center: shift_amount = (limit_x - printable_line_width) / 2
        }

        if shift_amount < 0 do shift_amount = 0
    }

    // shift printable tokens and reset positions of all leading and trailing non-printable ones
    for &tok, i in line_tokens {
        if i >= start_i && i <= end_i do tok.solved_pos.x += shift_amount
        else                          do tok.solved_pos = {}
    }

    return line_tokens[end_i].solved_pos.x + line_tokens[end_i].size.x

    _tok_is_non_printable :: proc (tok: ^Text_Token) -> bool {
        return tok.type == .whitespace || tok.size.x == 0
    }
}

_text_parse_tag_text :: proc (tag_text: string) -> (cmd, args: string) #no_bounds_check {
    i := strings.index_byte(tag_text, '=')
    if i >= 0   do return tag_text[0:i], tag_text[i+1:]
    else        do return tag_text, ""
}

Text_Token_Iterator :: struct {
    tokens  : [] Text_Token,
    style   : Text_Style,
    ctx     : ^Context,
    filter  : bit_set [Text_Token_Type],
    next_i  : int,
}

// The `filter` affects only returned tokens; the `.custom` tokens always get processed for `Text_Token_Iterator.style` changes.
@require_results
text_token_iterate :: proc (
    ctx     : ^Context,
    tokens  : [] Text_Token,
    filter  := bit_set [Text_Token_Type] { .word, .custom },
) -> (it: Text_Token_Iterator) {
    assert(filter != {})

    it = {
        tokens  = tokens,
        style   = Text_Style_Default,
        ctx     = ctx,
        filter  = filter,
    }

    if ctx.on_text_style != nil do ctx->on_text_style(&it.style)

    return
}

@require_results
text_token_next :: proc (it: ^Text_Token_Iterator) -> (tok: ^Text_Token, ok: bool) #no_bounds_check {
    for i := it.next_i; i < len(it.tokens); i += 1 {
        tok = &it.tokens[i]
        if tok.type == .custom && it.ctx.on_text_custom_command != nil {
            it.ctx->on_text_custom_command(&it.style, tok.text, tok.args)
        }
        if tok.type in it.filter {
            it.next_i = i + 1
            ok = true
            return
        }
    }
    return
}
