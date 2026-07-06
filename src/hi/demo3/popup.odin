package main

import "core:fmt"
import "core:os"
import "core:strings"

import "../../core"
import hi ".."
import k2 "../../../../karl2d"

Popup :: struct {
    ui_root         : ^hi.View,
    ui_window       : ^hi.View,
    ui_title        : ^hi.View,
    ui_tabs         : ^hi.View,
    ui_pages        : ^hi.View,
    ui_page_info    : ^hi.View,
    ui_page_text    : ^hi.View,
    ui_page_image   : ^hi.View,

    buf_title       : strings.Builder,
    buf_info        : strings.Builder,
    buf_tokens      : [dynamic] hi.Text_Token,

    buf_bytes       : [1_000_000] u8,
    buf_bytes_used  : int,          // Set only when no `issue`
    buf_bytes_issue : string,       // If set, contains rich formatted string, slice into `data`

    buf_texture     : k2.Texture,
    buf_texture_err : strings.Builder,
}

popup_create :: proc (parent: ^hi.View) -> ^Popup {
    popup := new(Popup)

    popup.buf_title         = strings.builder_make(0, 200)
    popup.buf_info          = strings.builder_make(0, 2_000)
    popup.buf_texture_err   = strings.builder_make(0, 200)
    popup.buf_tokens        = make([dynamic] hi.Text_Token, 0, 20_000)

    popup.ui_root = hi.add_view(parent, {
        flags   = { .ratio_x, .ratio_y, .hidden },
        size    = 1,
        strata  = .overlay,
        on_draw = proc (v: ^hi.Visible_View) {
            rect := hi.ref_view_to_screen(v)
            k2.draw_rect(k2.Rect(rect), {255,255,255,120})
        },
    })

    popup.ui_window = hi.add_view(popup.ui_root, {
        flags   = { .ratio_x, .ratio_y, .scissor },
        size    = { .5, 1 },
        place   = { anchor=.5, pivot=.5 },
        layout  = { dir=.column },
        on_draw = proc (v: ^hi.Visible_View) {
            k2.draw_rect(k2.Rect(v.solved_rect), core.gray2)
        },
    })

    popup.ui_title = hi.add_view(popup.ui_window, { flags={ .text, .fill_x }, padding=20 })

    popup.ui_tabs = hi.add_view(popup.ui_window, { flags={ .fill_x, .fit_y }, layout={ dir=.row }, padding={20,0,20,0} })

    popup.ui_pages = hi.add_view(popup.ui_window, {
        flags   = { .fill_x, .fill_y },
        padding = 20,
        on_draw = proc (v: ^hi.Visible_View) {
            k2.draw_rect(k2.Rect(v.solved_rect), core.gray1)
        },
    })

    for p in ([?] struct { title: string, content: ^^hi.View, init: hi.View_Init } {
        { "Text", &popup.ui_page_text, { flags={ .text, .text_wordy, .ratio_x }, size=1 } },
        { "Image", &popup.ui_page_image, {} },
        { "Info", &popup.ui_page_info, { flags={ .text, .ratio_x }, size=1 } },
    }) {
        hi.add_view(popup.ui_tabs, {
            flags   = { .text, .text_fit_x, .radio },
            padding = 20,
            text    = p.title,
            user_ptr= popup,
            on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
                if event.type == .clicked {
                    popup := cast (^Popup) v.user_ptr
                    idx := hi.view_index(v)
                    page := hi.child_by_index(popup.ui_pages, idx)
                    hi.show(page)
                    consumed = true
                }
                return
            },
            on_draw = _popup_draw_button_view,
        })

        // Each page consists of two views: container + content
        // The reason we need container is that we want it to keep scroll position of the content,
        // because once view is .text, its height is determined by measured text, and such view
        // cannot provide scrolling window of itself, so we wrap content view into container view.
        // P.S.: if we skip container and make so ui_pages be a single container for all contents,
        // every time we switch a page, the scroll will be clamped to the new content bounds,
        // which is not critical but ugly.

        container := hi.add_view(popup.ui_pages, { flags={ .page, .ratio_x, .ratio_y, .scissor, .wheel_scroll_y }, size=1 })
        p.content^ = hi.add_view(container, p.init)
    }

    popup.ui_page_image.user_ptr = popup
    popup.ui_page_image.on_draw = proc (v: ^hi.Visible_View) {
        popup := cast (^Popup) v.user_ptr
        if v.text == "" {
            assert(popup.buf_texture != {})
            pos := [2] f32 { v.solved_rect.x, v.solved_rect.y }
            k2.draw_texture(popup.buf_texture, pos)
        } else {
            v.ctx.on_draw_text(v)
        }
    }

    footer_bar := hi.add_view(popup.ui_window, { flags={ .fill_x, .fit_y }, layout={ dir=.row, justify=.center, gap=20 } })
    hi.add_view(footer_bar, {
        flags   = { .text, .text_fit_x },
        padding = 20,
        text    = "Close",
        user_ptr= popup,
        on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
            if event.type == .clicked {
                popup := cast (^Popup) v.user_ptr
                popup_close(popup)
                consumed = true
            }
            return
        },
        on_draw = _popup_draw_button_view,
    })

    return popup
}

popup_destroy :: proc (popup: ^Popup) {
    hi.remove_view(popup.ui_root)
    strings.builder_destroy(&popup.buf_title)
    strings.builder_destroy(&popup.buf_info)
    strings.builder_destroy(&popup.buf_texture_err)
    _popup_destroy_buf_texture(popup)
    delete(popup.buf_tokens)
    free(popup)
}

_popup_destroy_buf_texture :: proc (popup: ^Popup) {
    if popup.buf_texture != {} {
        k2.destroy_texture(popup.buf_texture)
        popup.buf_texture = {}
    }
}

popup_open :: proc (popup: ^Popup, file: ^os.File_Info) {
    log(#procedure, file.fullpath)

    _popup_setup_title(popup, file)
    _popup_setup_page_info(popup, file)
    _popup_setup_buf_bytes(popup, file.fullpath)
    _popup_setup_page_text(popup) // uses buf_bytes
    _popup_setup_page_image(popup) // uses buf_bytes

    // Click 1st tab button, this essentially does the following:
    // - each button has .radio, when .clicked it gets .selected, while other .radio siblings get de-.selected
    // - button receives .clicked where we do show(page)
    // - each page has .page, so when shown it hides all other .page siblings
    hi.click(popup.ui_tabs.first_child)

    hi.show(popup.ui_root)
}

popup_close :: proc (popup: ^Popup) {
    hi.hide(popup.ui_root)
    _popup_destroy_buf_texture(popup)
}

_popup_setup_title :: proc (popup: ^Popup, file: ^os.File_Info) {
    strings.builder_reset(&popup.buf_title)
    hi.set_text(popup.ui_title, fmt.sbprintf(&popup.buf_title,
        "|s=huge||i=%v| %s",
        file.type,
        file.name,
    ))
}

_popup_setup_page_info :: proc (popup: ^Popup, file: ^os.File_Info) {
    hi.scroll_to_start(popup.ui_page_info.parent)
    strings.builder_reset(&popup.buf_info)
    // popup.ui_page_info.flags += { .text_raw }
    hi.set_text(popup.ui_page_info, fmt.sbprintf(&popup.buf_info,
        "Full file path is |c=#ff8|%s|c|. " +
        "File name with icon is |c=#f8f||i=%v| %s|c|. " +
        "File size is |c=#f88|%M|c| and its modified time is |c=#88f|%s|c|.\n" +
        "\n" +
        "File mode is |file_mode=%d|. " +
        "We can change colors and custom inline tokens are also automatically wraps. " +
        "Here is File mode again with larger font and different color: |s=large||c=#8ff|Mode is |file_mode=%d||c||s|. " +
        "The custom token for file mode is |raw|\"|file_mode=%d|\"|noraw|\n" +
        "\n" +
        "|c=#069||divider||c|\n" +
        "\n" +
        "|center|This popup takes 50%% of width and 100%% of height. " +
        "Resize the app window to see automatic wrapping in action. " +
        "This paragraph starts and ends with custom token |raw|\"|divider|\"|noraw| which occupies full line. " +
        "Like any other token, it can use any running style info, e.g. color, font, user state.\n|left|" +
        "\n" +
        "|c=#960||divider||c|\n" +
        "\n" +
        "|right|We can use different font heights on a same line, " +
        "each text token has |c=#0ff|baseline_ratio|c| for proper vertical alignment, " +
        "normal text uses current style font baseline, while custom tokens can override it.\n|left|" +
        "\n" +
        "Mixing font sizes: " +
        "|s=tiny|Tiny |s|Normal |s=large|Large |s=huge|Huge " +
        "|s=large|Large |s|Normal |s=tiny|Tiny|s|\n" +
        "\n" +
        "Press |c=#f0f|TAB|c| to enable Debug mode to see token baselines. " +
        "Any printed text line aligns all its token baselines in a strait line.\n" +
        "\n" +
        "Mixing baselines: " +
        "|tab=150|F|b=index|n|b| = F|b=index|n-1|b| + F|b=index|n-2|b|\n" +
        "|tab=150|A = [ A|b=index|1|b|, A|b=index|2|b|, A|b=index|2|b|, A|b=index|3|b|, ... ]\n" +
        "|tab=150|B|b=index|avg|b| = ( B|b=index|min|b| + B|b=index|max|b| ) / 2\n" +
        "|tab=150|z|b=super|2|b| = x|b=super|2|b| + y|b=super|2|b|\n" +
        "|tab=150|e = mc|b=super|2|b|",
        file.fullpath,
        file.type,
        file.name,
        file.size,
        _format_time(file.modification_time, allocator=context.temp_allocator),
        transmute (u32) file.mode,
        transmute (u32) file.mode,
        transmute (u32) file.mode,
    ))
}

_popup_setup_page_text :: proc (popup: ^Popup) {
    hi.scroll_to_start(popup.ui_page_text.parent)

    if popup.buf_bytes_issue == "" {
        hi.set_text(popup.ui_page_text, string(popup.buf_bytes[:popup.buf_bytes_used]))
        popup.ui_page_text.flags += { .text_raw }
    } else {
        hi.set_text(popup.ui_page_text, popup.buf_bytes_issue)
        popup.ui_page_text.flags -= { .text_raw }
    }
}

_popup_setup_page_image :: proc (popup: ^Popup) {
    hi.scroll_to_start(popup.ui_page_image.parent)
    strings.builder_reset(&popup.buf_texture_err)
    err: string

    defer {
        hi.set_text(popup.ui_page_image, err)
        if err != "" {
            popup.ui_page_image.flags += { .text, .ratio_x }
            popup.ui_page_image.size = 1
        }
    }

    if popup.buf_bytes_issue == "" {
        assert(popup.buf_texture == {})
        popup.buf_texture = k2.load_texture_from_bytes(popup.buf_bytes[:popup.buf_bytes_used])
        if popup.buf_texture != {} {
            popup.ui_page_image.flags -= { .text, .ratio_x }
            popup.ui_page_image.size = { f32(popup.buf_texture.width), f32(popup.buf_texture.height) }
        } else {
            err = fmt.sbprint(&popup.buf_texture_err, "|c=error||s=large|Failed to k2.load_texture_from_bytes()")
        }
    } else {
        err = fmt.sbprint(&popup.buf_texture_err, popup.buf_bytes_issue)
    }
}

_popup_setup_buf_bytes :: proc (popup: ^Popup, file_fullpath: string) {
    popup.buf_bytes_used = 0
    popup.buf_bytes_issue = ""

    f, err := os.open(file_fullpath)
    defer {
        if err != nil {
            popup.buf_bytes_issue = fmt.bprintf(popup.buf_bytes[:], "|c=error||s=large|%v", err)
        }
        os.close(f)
    }

    if err != nil do return

    f_size: i64
    f_size, err = os.file_size(f)
    switch {
    case f_size == 0:
        popup.buf_bytes_issue = fmt.bprintf(popup.buf_bytes[:], "|c=muted||s=large|File is empty")
    case f_size > len(popup.buf_bytes):
        b1, b2: [32] u8
        popup.buf_bytes_issue = fmt.bprintf(popup.buf_bytes[:],
            "|c=error||s=large|File too large|s||c=muted|\n" +
            "File size is %s bytes\n" +
            "Size limit is %s bytes",
            core.format_buf_int(b1[:], f_size),
            core.format_buf_int(b2[:], len(popup.buf_bytes)),
        )
    case:
        popup.buf_bytes_used, err = os.read_full(f, popup.buf_bytes[:f_size])
        if err == nil do assert(i64(popup.buf_bytes_used) == f_size)
    }
}

_popup_draw_button_view :: proc (v: ^hi.Visible_View) {
    switch {
    case .selected in v.flags   : k2.draw_rect(k2.Rect(v.solved_rect), core.gray1)
    case .hovered in v.flags    : k2.draw_rect(k2.Rect(v.solved_rect), core.gray4)
    }
    v.ctx.on_draw_text(v)
}
