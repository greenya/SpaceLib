package spacelib_raylib_res2

import "core:strings"
import rl "vendor:raylib"

import "spacelib:core"

Audio :: struct {
    name: string,
    info: union { rl.Music, rl.Sound },
}

create_audios :: proc (
    files           : [] File,
    file_extensions := [] string { ".wav", ".ogg", ".mp3" },
    created         : proc (a: ^Audio),
) {
    assert(created != nil)
    for file in files {
        dot_ext := core.string_suffix_from_slice(file.name, file_extensions)
        audio := strings.contains(file.name, ".music.")\
            ? create_audio_as_music(file, dot_ext)\
            : create_audio_as_sound(file, dot_ext)
        created(audio)
    }
}

destroy_audio :: proc (audio: ^Audio) {
    if audio == nil do return

    switch i in audio.info {
    case rl.Music: rl.UnloadMusicStream(i)
    case rl.Sound: rl.UnloadSound(i)
    }

    delete(audio.name)
    free(audio)
}

create_audio_as_music :: proc (file: File, dot_ext: string) -> ^Audio {
    dot_ext_cstr := strings.clone_to_cstring(dot_ext, context.temp_allocator)
    music_rl := rl.LoadMusicStreamFromMemory(dot_ext_cstr, raw_data(file.data), i32(len(file.data)))

    a := new(Audio)
    a.name = strings.clone(file.name[:strings.index_byte(file.name, '.')])
    a.info = music_rl
    return a
}

create_audio_as_sound :: proc (file: File, dot_ext: string) -> ^Audio {
    dot_ext_cstr := strings.clone_to_cstring(dot_ext, context.temp_allocator)
    wave_rl := rl.LoadWaveFromMemory(dot_ext_cstr, raw_data(file.data), i32(len(file.data)))
    sound_rl := rl.LoadSoundFromWave(wave_rl)
    rl.UnloadWave(wave_rl)

    a := new(Audio)
    a.name = strings.clone(file.name[:strings.index_byte(file.name, '.')])
    a.info = sound_rl
    return a
}
