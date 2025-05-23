package spacelib_raylib_res

import "core:strings"
import rl "vendor:raylib"
import "../../core"

Sound :: struct {
    name            : string,
    using sound_rl  : rl.Sound,
}

@private default_sound_file_ext_list :: [] string { ".ogg" }

load_sounds :: proc (res: ^Res) {
    assert(len(res.sounds) == 0)

    for file_name in core.map_keys_sorted(res.files, context.temp_allocator) {
        file_ext := core.string_suffix_from_slice(file_name, default_sound_file_ext_list)
        if file_ext == "" do continue

        file := res.files[file_name]
        file_ext_cstr := strings.clone_to_cstring(file_ext, context.temp_allocator)
        wave_rl := rl.LoadWaveFromMemory(file_ext_cstr, raw_data(file.data), i32(len(file.data)))
        sound_rl := rl.LoadSoundFromWave(wave_rl)
        rl.UnloadWave(wave_rl)

        sound := new(Sound)
        sound.name = strings.clone(file_name[:strings.index_byte(file_name, '.')])
        sound.sound_rl = sound_rl

        res.sounds[sound.name] = sound
    }
}

@private
destroy_sounds :: proc (res: ^Res) {
    for _, sound in res.sounds {
        rl.UnloadSound(sound.sound_rl)
        delete(sound.name)
        free(sound)
    }

    delete(res.sounds)
    res.sounds = nil
}
