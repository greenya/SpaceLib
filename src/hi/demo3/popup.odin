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
    ui_text     : ^hi.View,
    sb_text     : strings.Builder,
    buf_tokens  : [dynamic] hi.Text_Token,
}

popup_create :: proc (parent: ^hi.View) -> ^Popup {
    popup := new(Popup)

    popup.sb_text = strings.builder_make()

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
        flags   = { .ratio_x, .ratio_y, .wheel_scroll_layout },
        size    = { .5, 1 },
        place   = { anchor=.5, pivot=.5 },
        layout  = { dir=.column },
        padding = 20,
        on_draw = proc (v: ^hi.Visible_View) {
            rect := v.solved_rect
            k2.draw_rect(k2.Rect(rect), core.gray2)
        },
    })

    popup.ui_text = hi.add_view(popup.ui_window, { flags={ .text, .text_wordy, .fill_x } })

    return popup
}

popup_destroy :: proc (popup: ^Popup) {
    hi.remove_view(popup.ui_root)
    strings.builder_destroy(&popup.sb_text)
    delete(popup.buf_tokens)
    free(popup)
}

popup_open :: proc (popup: ^Popup, file: ^os.File_Info) {
    // TODO: impl
    log(#procedure)
    log(file)

    strings.builder_reset(&popup.sb_text)
    hi.set_text(popup.ui_text, fmt.sbprintf(&popup.sb_text,
        "|s=huge||i=%v| %s|s|\n\n" +
        "|c=muted||divider||c|\n\n" +
        "Some details goes here... Some details goes here... |i=Directory| Some details goes here... |i=Symlink| Some details goes here...\n\n" +
        "|c=muted||divider||c|\n\n" +
        "File content goes here...",
        file.type,
        file.name,
    ))

    hi.show(popup.ui_root)
}
