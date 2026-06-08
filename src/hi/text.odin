package hi

import "core:strings"
import "core:strconv"

Text_Token :: struct {
    type: Text_Token_Type,
    text: string,       // Text of the `.word` or `.whitespace` or name of the `.custom` command, e.g. "color" for "|color=primary|"
    args: string,       // `.custom` command args, e.g. "primary" for "|color=primary|"
    size: Vec2,         // Occupied size, the value received from the `Context.on_text_measure()` and `Context.on_text_custom_command()`
    solved_pos: Vec2,   // Calculated by the wrapping algorithm
}

Text_Token_Type :: enum u8 {
    word,       // Continuous block of letters/numbers/punctuations between other tokens
    whitespace, // Continuous block of spaces `" "` or tabs `"\t"`
    br,         // New line `"\n"` or Line break `|br|`
    tab,        // `|tab=XXX|` Tab stop. Moves cursor X position to XXX if it is lower than XXX.
    wrap,       // `|wrap|` Enable wrapping mode
    nowrap,     // `|nowrap|` Disable wrapping mode
    left,       // `|left|` Align to the left
    right,      // `|right|` Align to the right
    center,     // `|center|` Align to the center
    custom,     // Custom/unknown command, e.g. `|icon=sword|` or `|item=#1234|`. Values stored in `Text_Token.text/args` and should be processed in `Context.on_text_custom_command()`.
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

// Tokenizes given text. Appends to `ctx.visible_text_tokens`.
// Returns slice of appended tokens.
_text_tokenize :: proc (ctx: ^Context, text: string) -> [] Text_Token #no_bounds_check {
    pool := &ctx.visible_text_tokens
    pool_len := len(pool)
    text_len := len(text)

    for i := 0; i < text_len; /**/ {
        r := text[i]
        switch r {
        case ' ', '\t':
            j := i
            for j < text_len && (text[j]==' ' || text[j]=='\t') do j += 1
            append(&ctx.visible_text_tokens, Text_Token { type=.whitespace, text=text[i:j] })
            i = j

        case '\n':
            append(pool, Text_Token { type=.br, text="\n" })
            i += 1

        case '|':
            j := i + 1
            for j < text_len && text[j]!='|' do j += 1
            if j < text_len && text[j]=='|' {
                tag_text := text[i+1:j] // Extract text between '|' and '|'
                cmd, args := _text_parse_tag_text(tag_text)
                switch cmd {
                case ""         : append(pool, Text_Token { type=.word, text=text[i:i+1] }) // double pipe ("||")
                case "br"       : append(pool, Text_Token { type=.br, text="\n" })
                case "tab"      : v, _ := strconv.parse_f32(args)
                                  append(pool, Text_Token { type=.tab, size={v,0} })
                case "wrap"     : append(pool, Text_Token { type=.wrap })
                case "nowrap"   : append(pool, Text_Token { type=.nowrap })
                case "left"     : append(pool, Text_Token { type=.left })
                case "right"    : append(pool, Text_Token { type=.right })
                case "center"   : append(pool, Text_Token { type=.center })
                case            : append(pool, Text_Token { type=.custom, text=cmd, args=args })
                }
                i = j + 1 // Move cursor after closing '|'
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

    assert(len(pool) != cap(pool), "Most likely Context.visible_text_tokens overflow")
    return pool[pool_len:]
}

// Measures given tokes. Updates each `Text_Token.size`.
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

// Wraps and aligns given tokes. Updates each `Text_Token.solved_pos`.
// Returns total height needed to fit all the tokens with given `max_width`.
_text_wrap_tokens :: proc (ctx: ^Context, tokens: [] Text_Token, max_width: f32) -> (total_height: f32) #no_bounds_check {
    cursor_x: f32
    cursor_y: f32
    line_height: f32
    line_start_i: int

    style := Text_Style_Default
    if ctx.on_text_style != nil do ctx->on_text_style(&style)
    align := style.align
    wrapping := style.wrapping

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
        overflow := wrapping && cursor_x > 0 && (cursor_x + tok.size.x > max_width)

        if overflow || tok.type == .br {
            _text_apply_line_alignment(tokens[line_start_i:i], max_width, align)

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

    // align very last line
    _text_apply_line_alignment(tokens[line_start_i:], max_width, align)

    return cursor_y + line_height
}

_text_apply_line_alignment :: proc (line_tokens: [] Text_Token, max_width: f32, align: Text_Alignment) #no_bounds_check {
    if len(line_tokens) == 0 do return

    start_i: int
    end_i := len(line_tokens) - 1

    leading_space_w: f32
    for start_i <= end_i {
        tok := &line_tokens[start_i]
        if _text_token_is_non_printable(tok) {
            leading_space_w += tok.size.x
            start_i += 1
        } else {
            break
        }
    }

    trailing_space_w: f32
    for end_i >= start_i {
        tok := &line_tokens[end_i]
        if _text_token_is_non_printable(tok) {
            trailing_space_w += tok.size.x
            end_i -= 1
        } else {
            break
        }
    }

    printable_line_width: f32
    for i in start_i..=end_i {
        printable_line_width += line_tokens[i].size.x
    }

    if printable_line_width <= 0 {
        for &tok in line_tokens do tok.solved_pos = {}
        return
    }

    shift_amount: f32
    switch align {
    case .left  : /**/
    case .right : shift_amount +=  max_width - printable_line_width
    case .center: shift_amount += (max_width - printable_line_width) / 2
    }

    if shift_amount < 0 do shift_amount = 0

    for &tok, i in line_tokens {
        if i >= start_i && i <= end_i do tok.solved_pos.x += shift_amount
        else                          do tok.solved_pos = {}
    }
}

// Token is `.whitespace` or has zero width
_text_token_is_non_printable :: proc (tok: ^Text_Token) -> bool {
    return tok.type == .whitespace || tok.size.x == 0
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
