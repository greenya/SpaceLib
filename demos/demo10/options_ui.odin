package demo10

import "core:fmt"
import "core:reflect"
import "spacelib:ui"

options_ui_add :: proc (tab_parent, content_parent: ^ui.Frame) {
    _, content := ui_add_tab_and_content(tab_parent, content_parent, "Options")

    bar := ui.add_frame(content, {
        layout=ui.Flow { dir=.right_center, gap=20, auto_size={.height} },
    })

    ui_add_checkbox(bar, "Show FPS", options.show_fps, click=proc (f: ^ui.Frame) {
        options.show_fps = f.selected
        options_save()
    })

    ui_add_checkbox(bar, "Use VSync", options.use_vsync, click=proc (f: ^ui.Frame) {
        options.use_vsync = f.selected
        app_update_vsync()
        options_save()
    })

    ui.add_frame(content, { size={0,20} })
    ui.add_frame(content, { flags={.terse,.terse_height}, text="Some Difficulty" })
    ui_add_enum_radio(content, options.some_difficulty, button_click=proc (f: ^ui.Frame) {
        value, ok := reflect.enum_from_name(Options_Difficulty, f.name)
        assert(ok)
        options.some_difficulty = value
        options_save()
    })

    ui.add_frame(content, { size={0,20} })
    ui.add_frame(content, { flags={.terse,.terse_height}, text="Some Quality" })
    ui_add_enum_radio(content, options.some_quality, button_click=proc (f: ^ui.Frame) {
        value, ok := reflect.enum_from_name(Options_Quality, f.name)
        assert(ok)
        options.some_quality = value
        options_save()
    })

    vol_ticks :: 11 // we want 10% volume steps: 0.0, 0.1 ... 1.0 -> 11 ticks in total

    ui.add_frame(content, { size={0,20} })
    ui.add_frame(content, { flags={.terse,.terse_height}, text="Some Music Volume" })
    ui_add_slider(content, idx=int(options.some_music_volume*vol_ticks), total=vol_ticks, thumb_click=proc (f: ^ui.Frame) {
        _, data := ui.actor_slider(f)
        options.some_music_volume = f32(data.idx)/f32(data.total-1)
        options_save()
    })

    ui.add_frame(content, { size={0,20} })
    ui.add_frame(content, { flags={.terse,.terse_height}, text="Some SFX Volume" })
    ui_add_slider(content, idx=int(options.some_sfx_volume*vol_ticks), total=vol_ticks, thumb_click=proc (f: ^ui.Frame) {
        _, data := ui.actor_slider(f)
        options.some_sfx_volume = f32(data.idx)/f32(data.total-1)
        options_save()
    })

    ui.add_frame(content, { size={0,20} })
    ui.add_frame(content, {
        flags={.terse,.terse_height},
        text=fmt.tprintf("<wrap,pad=8>The state stored in \"%s\".", options_file_name),
    })
}
