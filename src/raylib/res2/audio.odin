package spacelib_raylib_res2

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Audio :: struct {
    info: union { rl.Music, rl.Sound },
}

create_audio :: proc (file: File, type: enum { auto, music, sound } = .auto) -> ^Audio {
    type := type
    if type == .auto {
        type = strings.contains(file.name, ".music.")\
            ? .music\
            : .sound
    }

    audio := new(Audio)

    dot_ext := file_dot_ext(file.name)
    fmt.assertf(dot_ext != "", "Audio file \"%s\" must contain extension", file.name)
    dot_ext_cstr := strings.clone_to_cstring(dot_ext, context.temp_allocator)

    #partial switch type {
    case .music:
        audio.info = rl.LoadMusicStreamFromMemory(dot_ext_cstr, raw_data(file.data), i32(len(file.data)))
    case .sound:
        wave_rl := rl.LoadWaveFromMemory(dot_ext_cstr, raw_data(file.data), i32(len(file.data)))
        audio.info = rl.LoadSoundFromWave(wave_rl)
        rl.UnloadWave(wave_rl)
    }

    return audio
}

destroy_audio :: proc (audio: ^Audio) {
    if audio == nil do return

    switch i in audio.info {
    case rl.Music: rl.UnloadMusicStream(i)
    case rl.Sound: rl.UnloadSound(i)
    }

    free(audio)
}
