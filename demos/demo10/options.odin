package demo10

import "core:encoding/json"
import "core:fmt"
import "spacelib:userfs"

Options :: struct {
    active_tab_idx      : int,
    show_fps            : bool,
    use_vsync           : bool,
    some_difficulty     : Options_Difficulty,
    some_quality        : Options_Quality,
    some_music_volume   : f32,
    some_sfx_volume     : f32,
}

Options_Difficulty  :: enum { story, easy, normal, hard }
Options_Quality     :: enum { auto, low, medium, high, ultra }

options_default := Options {
    active_tab_idx      = 0,
    show_fps            = false,
    use_vsync           = true,
    some_difficulty     = .normal,
    some_quality        = .auto,
    some_music_volume   = .5,
    some_sfx_volume     = .5,
}

options_file_name :: "options.json"

options: Options

options_load :: proc () {
    options = options_default
    bytes := userfs.read(options_file_name, context.temp_allocator)
    if bytes != nil {
        err := json.unmarshal(bytes, &options)
        fmt.ensuref(err == nil, "Failed to json.unmarshal(): %v", err)
    }
}

options_save :: proc () {
    bytes, err := json.marshal(options, allocator=context.temp_allocator)
    fmt.ensuref(err == nil, "Failed to json.marshal(): %v", err)
    userfs.write(options_file_name, bytes)
}
