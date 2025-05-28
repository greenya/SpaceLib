package spacelib_raylib_res

import "core:strings"
import rl "vendor:raylib"
import "../../core"

Sound :: struct {
    name            : string,
    using sound_rl  : rl.Sound,
}

Music :: struct {
    name            : string,
    using music_rl  : rl.Music,
}

@private default_audio_file_ext_list :: [] string { ".ogg" }

load_audio :: proc (res: ^Res) {
    assert(len(res.sounds) == 0)
    assert(len(res.music) == 0)

    for file_name in core.map_keys_sorted(res.files, context.temp_allocator) {
        dot_ext := core.string_suffix_from_slice(file_name, default_audio_file_ext_list)
        if dot_ext == "" do continue

        if strings.contains(file_name, ".music.") {
            load_file_as_music(res, file_name, dot_ext)
        } else {
            load_file_as_sound(res, file_name, dot_ext)
        }
    }
}

@private
load_file_as_sound :: proc (res: ^Res, file_name, dot_ext: string) {
    file := res.files[file_name]
    dot_ext_cstr := strings.clone_to_cstring(dot_ext, context.temp_allocator)
    wave_rl := rl.LoadWaveFromMemory(dot_ext_cstr, raw_data(file.data), i32(len(file.data)))
    sound_rl := rl.LoadSoundFromWave(wave_rl)
    rl.UnloadWave(wave_rl)

    sound := new(Sound)
    sound.name = strings.clone(file_name[:strings.index_byte(file_name, '.')])
    sound.sound_rl = sound_rl

    res.sounds[sound.name] = sound
}

@private
load_file_as_music :: proc (res: ^Res, file_name, dot_ext: string) {
    file := res.files[file_name]
    dot_ext_cstr := strings.clone_to_cstring(dot_ext, context.temp_allocator)
    music_rl := rl.LoadMusicStreamFromMemory(dot_ext_cstr, raw_data(file.data), i32(len(file.data)))

    music := new(Music)
    music.name = strings.clone(file_name[:strings.index_byte(file_name, '.')])
    music.music_rl = music_rl

    res.music[music.name] = music
}

@private
destroy_sounds_and_music :: proc (res: ^Res) {
    for _, sound in res.sounds {
        rl.UnloadSound(sound.sound_rl)
        delete(sound.name)
        free(sound)
    }

    delete(res.sounds)
    res.sounds = nil

    for _, music in res.music {
        rl.UnloadMusicStream(music.music_rl)
        delete(music.name)
        free(music)
    }

    delete(res.music)
    res.music = nil
}
