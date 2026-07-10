package hi

import "core:strings"
import "core:strconv"

Text_Token :: struct {
    type        : Text_Token_Type,
    flags       : Text_Token_Flags,
    text        : string,   // Text of the `.word` or `.whitespace`, or the name of a `.custom` token (e.g., "color" for "|color=primary|")
    args        : string,   // `.custom` token arguments (e.g., "primary" for "|color=primary|")
    size        : Vec2,     // Occupied size received from `Context.on_text_measure()` and `Context.on_text_custom_token()`. Note: For `.scale_full_line` custom tokens, `size.x` is the unresolved line-width scale. Use `solved_width` for any token type instead.
    ascent      : f32,      // Distance from token top to baseline
    descent     : f32,      // Distance from baseline to token bottom
    intext_view : ^View,    // `.intext` view this token is bound with
    solved_pos  : Vec2,     // Calculated by the wrapping algorithm
    solved_width: f32,      // Calculated by the wrapping algorithm. Usually `size.x`, but can differ for `.tab` and custom tokens.
}

Text_Token_Type :: enum u8 {
    // Content

    word,       // Continuous block of letters/numbers/punctuations between other tokens
    whitespace, // Continuous block of spaces `" "` or tabs `\t`

    // Commands

    br,         // `|br|` Line break or newline `\n`

    left,       // `|left|` Align to the left
    right,      // `|right|` Align to the right
    center,     // `|center|` Align to the center

    tab,        // `|tab=XXX|` Tab stop. Moves cursor X forward to XXX if current X is lower. In wrapping mode, overflowed continuation lines start at the last tab stop until `\n`, `|br|`, or another tab stop.

    wrap,       // `|wrap|` Enable wrapping mode
    nowrap,     // `|nowrap|` Disable wrapping mode

    raw,        // `|raw|` Enable raw mode. In raw mode, tags are not parsed and are treated as text (expecting only `.word`, `.whitespace`, and `.br` tokens). The only tag parsed is `|noraw|`. Note: the tokenizer never adds this token type to the result stream.
    noraw,      // `|noraw|` Disable raw mode. Note: the tokenizer never adds this token type to the result stream.

    // Custom

    custom,     // Custom/unknown token, e.g., `|icon=sword|` or `|item=#1234|`. Values are stored in `Text_Token.text` and `Text_Token.args`, and should be processed in `Context.on_text_custom_token()`.
}

Text_Token_Flags :: bit_set [Text_Token_Flag; u32]
Text_Token_Flag :: enum {
    scale_full_line, // If set, `size.x` is a scaler for full line width; otherwise it is scaler for style font height
}

Text_Custom_Token_Hint :: struct {
    intext_view     : ^View,    // If set, the view defines token size while the token defines view's position. The view must have `.intext` flag and be a child of `.text` view this token is part of. Using `intext_view` makes `scale` and `scale_full_line` to be ignored.
    scale           : Vec2,     // Relative to current text style font height. If `scale_full_line` is set, `scale.x` is relative to full line width.
    scale_full_line : bool,     // If set, `scale.x` is scaled to full line width instead of font height. This flag should not be used with `.text_fit_x`.
    baseline_ratio  : f32,      // From 0 to 1 ratio inside the custom token box
}

// Tokenizes given text.
// Appends to the `pool` and returns slice of just appended tokens.
_text_tokenize :: proc (pool: ^[dynamic] Text_Token, text: string, is_raw_exclusive: bool) -> [] Text_Token #no_bounds_check {
    pool_len_start := len(pool)
    text_len := len(text)
    raw_mode := is_raw_exclusive

    for i := 0; i < text_len; /**/ {
        r := text[i]

        raw_end_tag :: "|noraw|"
        if raw_mode && !is_raw_exclusive && r == '|' && i + len(raw_end_tag) <= text_len {
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
                tag_name, tag_args := _text_parse_tag_text(tag_text)
                switch tag_name {
                case ""         : append(pool, Text_Token { type=.word, text=text[i:i+1] }) // double pipe ("||")

                case "br"       : append(pool, Text_Token { type=.br, text="\n" })

                case "left"     : append(pool, Text_Token { type=.left })
                case "right"    : append(pool, Text_Token { type=.right })
                case "center"   : append(pool, Text_Token { type=.center })

                case "wrap"     : append(pool, Text_Token { type=.wrap })
                case "nowrap"   : append(pool, Text_Token { type=.nowrap })

                case "tab"      : v, _ := strconv.parse_f32(tag_args)
                                  append(pool, Text_Token { type=.tab, size={v,0} })

                case "raw"      : raw_mode = true

                case            : append(pool, Text_Token { type=.custom, text=tag_name, args=tag_args })
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

// Measures text tokens of a given view.
// - Updates each `Text_Token.size/ascent/descent`.
_text_measure_tokens :: proc (v: ^Visible_View) #no_bounds_check {
    ctx := v.ctx
    style := _text_style_init(v)
    has_on_text_measure := ctx.on_text_measure != nil
    has_on_text_custom_token := ctx.on_text_custom_token != nil

    for &tok in v.solved_text_tokens do #partial switch tok.type {
    case .word, .whitespace:
        if has_on_text_measure {
            tok.size = ctx.on_text_measure(style, tok.type, tok.text)
            _tok_setup_ascent_descent(&tok, style.font_baseline_ratio)
        }
    case .br:
        tok.size.y = style.font_scale * ctx.ref_font_height
        _tok_setup_ascent_descent(&tok, style.font_baseline_ratio)
    case .custom:
        if has_on_text_custom_token {
            hint := Text_Custom_Token_Hint { baseline_ratio=style.font_baseline_ratio }
            ctx.on_text_custom_token(v, &style, tok.text, tok.args, &hint)
            switch {
            case hint.intext_view != nil:
                iv := hint.intext_view
                assert(.intext in iv.flags, "Text_Custom_Token_Hint.intext_view must have .intext flag")
                assert(iv.parent == v.view, "Text_Custom_Token_Hint.intext_view must be child of the .text view it is used in")
                tok.intext_view = iv
                tok.size = { iv.solved_rect.w, iv.solved_rect.h }
                _tok_setup_ascent_descent(&tok, hint.baseline_ratio)
            case hint.scale != {}:
                if hint.scale_full_line {
                    tok.flags += { .scale_full_line }
                    tok.size = {
                        hint.scale.x, // Keep scale.x value as-is, for wrapping step
                        hint.scale.y * style.font_scale * ctx.ref_font_height,
                    }
                } else {
                    tok.size = hint.scale * style.font_scale * ctx.ref_font_height
                }
                _tok_setup_ascent_descent(&tok, hint.baseline_ratio)
            }
        }
    }

    _tok_setup_ascent_descent :: proc (tok: ^Text_Token, baseline_ratio: f32) {
        tok.ascent = tok.size.y * baseline_ratio
        tok.descent = tok.size.y * (1 - baseline_ratio)
    }
}

// Wraps and aligns text tokens of a given view.
// - Updates each `Text_Token.solved_*`
// - Updates each `Text_Token.intext_view.solved_rect.x/y`
// - Automatic wrapping is applied if `limit_x > 0`
// - Alignment tokens effective only if `limit_x > 0`
// - Returns total `extent` fitting all the tokens; expect `extent.x >= limit_x`
_text_wrap_tokens :: proc (v: ^Visible_View, limit_x: f32) -> (extent: Vec2, intext_mismatch: bool) #no_bounds_check {
    cursor_x: f32
    cursor_y: f32
    overflow_cursor_x: f32
    overflow_allowed: bool
    line_start_i: int
    line_max_ascent: f32
    line_max_descent: f32

    ctx := v.ctx
    tokens := v.solved_text_tokens
    style := _text_style_init(v)
    has_on_text_custom_token := ctx.on_text_custom_token != nil
    has_intext_views: bool

    extent.x = limit_x

    for &tok, i in tokens {
        tok.solved_width = tok.size.x
        if .scale_full_line in tok.flags do tok.solved_width *= max(limit_x, 0)

        #partial switch tok.type {
        case .left      : style.align = .left       ; continue
        case .right     : style.align = .right      ; continue
        case .center    : style.align = .center     ; continue
        case .wrap      : style.wrapping = true     ; continue
        case .nowrap    : style.wrapping = false    ; continue

        case .tab:
            next_x := max(cursor_x, tok.solved_width)
            tok.solved_pos = { cursor_x, cursor_y }
            tok.solved_width = next_x - cursor_x
            cursor_x = next_x
            overflow_cursor_x = next_x
            overflow_allowed = false
            continue

        case .custom:
            if has_on_text_custom_token {
                ctx.on_text_custom_token(v, &style, tok.text, tok.args, out_hint=nil)
                has_intext_views ||= tok.intext_view != nil
            }
        }

        if tok.type == .br {
            line_max_ascent = max(line_max_ascent, tok.ascent)
            line_max_descent = max(line_max_descent, tok.descent)

            extent.x = max(extent.x, _text_finalize_line(
                tokens[line_start_i:i],
                limit_x,
                line_max_ascent,
                style.align,
            ))

            cursor_x = 0
            cursor_y += line_max_ascent + line_max_descent
            overflow_cursor_x = 0
            line_max_ascent = 0
            line_max_descent = 0
            line_start_i = i + 1
            overflow_allowed = false

            continue
        }

        overflow :=
            style.wrapping &&
            limit_x > 0 &&
            overflow_allowed &&
            _tok_starts_printable_content(tok) &&
            cursor_x + tok.solved_width > limit_x

        if overflow {
            extent.x = max(extent.x, _text_finalize_line(
                tokens[line_start_i:i],
                limit_x,
                line_max_ascent,
                style.align,
            ))

            cursor_x = overflow_cursor_x
            cursor_y += line_max_ascent + line_max_descent
            line_max_ascent = 0
            line_max_descent = 0
            line_start_i = i
            overflow_allowed = false
        }

        line_max_ascent = max(line_max_ascent, tok.ascent)
        line_max_descent = max(line_max_descent, tok.descent)

        tok.solved_pos = { cursor_x, cursor_y }
        cursor_x += tok.solved_width
        overflow_allowed ||= _tok_starts_printable_content(tok)
    }

    // align very last line and set the total height
    extent = {
        max(extent.x, _text_finalize_line(
            tokens[line_start_i:],
            limit_x,
            line_max_ascent,
            style.align,
        )),
        cursor_y + line_max_ascent + line_max_descent,
    }

    if has_intext_views {
        top_left := content_top_left(v)
        for tok in tokens do if tok.intext_view != nil {
            assert(._intext_bound not_in tok.intext_view.flags, "Text_Token.intext_view is already bound to another text token")
            tok.intext_view.flags += { ._intext_bound }

            tok_pos_ref := tok.solved_pos + top_left
            intext_mismatch ||= abs(tok_pos_ref.x-tok.intext_view.solved_rect.x)>.1\
                            ||  abs(tok_pos_ref.y-tok.intext_view.solved_rect.y)>.1
            tok.intext_view.solved_rect.x = tok_pos_ref.x
            tok.intext_view.solved_rect.y = tok_pos_ref.y
        }
    }

    return

    _tok_starts_printable_content :: proc (tok: Text_Token) -> bool {
        return tok.solved_width > 0 && (tok.type!=.whitespace && tok.type!=.tab)
    }
}

// Finalizes line of tokens:
// - Applies horizontal alignment only if `limit_x > 0`
// - Applies baseline alignment
// - Updates each `Text_Token.solved_pos`
_text_finalize_line :: proc (
    line_tokens     : [] Text_Token,
    limit_x         : f32,
    line_max_ascent : f32,
    align           : Text_Alignment,
) -> (extent_x: f32) #no_bounds_check {
    if len(line_tokens) == 0 do return

    start_i: int
    end_i := len(line_tokens) - 1

    for start_i <= end_i {
        tok := &line_tokens[start_i]
        if _tok_is_trimmed_for_alignment(tok) do start_i += 1
        else do break
    }

    for end_i >= start_i {
        tok := &line_tokens[end_i]
        if _tok_is_trimmed_for_alignment(tok) do end_i -= 1
        else do break
    }

    if start_i > end_i {
        // the line has no printable tokens -- reset all positions
        for &tok in line_tokens do tok.solved_pos = {}
        return
    }

    printable_line_width: f32
    for i in start_i..=end_i {
        printable_line_width += line_tokens[i].solved_width
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
        if i >= start_i && i <= end_i {
            tok.solved_pos += { shift_amount, line_max_ascent - tok.ascent }
        } else {
            tok.solved_pos = {}
        }
    }

    return line_tokens[end_i].solved_pos.x + line_tokens[end_i].solved_width

    _tok_is_trimmed_for_alignment :: proc (tok: ^Text_Token) -> bool {
        return tok.type == .whitespace || tok.solved_width == 0
    }
}

_text_parse_tag_text :: proc (tag_text: string) -> (name, args: string) #no_bounds_check {
    i := strings.index_byte(tag_text, '=')
    if i >= 0   do return tag_text[0:i], tag_text[i+1:]
    else        do return tag_text, ""
}

Text_Token_Iterator :: struct {
    view    : ^Visible_View,
    style   : Text_Style,
    filter  : bit_set [Text_Token_Type],
    next_i  : int,
}

// The `filter` affects only returned tokens; the `.custom` tokens always get processed for `Text_Token_Iterator.style` changes.
@require_results
text_token_iterate :: proc (
    v       : ^Visible_View,
    filter  := bit_set [Text_Token_Type] { .word, .custom },
) -> (it: Text_Token_Iterator) {
    assert(filter != {})

    it = {
        view    = v,
        style   = _text_style_init(v),
        filter  = filter,
    }

    return
}

@require_results
text_token_next :: proc (it: ^Text_Token_Iterator) -> (tok: ^Text_Token, ok: bool) #no_bounds_check {
    ctx := it.view.ctx
    tokens := it.view.solved_text_tokens
    for i := it.next_i; i < len(tokens); i += 1 {
        tok = &tokens[i]
        if tok.type == .custom && ctx.on_text_custom_token != nil {
            ctx.on_text_custom_token(it.view, &it.style, tok.text, tok.args, out_hint=nil)
        }
        if tok.type in it.filter {
            it.next_i = i + 1
            ok = true
            return
        }
    }
    return
}
