package main

import "core:fmt"
import "core:os"
import "core:strings"

import "../../core"
import hi ".."
import k2 "../../../../karl2d"

Popup :: struct {
    ui_root     : ^hi.View,
    ui_window   : ^hi.View,
    ui_title    : ^hi.View,
    ui_tabs     : ^hi.View,
    ui_pages    : ^hi.View,
    ui_page_info: ^hi.View,
    ui_page_text: ^hi.View,
    // ui_page_image   : ^hi.View, // TODO: Add image view (tab)

    sb_title    : strings.Builder,
    sb_page_info: strings.Builder,
    buf_tokens  : [dynamic] hi.Text_Token,
    buf_bytes   : [1_000_000] u8,
}

popup_create :: proc (parent: ^hi.View) -> ^Popup {
    popup := new(Popup)

    popup.sb_title      = strings.builder_make(0, 200)
    popup.sb_page_info  = strings.builder_make(0, 2_000)
    popup.buf_tokens    = make([dynamic] hi.Text_Token, 0, 20_000)

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
    for text in ([?] string { "Info", "Text" }) {
        hi.add_view(popup.ui_tabs, {
            flags   = { .text, .text_fit_x, .radio },
            padding = 20,
            text    = text,
            user_ptr= popup,
            on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
                if event.type == .clicked {
                    popup := cast (^Popup) v.user_ptr
                    // Assuming tab index corresponds to page index
                    idx := hi.view_index(v)
                    page := hi.child_by_index(popup.ui_pages, idx)
                    hi.show(page)
                    consumed = true
                }
                return
            },
            on_draw = _popup_draw_button_view,
        })
    }

    popup.ui_pages = hi.add_view(popup.ui_window, {
        flags   = { .fill_x, .fill_y, .scissor, .wheel_scroll_y },
        padding = 20,
        on_draw = proc (v: ^hi.Visible_View) {
            k2.draw_rect(k2.Rect(v.solved_rect), core.gray1)
        },
    })

    popup.ui_page_info = hi.add_view(popup.ui_pages, { flags={ .text, .fill_x, .page } })
    popup.ui_page_text = hi.add_view(popup.ui_pages, { flags={ .text, .text_wordy, .fill_x, .page } })

    footer_bar := hi.add_view(popup.ui_window, { flags={ .fill_x, .fit_y }, layout={ dir=.row, justify=.center, gap=20 } })
    hi.add_view(footer_bar, {
        flags   = { .text, .text_fit_x },
        padding = 20,
        text    = "Close",
        user_ptr= popup,
        on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
            if event.type == .clicked {
                popup := cast (^Popup) v.user_ptr
                hi.hide(popup.ui_root)
                consumed = true
            }
            return
        },
        on_draw = _popup_draw_button_view,
    })

    assert(
        hi.child_count(popup.ui_tabs) == hi.child_count(popup.ui_pages),
        "We rely on this condition when handling .clicked of a tab button",
    )

    return popup
}

popup_destroy :: proc (popup: ^Popup) {
    hi.remove_view(popup.ui_root)
    strings.builder_destroy(&popup.sb_title)
    strings.builder_destroy(&popup.sb_page_info)
    delete(popup.buf_tokens)
    free(popup)
}

popup_open :: proc (popup: ^Popup, file: ^os.File_Info) {
    log(#procedure, file.fullpath)

    // setup title

    strings.builder_reset(&popup.sb_title)
    hi.set_text(popup.ui_title, fmt.sbprintf(&popup.sb_title,
        "|s=huge||i=%v| %s",
        file.type,
        file.name,
    ))

    _popup_setup_page_info(popup, file)

    _popup_setup_page_text(popup, file.fullpath)

    // Click 1st tab button, this essentially does the following:
    // - each button has .radio, when .clicked it gets .selected, while other .radio siblings get de-.selected
    // - button receives .clicked where we do show(page)
    // - each page has .page, so when shown it hides all other .page siblings
    hi.click(popup.ui_tabs.first_child)

    hi.scroll_to_start(popup.ui_pages)
    hi.show(popup.ui_root)
}

_popup_setup_page_info :: proc (popup: ^Popup, file: ^os.File_Info) {
    strings.builder_reset(&popup.sb_page_info)
    hi.set_text(popup.ui_page_info, fmt.sbprintf(&popup.sb_page_info,
        "Full file path is |c=#ff8|%s|c|. " +
        "File name with icon is |c=#f8f||i=%v| %s|c|. " +
        "File size is |c=#f88||s=huge|%M|s||c| and its modified time is |c=#88f|%s|c|.\n" +
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
        "|tab=150|B = C|b=index|min|b| + D|b=index|max|b|\n" +
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

_popup_setup_page_text :: proc (popup: ^Popup, file_fullpath: string) {
    popup.ui_page_text.flags -= { .text_raw }

    f, err := os.open(file_fullpath)
    defer os.close(f)
    defer if err != nil {
        hi.set_text(popup.ui_page_text, fmt.bprintf(popup.buf_bytes[:], "|c=error|%v", err))
    }

    if err != nil do return

    f_size: i64
    f_size, err = os.file_size(f)
    switch {
    case f_size == 0:
        hi.set_text(popup.ui_page_text, "|c=muted|File is empty")
    case f_size > len(popup.buf_bytes):
        hi.set_text(popup.ui_page_text, "|c=muted|File too large")
    case:
        n: int
        n, err = os.read_full(f, popup.buf_bytes[:f_size])
        if err == nil {
            assert(i64(n) == f_size)
            hi.set_text(popup.ui_page_text, string(popup.buf_bytes[:n]))
            popup.ui_page_text.flags += { .text_raw }
        }
    }
}

_popup_draw_button_view :: proc (v: ^hi.Visible_View) {
    switch {
    case .selected in v.flags   : k2.draw_rect(k2.Rect(v.solved_rect), core.gray1)
    case .hovered in v.flags    : k2.draw_rect(k2.Rect(v.solved_rect), core.gray4)
    }
    v.ctx.on_draw_text(v)
}
