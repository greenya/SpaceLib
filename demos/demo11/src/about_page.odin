package main

import "spacelib:ui"

about_page_add :: proc () {
    tab_button, page_content := app_add_tab("About")
    ui.set_name(tab_button, "about") // we set name to preselect this tab (click it by name)

    when ODIN_OS == .JS {
        current_build_msg :: "++ This is a web build ++"
    } else {
        current_build_msg :: "++ This is a desktop build ++"
    }

    ui.add_frame(page_content, {
        flags   = {.terse,.terse_height},
        text    = "<wrap,top,left,font=text_4r,color=white>" +
                "The <color=amber>userhttp</> package allows sending HTTP requests " +
                "both in a web browser and in a desktop environment. On desktop, it uses " +
                "<group=link_curl>cURL</>, while on the web it relies on the browser's " +
                "<group=link_fetch_api>Fetch API</>.\n" +
                "\n" +
                "The implementation is asynchronous and aimed to be easily used in scenarios " +
                "like a main/game/rendering loop where you call \"update\" procedure from time " +
                "to time and expect no lags or stutters. The small animation in the bottom left " +
                "corner is added for demonstration purposes. It is expected to not freeze nor lag " +
                "nor stutter at any given moment.\n" +
                "\n" +
                current_build_msg + "\n" +
                "\n" +
                "<group=link_userhttp>Open userhttp Package Source Code</>\n" +
                "<group=link_demo>Open This Demo Source Code</>\n" +
                "\n" +
                "This demo uses following assets:\n" +
                "- <group=link_asset_font>Lustria font by MADType</>\n" +
                "- <group=link_asset_palette>Neon Space palette by Jimison3</>\n" +
                "\n" +
                "\\<-- Click the buttons to see usage examples!",
    })
}
