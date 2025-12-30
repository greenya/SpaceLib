package res

import "spacelib:terse"

ASSETS_PATH :: "../../assets"

init :: proc () {
    create_colors()
    create_fonts()

    terse.query_font    = proc (name: string) -> ^terse.Font    { return font_by_name(name) }
    terse.query_color   = proc (name: string) -> Color          { return color_by_name(name) }
}

destroy :: proc () {
    destroy_colors()
    destroy_fonts()

    terse.query_font    = nil
    terse.query_color   = nil
}
