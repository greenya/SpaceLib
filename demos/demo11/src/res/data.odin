package res

import "core:fmt"
import "core:strings"

Data :: struct {
    urls: map [string] string,
}

@private data: Data

@private
create_data :: proc () {
    data.urls = make(map [string] string)

    data.urls["link_demo"]          = "https://github.com/greenya/SpaceLib/tree/main/demos/demo11"
    data.urls["link_userhttp"]      = "https://github.com/greenya/SpaceLib/tree/main/src/userhttp"
    data.urls["link_curl"]          = "https://github.com/odin-lang/Odin/tree/master/vendor/curl"
    data.urls["link_fetch_api"]     = "https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API"

    data.urls["link_github_limits"] = "https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api"

    data.urls["link_asset_font"]    = "https://fonts.google.com/specimen/Lustria"
    data.urls["link_asset_palette"] = "https://lospec.com/palette-list/neon-space"
}

@private
destroy_data :: proc () {
    delete(data.urls)
}

url :: #force_inline proc (name: string, allocator := context.allocator) -> (result: string, was_allocation: bool) #optional_ok {
    for known_prefix in ([?] struct { prefix, url_template: string } {
        { "link_github_user_"   , "https://github.com/%s" },
        { "link_github_commit_" , "https://github.com/odin-lang/Odin/commit/%s" },
    }) {
        if strings.has_prefix(name, known_prefix.prefix) {
            value := name[len(known_prefix.prefix):]
            return fmt.aprintf(known_prefix.url_template, value, allocator=allocator), true
        }
    }

    fmt.assertf(name in data.urls, "Unknown URL \"%s\"", name)
    return data.urls[name], false
}
