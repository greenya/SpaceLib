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
    data.urls["link_github_limits"] = "https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api"
    data.urls["link_font"]          = "https://fonts.google.com/specimen/Lustria"
    data.urls["link_palette"]       = "https://lospec.com/palette-list/neon-space"
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
