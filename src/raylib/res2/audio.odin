package spacelib_raylib_res2

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Audio :: struct {
    info: union { rl.Music, rl.Sound },
}

@require_results
create_audio :: proc (file: File, type: enum { auto, music, sound } = .auto) -> ^Audio {
    type := type
    if type == .auto {
        type = strings.contains(file.name, ".music.")\
            ? .music\
            : .sound
    }

    audio := new(Audio)

    dot_ext := file_dot_ext(file.name)
    fmt.assertf(dot_ext != "", "Audio file \"%s\" must have extension", file.name)
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

play_music          :: proc (audio: ^Audio)             { rl.PlayMusicStream(rl_music(audio)) }
stop_music          :: proc (audio: ^Audio)             { rl.StopMusicStream(rl_music(audio)) }
pause_music         :: proc (audio: ^Audio)             { rl.PauseMusicStream(rl_music(audio)) }
resume_music        :: proc (audio: ^Audio)             { rl.ResumeMusicStream(rl_music(audio)) }
seek_music          :: proc (audio: ^Audio, pos: f32)   { rl.SeekMusicStream(rl_music(audio), pos) }
is_music_playing    :: proc (audio: ^Audio) -> bool     { return rl.IsMusicStreamPlaying(rl_music(audio)) }
update_music_stream :: proc (audio: ^Audio)             { rl.UpdateMusicStream(rl_music(audio)) }
set_music_vol       :: proc (audio: ^Audio, vol: f32)   { rl.SetMusicVolume(rl_music(audio), vol) }
set_music_pitch     :: proc (audio: ^Audio, pitch: f32) { rl.SetMusicPitch(rl_music(audio), pitch) }
set_music_pan       :: proc (audio: ^Audio, pan: f32)   { rl.SetMusicPan(rl_music(audio), pan) }
music_len           :: proc (audio: ^Audio) -> f32      { return rl.GetMusicTimeLength(rl_music(audio)) }
music_played        :: proc (audio: ^Audio) -> f32      { return rl.GetMusicTimePlayed(rl_music(audio)) }

play_sound          :: proc (audio: ^Audio)             { rl.PlaySound(rl_sound(audio)) }
stop_sound          :: proc (audio: ^Audio)             { rl.StopSound(rl_sound(audio)) }
pause_sound         :: proc (audio: ^Audio)             { rl.PauseSound(rl_sound(audio)) }
resume_sound        :: proc (audio: ^Audio)             { rl.ResumeSound(rl_sound(audio)) }
is_sound_playing    :: proc (audio: ^Audio) -> bool     { return rl.IsSoundPlaying(rl_sound(audio)) }
set_sound_vol       :: proc (audio: ^Audio, vol: f32)   { rl.SetSoundVolume(rl_sound(audio), vol) }
set_sound_pitch     :: proc (audio: ^Audio, pitch: f32) { rl.SetSoundPitch(rl_sound(audio), pitch) }
set_sound_pan       :: proc (audio: ^Audio, pan: f32)   { rl.SetSoundPan(rl_sound(audio), pan) }

@private
rl_music :: #force_inline proc (audio: ^Audio) -> rl.Music {
    #partial switch info in audio.info {
    case rl.Music   : return info
    case            : panic("Audio is not music")
    }
}

@private
rl_sound :: #force_inline proc (audio: ^Audio) -> rl.Sound {
    #partial switch info in audio.info {
    case rl.Sound   : return info
    case            : panic("Audio is not sound")
    }
}
