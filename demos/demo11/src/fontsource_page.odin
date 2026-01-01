package main

import "core:encoding/json"
import "core:fmt"
import "spacelib:ui"
import "spacelib:userhttp"

Fontsource_Page :: struct {
    ui_reload       : ^ui.Frame,
    ui_fonts        : ^ui.Frame,
}

fontsource_page: Fontsource_Page

add_fontsource_page :: proc () {
    _, page_content := app_add_tab("Fontsource")

    ui.add_frame(page_content, {
        flags   = {.terse,.terse_height},
        text    = "<wrap,top,left,font=text_4r,color=white>" +
                "This example demonstrates usage of the Fontsource REST API.",
    })

    bar := ui.add_frame(page_content, {
        layout = ui.Flow { dir=.right, gap=20, auto_size={.height} },
    })

    fontsource_page.ui_reload = ui.add_frame(bar, {
        flags   = {.terse,.terse_size,.capture},
        text    = "<pad=20:10,font=text_4r,color=white>Reload font list",
        draw    = draw_button,
        click   = fontsource_page_reload_click,
    })

    ui.add_frame(bar, {
        flags   = {.terse,.terse_size,.capture},
        text    = "<pad=20:10,font=text_4r,color=white>Reset font",
        draw    = draw_button,
        click   = proc (f: ^ui.Frame) { reload_fonts() },
    })

    fontsource_page.ui_fonts = ui.add_frame(page_content, {
        layout = ui.Grid { dir=.right_down, size={240,100}, gap=16, auto_size={.height} },
    })
}

fontsource_page_reload_click :: proc (f: ^ui.Frame) {
    assert(f == fontsource_page.ui_reload)

    fontsource_page.ui_reload.flags += { .disabled }

    Result      :: [] Result_Row
    Result_Row  :: struct {
        id      : string,
        family  : string,
        category: string,
    }

    userhttp.send_request({
        url     = "https://api.fontsource.org/v1/fonts",
        ready   = proc(req: ^userhttp.Request) {
            fontsource_page.ui_reload.flags -= { .disabled }
            log_request(req)

            if req.error != nil {
                log("Listing fonts failed:", userhttp.request_state_text(req, context.temp_allocator))
                return
            }

            result: Result
            json_err := json.unmarshal(req.response.content, &result, allocator=context.temp_allocator)
            if json_err != nil {
                log("Failed to json.unmarshal():", json_err)
                return
            }

            ui.destroy_frame_children(fontsource_page.ui_fonts)
            for row, _ in result {
                fontsource_page_add_font_card(id=row.id, family=row.family, category=row.category)
            }
        },
    })
}

fontsource_page_add_font_card :: proc (id, family, category: string) {
    ui.add_frame(fontsource_page.ui_fonts, {
        name    = id,
        flags   = {.terse,.capture},
        text    = fmt.tprintf(
            "<pad=12:8,wrap,font=text_4r,color=white>%s\n<color=turquoise>(%s)</>",
            family, category,
        ),
        draw    = draw_button,
        click   = fontsource_page_font_card_click,
    })
}

fontsource_page_font_card_click :: proc (f: ^ui.Frame) {
    Result :: struct {
        variants: struct {
            _400: struct {
                normal: struct {
                    latin: struct {
                        url: struct {
                            ttf: string,
                        },
                    },
                },
            } `json:"400"`,
        },
    }

    userhttp.send_request({
        url     = fmt.tprintf("https://api.fontsource.org/v1/fonts/%s", f.name),
        ready   = proc(req: ^userhttp.Request) {
            log_request(req)

            if req.error != nil {
                log("Getting font failed:", userhttp.request_state_text(req, context.temp_allocator))
                return
            }

            result: Result
            json_err := json.unmarshal(req.response.content, &result, allocator=context.temp_allocator)
            if json_err != nil {
                log("Failed to json.unmarshal():", json_err)
                return
            }

            ttf_url := result.variants._400.normal.latin.url.ttf
            if ttf_url == "" {
                log("Failed to detect URL of the TTF file, please choose another font")
                return
            }

            fontsource_page_load_ttf(ttf_url)
        },
    })
}

fontsource_page_load_ttf :: proc (ttf_url: string) {
    userhttp.send_request({
        url     = ttf_url,
        ready   = proc (req: ^userhttp.Request) {
            log_request(req)

            if req.error != nil {
                log("Getting TTF file failed:", userhttp.request_state_text(req, context.temp_allocator))
                return
            }

            reload_fonts(use_my_bytes=req.response.content)
        },
    })
}
