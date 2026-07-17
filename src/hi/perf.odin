package hi

import "core:fmt"
import "core:time"
import "../core"

_ :: fmt
_ :: time
_ :: core

PERF_ON :: #config(HI_PERF, false)

when PERF_ON {

Perf_State :: struct {
    frame_start : time.Tick,
    track_starts: [_Perf_Counter] time.Tick,

    current : _Perf_Frame,
    frames  : [_PERF_MAX_FRAMES] _Perf_Frame,
    head    : int,
    count   : int,

    buf: [200] u8,
}

_Perf_Counter :: enum {
    update,         // Time spent in `update_context()`. This value includes `.solve` counter.

    solve,          // Time spent in `solve_context()` during the current perf frame. This is the sum of all calls to the procedure, as it can be called multiple times by the UI, and by the user directly from any event handler. The time includes `.text_total` counter.

    text_total,     // Time spent on text solving specifically. This value includes all other `.text_*` counters.
    text_tokenize,  // Time spent on tokenization of text strings
    text_measure,   // Time spent on tokens measurement
    text_wrap,      // Time spent on wrapping measured tokens

    draw,           // Time spent in `draw_context()`. This value includes other `.draw_*` counters. The debug drawing of each non-root view is included.
    draw_view,      // Time spent by all `View.on_draw()` calls from `draw_context()`
    draw_text,      // Time spent by fallback `Context.on_draw_text()` calls from `draw_context()`
}

_Perf_Frame :: struct {
    dur     : time.Duration,
    tracks  : [_Perf_Counter] _Perf_Track,
}

_Perf_Track :: struct {
    dur     : time.Duration,
    calls   : int,
}

_PERF_MAX_FRAMES :: 200

_PERF_UPDATE_COLOR      :: Color { 240, 160,  80, 255 }
_PERF_DRAW_COLOR        :: Color {  80, 180, 240, 255 }
_PERF_UNTRACKED_COLOR   :: Color {  70,  70,  70, 255 }
_PERF_REF_LINE_COLOR    :: Color { 255, 255, 255,  80 }

_perf_frame_start :: proc (ctx: ^Context) {
    ctx.perf.current = {}
    ctx.perf.frame_start = time.tick_now()
}

_perf_frame_stop :: proc (ctx: ^Context) {
    if ctx.perf.frame_start._nsec == 0 do return

    ctx.perf.current.dur = time.tick_since(ctx.perf.frame_start)
    ctx.perf.frames[ctx.perf.head] = ctx.perf.current
    ctx.perf.head = (ctx.perf.head + 1) % _PERF_MAX_FRAMES
    ctx.perf.count = min(ctx.perf.count + 1, _PERF_MAX_FRAMES)
    ctx.perf.frame_start = {}
}

_perf_start :: time.tick_now

_perf_track_start :: proc (ctx: ^Context, counter: _Perf_Counter) {
    assert(ctx.perf.track_starts[counter]._nsec == 0)
    ctx.perf.track_starts[counter] = _perf_start()
}

_perf_track_stop :: proc (ctx: ^Context, counter: _Perf_Counter) {
    since := ctx.perf.track_starts[counter]
    ctx.perf.track_starts[counter] = {}
    _perf_stop(ctx, counter, since)
}

_perf_stop :: proc (ctx: ^Context, counter: _Perf_Counter, since: time.Tick) {
    if since._nsec == 0 do return

    track := &ctx.perf.current.tracks[counter]
    track.dur += time.tick_since(since)
    track.calls += 1
}

_perf_draw :: proc (ctx: ^Context) #no_bounds_check {
    if ctx.debug_draw_line == nil do return
    if ctx.perf.count == 0 do return

    graph_rect_w :: f32(_PERF_MAX_FRAMES)
    graph_rect_h :: 80
    text_rect_w  :: 260
    text_rect_h  :: 120

    graph_rect := Rect {
        x = 5,
        y = ctx.screen_size.y - graph_rect_h - text_rect_h - 5 - 5,
        w = graph_rect_w,
        h = graph_rect_h,
    }

    avg_ms: f64
    max_ms: f64
    max_dur: time.Duration

    for i in 0..<ctx.perf.count {
        frame := _perf_frame(ctx, i)
        frame_ms := time.duration_milliseconds(frame.dur)
        avg_ms += frame_ms
        max_ms = max(max_ms, frame_ms)
        max_dur = max(max_dur, frame.dur)
    }

    avg_ms /= f64(ctx.perf.count)

    graph_full_rect := graph_rect
    graph_full_rect.w += 60
    _debug_draw_rect_filled(ctx, graph_full_rect, _DEBUG_BG_COLOR)

    for i in 0..<ctx.perf.count {
        x := graph_rect.x + f32(i)
        frame       := _perf_frame(ctx, i)
        frame_h     := _perf_graph_height(frame.dur, max_dur, graph_rect_h)
        update_h    := _perf_graph_height(frame.tracks[.update].dur, max_dur, graph_rect_h)
        draw_h      := _perf_graph_height(frame.tracks[.draw].dur, max_dur, graph_rect_h)
        untracked_h := max(0, frame_h - update_h - draw_h)

        y := graph_rect.y + graph_rect_h

        _debug_draw_line(ctx, {x, y}, {x, y - update_h}, 1, _PERF_UPDATE_COLOR)
        y -= update_h

        _debug_draw_line(ctx, {x, y}, {x, y - draw_h}, 1, _PERF_DRAW_COLOR)
        y -= draw_h

        _debug_draw_line(ctx, {x, y}, {x, y - untracked_h}, 1, _PERF_UNTRACKED_COLOR)
    }

    ref_lines_drawn: int
    for line in ([?] struct { dur: time.Duration, label: string } {
        { time.Millisecond * 100, "100ms" },
        { time.Millisecond * 50, "50ms" },
        { time.Millisecond * 30, "30ms" },
        { time.Millisecond * 20, "20ms" },
        { time.Millisecond * 10, "10ms" },
        { time.Millisecond * 5, "5ms" },
        { time.Millisecond * 2, "2ms" },
        { time.Millisecond * 1, "1ms" },
        { time.Millisecond / 2, "0.5ms" },
        { time.Millisecond / 5, "0.2ms" },
        { time.Millisecond / 10, "0.1ms" },
    }) {
        if line.dur > max_dur do continue
        _perf_draw_ref_line(ctx, graph_rect, max_dur, line.dur, line.label)
        ref_lines_drawn += 1
        if ref_lines_drawn == 2 do break
    }

    latest := _perf_frame(ctx, ctx.perf.count - 1)
    untracked := _perf_untracked(latest)
    text := fmt.bprintf(ctx.perf.buf[:],
        "frame %.2fms avg %.2f max %.2f\n" +
        "+ update %.2fms\n" +
        "    + solve %.2fms (%i)\n" +
        "    + text %.2fms (%.2f %.2f %.2f)\n" +
        "+ draw %.2fms\n" +
        "+ untracked %.2fms",
        time.duration_milliseconds(latest.dur), avg_ms, max_ms,
        time.duration_milliseconds(latest.tracks[.update].dur),
        time.duration_milliseconds(latest.tracks[.solve].dur),
            latest.tracks[.solve].calls,
        time.duration_milliseconds(latest.tracks[.text_total].dur),
            time.duration_milliseconds(latest.tracks[.text_tokenize].dur),
            time.duration_milliseconds(latest.tracks[.text_measure].dur),
            time.duration_milliseconds(latest.tracks[.text_wrap].dur),
        time.duration_milliseconds(latest.tracks[.draw].dur),
        time.duration_milliseconds(untracked),
    )
    text_rect := Rect {
        x = graph_rect.x,
        y = graph_rect.y + graph_rect_h + 5,
        w = text_rect_w,
        h = text_rect_h,
    }
    _debug_draw_rect_filled(ctx, text_rect, _DEBUG_BG_COLOR)
    _debug_draw_text(ctx, text, { text_rect.x, text_rect.y }, _DEBUG_STATS_COLOR)
}

@require_results
_perf_frame :: proc (ctx: ^Context, i: int) -> _Perf_Frame {
    assert(i >= 0 && i < ctx.perf.count)
    oldest := ctx.perf.head - ctx.perf.count
    if oldest < 0 do oldest += _PERF_MAX_FRAMES
    return ctx.perf.frames[(oldest + i) % _PERF_MAX_FRAMES]
}

@require_results
_perf_untracked :: proc (frame: _Perf_Frame) -> time.Duration {
    tracked := frame.tracks[.update].dur + frame.tracks[.draw].dur
    if tracked >= frame.dur do return 0
    return frame.dur - tracked
}

@require_results
_perf_graph_height :: proc (dur, max_dur: time.Duration, graph_h: f32) -> f32 {
    if max_dur <= 0 do return 0
    return f32(f64(graph_h) * time.duration_milliseconds(dur) / time.duration_milliseconds(max_dur))
}

_perf_draw_ref_line :: proc (ctx: ^Context, graph_rect: Rect, max_dur, ref_dur: time.Duration, label: string) {
    if ref_dur > max_dur do return

    h := graph_rect.h * f32(time.duration_milliseconds(ref_dur) / time.duration_milliseconds(max_dur))
    y := graph_rect.y + graph_rect.h - h
    _debug_draw_line(ctx, { graph_rect.x, y }, { graph_rect.x + graph_rect.w + 4, y }, 1, _PERF_REF_LINE_COLOR)
    _debug_draw_text(ctx, label, { graph_rect.x + graph_rect.w + 4, y - 10 }, _PERF_REF_LINE_COLOR)
}

} else {

Perf_State :: struct {}

}
