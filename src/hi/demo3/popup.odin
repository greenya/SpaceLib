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
    ui_page_text    : ^hi.View,
    ui_page_image   : ^hi.View,
    ui_page_demo    : ^hi.View,
    ui_page_demo_counter: ^hi.View,

    buf_title       : strings.Builder,
    buf_demo        : strings.Builder,
    buf_demo_counter: strings.Builder,
    buf_tokens      : [dynamic] hi.Text_Token,

    buf_bytes       : [1_000_000] u8,
    buf_bytes_used  : int,      // Set only when `buf_bytes_issue == ""`
    buf_bytes_issue : string,   // If set, contains rich formatted string, slice into `buf_bytes`

    buf_texture     : k2.Texture,
    buf_texture_err : strings.Builder,
}

popup_create :: proc (parent: ^hi.View) -> ^Popup {
    popup := new(Popup)

    popup.buf_title         = strings.builder_make(0, 200)
    popup.buf_demo          = strings.builder_make(0, 2_000)
    popup.buf_demo_counter  = strings.builder_make(0, 20)
    popup.buf_texture_err   = strings.builder_make(0, 200)
    popup.buf_tokens        = make([dynamic] hi.Text_Token, 0, 20_000)

    popup.ui_root = hi.add_view(parent, {
        flags   = { .ratio_x, .ratio_y, .hidden },
        size    = 1,
        strata  = .high,
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

    popup.ui_tabs = hi.add_view(popup.ui_window, {
        flags   = { .fill_x, .fit_y, .wheel_scroll_layout },
        layout  = { dir=.row },
        padding = { 20,0,20,0 },
    })

    popup.ui_pages = hi.add_view(popup.ui_window, {
        flags   = { .fill_x, .fill_y },
        on_draw = proc (v: ^hi.Visible_View) {
            k2.draw_rect(k2.Rect(v.solved_rect), core.gray1)
        },
    })

    for p in ([?] struct { title: string, content: ^^hi.View, init: hi.View_Init } {
        { "Text\n|s=small|Content as text", &popup.ui_page_text, { flags={ .text, .text_wordy, .ratio_x }, size=1 } },
        { "Image\n|s=small|Content as image", &popup.ui_page_image, {} },
        { "Demo\n|s=small|Formatting demo and options", &popup.ui_page_demo, { flags={ .text, .ratio_x }, size=1 } },
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

        container := hi.add_view(popup.ui_pages, {
            flags   = { .page, .ratio_x, .ratio_y, .scissor, .wheel_scroll_y },
            size    = 1,
            padding = 20,
        })

        p.content^ = hi.add_view(container, p.init)

        if p.content^ == popup.ui_page_demo {
            _popup_page_demo_add_intext_views(popup)
            _popup_page_demo_add_action_bar(popup)
        }
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
    strings.builder_destroy(&popup.buf_demo)
    strings.builder_destroy(&popup.buf_demo_counter)
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
    _popup_setup_buf_bytes(popup, file.fullpath)
    _popup_setup_page_text(popup) // uses buf_bytes
    _popup_setup_page_image(popup) // uses buf_bytes
    _popup_setup_page_demo(popup, file)

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

_popup_page_demo_update_counter :: proc (popup: ^Popup, step := 0) {
    popup.ui_page_demo_counter.user_idx += step

    buf: [32] u8
    strings.builder_reset(&popup.buf_demo_counter)
    hi.set_text(popup.ui_page_demo_counter, fmt.sbprintf(&popup.buf_demo_counter,
        "|c=#8bf|%s",
        core.bprint_int(buf[:], popup.ui_page_demo_counter.user_idx),
    ))
}

_popup_page_demo_add_intext_views :: proc (popup: ^Popup) {
    for b in ([?] struct { name, text: string, step: int } {
        { "plus_1", "|c=#8f8|+1", 1 },
        { "plus_10", "|c=#8f8|+10", 10 },
        { "plus_100", "|c=#8f8|+100", 100 },
        { "plus_1k", "|c=#8f8|+1,000", 1000 },
        { "minus_1k", "|c=#f88|-1,000", -1000 },
        { "minus_100", "|c=#f88|-100", -100 },
        { "minus_10", "|c=#f88|-10", -10 },
        { "minus_1", "|c=#f88|-1", -1 },
    }) {
        hi.add_view(popup.ui_page_demo, {
            flags   = { .intext, .text, .text_fit_x },
            name    = b.name,
            text    = b.text,
            padding = { 5, 0, 5, 0 },
            user_ptr= popup,
            user_idx= b.step,
            on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
                if event.type == .clicked {
                    popup := cast (^Popup) v.user_ptr
                    _popup_page_demo_update_counter(popup, step=v.user_idx)
                    consumed = true
                }
                return
            },
            on_draw = _popup_draw_button_view,
        })
    }

    popup.ui_page_demo_counter = hi.add_view(popup.ui_page_demo, {
        flags   = { .intext, .text, .text_fit_x },
        on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
            if event.type == .wheeled {
                log("Demo counter label just consumed .wheeled event")
                consumed = true
            }
            return
        },
    })

    _popup_page_demo_update_counter(popup)
}

_popup_page_demo_add_action_bar :: proc (popup: ^Popup) {
    root := hi.add_view(popup.ui_page_demo.parent, {
        // Use higher strata to escape scissor;
        // if we only needed to escape layout/scroll/padding, the `.absolute` flag is the way
        strata  = .overlay,
        place   = { anchor={1,.5}, pivot={0,.5} },
        flags   = { .fit_x, .fit_y },
        layout  = { dir=.column },
        on_draw = proc (v: ^hi.Visible_View) {
            k2.draw_rect(k2.Rect(v.solved_rect), core.gray2)
        },
    })

    // .text_raw toggle

    hi.add_view(root, {
        flags   = { .text, .fill_x, .check },
        text    = "[ _ ] .text_raw",
        padding = 20,
        user_ptr= popup,
        on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
            if event.type == .selection_changed {
                popup := cast (^Popup) v.user_ptr
                if .selected in v.flags {
                    popup.ui_page_demo.flags += { .text_raw }
                    hi.set_text(v, "[ x ] .text_raw")
                } else {
                    popup.ui_page_demo.flags -= { .text_raw }
                    hi.set_text(v, "[ _ ] .text_raw")
                }
            }
            return
        },
        on_draw = _popup_draw_button_view,
    })

    // Font scaling

    @static
    Font_Scale_Options := [?] struct { text: string, scale: f32 } {
        { "60%", .6 },
        { "80%", .8 },
        { "100%", 1 },
        { "120%", 1.2 },
        { "140%", 1.4 },
    }

    hi.add_view(root, { flags={.text,.text_fit_x}, padding={20,20,20,0}, text="Font scale" })
    fs_bar := hi.add_view(root, { flags={ .fit_x, .fit_y }, layout={ dir=.row, align=.center }, padding=10 })
    for o, i in Font_Scale_Options {
        hi.add_view(fs_bar, {
            flags   = { .text, .text_fit_x, .radio } | (o.scale == 1 ? {.selected} : {}),
            text    = o.text,
            padding = 10,
            user_idx= i,
            on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
                if event.type == .selection_changed && .selected in v.flags {
                    o := &Font_Scale_Options[v.user_idx]
                    hi.set_ref_font_height(v.ctx, o.scale * APP_DEFAULT_FONT_HEIGHT)
                }
                return
            },
            on_draw = _popup_draw_button_view,
        })
    }

    // Panel width

    @static
    Panel_Width_Options := [?] struct { text: string, width: f32 /* Fixed if >1 and Ratio otherwise */ } {
        { "200px", 200 },
        { "300px", APP_DEFAULT_PANEL_WIDTH },
        { "30%", .3 },
        { "50%", .5 },
    }

    hi.add_view(root, { flags={.text,.text_fit_x}, padding={20,20,20,0}, text="Panel width" })
    pw_bar := hi.add_view(root, { flags={ .fit_x, .fit_y }, layout={ dir=.row, align=.center }, padding=10 })
    for o, i in Panel_Width_Options {
        hi.add_view(pw_bar, {
            flags   = { .text, .text_fit_x, .radio } | (o.width == APP_DEFAULT_PANEL_WIDTH ? {.selected} : {}),
            text    = o.text,
            padding = 10,
            user_idx= i,
            on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
                if event.type == .selection_changed && .selected in v.flags {
                    o := &Panel_Width_Options[v.user_idx]
                    app_apply_panels_width(o.width)
                }
                return
            },
            on_draw = _popup_draw_button_view,
        })
    }
}

_popup_setup_title :: proc (popup: ^Popup, file: ^os.File_Info) {
    strings.builder_reset(&popup.buf_title)
    hi.set_text(popup.ui_title, fmt.sbprintf(&popup.buf_title,
        "|s=huge||i=%v| %s",
        file.type,
        file.name,
    ))
}

_popup_setup_page_demo :: proc (popup: ^Popup, file: ^os.File_Info) {
    hi.scroll_to_start(popup.ui_page_demo.parent)
    strings.builder_reset(&popup.buf_demo)
    hi.set_text(popup.ui_page_demo, fmt.sbprintf(&popup.buf_demo,
        "Full file path is |c=#ff8|%s|c|. " +
        "File name with icon is |c=#f8f||i=%v| %s|c|. " +
        "File size is |c=#f88|%M|c| and its modified time is |c=#88f|%s|c|.\n" +
        "\n" +
        "File mode is |file_mode=%d|. " +
        "We can change colors and custom inline tokens are also automatically wraps. " +
        "Here is File mode again with larger font and different color: |s=large||c=#8ff|Mode is |file_mode=%d||c||s|. " +
        "The custom token for file mode is \"file_mode=%d\"\n" +
        "\n" +
        "|c=#069||divider||c|\n" +
        "\n" +
        "|center|This popup takes 50%% of width and 100%% of height. " +
        "Resize the app window to see automatic wrapping in action. " +
        "This paragraph starts and ends with custom token \"divider\" which occupies full line. " +
        "Like any other token, it can use any running style info, e.g. color, font, user state.\n|left|" +
        "\n" +
        "|c=#960||divider||c|\n" +
        "\n" +
        "|right|We can use different font heights on a same line, " +
        "each text token has |c=#0ff|baseline_ratio|c| for proper vertical alignment, " +
        "normal text uses current style font baseline, while custom tokens can override it.\n|left|" +
        "\n" +
        "|s=large|Mixing font sizes|s|\n" +
        "\n" +
        "111 222 333 444 555 Aaa Bbb Ccc Jjj Qqq Yyy Www " +
        "|s=tiny|Tiny |s|Normal |s=large|Large |s=huge|Huge " +
        "|s=large|Large |s|Normal |s=tiny|Tiny|s| " +
        "111 222 333 444 555 Aaa Bbb Ccc Jjj Qqq Yyy Www\n" +
        "\n" +
        "Press |c=#f0f|TAB|c| to enable Debug mode to see token baselines. " +
        "Any printed text line aligns all its token baselines in a strait line.\n" +
        "\n" +
        "|s=large|Mixing baselines|s|\n" +
        "\n" +
        "|tab=40||c=#888|a)|c|  F|b=index|n|b| = F|b=index|n-1|b| + F|b=index|n-2|b|\n" +
        "|tab=40||c=#888|b)|c|  A = [ A|b=index|1|b|, A|b=index|2|b|, A|b=index|2|b|, A|b=index|3|b|, ... ]\n" +
        "|tab=40||c=#888|c)|c|  B|b=index|avg|b| = ( B|b=index|min|b| + B|b=index|max|b| ) / 2\n" +
        "|tab=40||c=#888|d)|c|  z|b=super|2|b| = x|b=super|2|b| + y|b=super|2|b|\n" +
        "|tab=40||c=#888|e)|c|  e = mc|b=super|2|b|\n" +
        "\n" +
        "|s=large|Mixing text and views|s|\n" +
        "\n" +
        "You can click these buttons |button=plus_1k| |button=plus_100| |button=plus_10| and |button=plus_1| " +
        "to increment the number |counter=value|. These buttons do the opposite: " +
        "|button=minus_1| |button=minus_10| |button=minus_100| and |button=minus_1k|. " +
        "There are nine views involved above. " +
        "Enabled by |c=#ff8|.intext|c| flag and allows to bound a child view to a custom text token, " +
        "their solved rectangles will be kept synchronized in the following way:\n" +
        "|tab=40|- text token provides position\n" +
        "|tab=40|- bound view provides size\n" +
        "Resize window to see the wrapping in action. " +
        "The mouse click is consumed but the scrolling is propagated to the parent, " +
        "so whole text gets scrolled even when mouse cursor is above the inline view. " +
        "A view can manually consume the event if needed: the counter value does it for demo purposes, " +
        "e.g. when mouse hovers the counter, .wheeled event blocked and text scrolling doesn't work.",
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

    _popup_destroy_buf_texture(popup)
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
            core.bprint_int(b1[:], f_size),
            core.bprint_int(b2[:], len(popup.buf_bytes)),
        )
    case:
        popup.buf_bytes_used, err = os.read_full(f, popup.buf_bytes[:f_size])
        if err == nil do assert(i64(popup.buf_bytes_used) == f_size)
    }
}

_popup_draw_button_view :: proc (v: ^hi.Visible_View) {
    bg_color: [4] u8

    switch {
    case .radio in v.flags:
        // .radio button: show .hovered only if not .selected
        if .selected in v.flags     do bg_color = core.gray1
        else if .hovered in v.flags do bg_color = core.gray4
    case:
        // .check/normal button: always show .hovered
        if .selected in v.flags     do bg_color = core.gray1
        if .hovered in v.flags      do bg_color = core.gray4
    }

    k2.draw_rect(k2.Rect(v.solved_rect), bg_color)
    v.ctx.on_draw_text(v)
}
