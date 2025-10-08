package spacelib_raylib_res

import "core:thread"
import "core:time"
import rl "vendor:raylib"

// Common usage:
//
//      import res "spacelib:raylib/res"
//      main :: proc () {
//          bg_music := res.create_music_thread()
//          res.music_thread_play(...music audio...)
//          for !app_should_close {
//              music_thread_tick(bg_music)
//              ...
//          }
//          destroy_music_thread(bg_music)
//      }
//
// Note: if you're not building for JS, music_thread_tick() call can be skipped

Music_Thread :: struct {
    thread              : ^thread.Thread,
    thread_should_exit  : bool,
    thread_sleep_dur    : time.Duration,
    audio               : ^Audio,

    // storage for thread-local state; we do it like this to support thread-less targets (JS)
    _thread_state: struct {
        streaming_audio: ^Audio,
    },
}

create_music_thread :: proc () -> ^Music_Thread {
    mt := new(Music_Thread)

    when ODIN_OS != .JS {
        mt.thread = thread.create(music_thread_main)
        mt.thread.data = mt
        thread.start(mt.thread)
    }

    return mt
}

destroy_music_thread :: proc (mt: ^Music_Thread) {
    if mt == nil do return

    if mt.thread != nil {
        mt.thread_should_exit = true
        thread.join(mt.thread)
        thread.destroy(mt.thread)
    }

    free(mt)
}

music_thread_play :: proc (mt: ^Music_Thread, music_audio: ^Audio) {
    // we require "music only" because for sounds it will not be ok:
    // - sounds use different mechanism (no need for streaming),
    //   single call to rl.PlaySound() is enough
    // - sounds can be added many times before next update, so some kind of queue is needed
    // - we have thread_sleep_dur, which means the thread might not react for up to that duration,
    //   which can be an issue for sounds, as they should start playing as fast as possible
    //   (think of a gun shot etc.)

    _, ok := music_audio.info.(rl.Music)
    if !ok do panic("Audio must be music")

    mt.audio = music_audio
}

music_thread_tick :: proc (mt: ^Music_Thread) {
    if mt.thread == nil {
        music_thread_update(mt)
    }
}

@private
music_thread_update :: proc (mt: ^Music_Thread) {
    state := &mt._thread_state

    if mt.audio != state.streaming_audio {
        if state.streaming_audio != nil {
            stop_music(state.streaming_audio)
        }

        if mt.audio != nil {
            play_music(mt.audio)
        }

        state.streaming_audio = mt.audio
    }

    if state.streaming_audio != nil {
        update_music_stream(state.streaming_audio)
    }
}

@private
music_thread_main :: proc (t: ^thread.Thread) {
    mt := cast (^Music_Thread) t.data
    for !mt.thread_should_exit {
        music_thread_update(mt)
        time.sleep(mt.thread_sleep_dur)
    }
}
