package spacelib_clock

import "base:intrinsics"
import tm "core:time"
_ :: tm

Clock :: struct ($T: typeid) where intrinsics.type_is_float(T) {
    time        : T,
    time_scale  : T,
    tick_count  : int,

    _now        : tm.Time,
}

init :: proc (c: ^Clock($T)) {
    c^ = { time_scale=1, _now=tm.now() }
}

tick :: proc (c: ^Clock($T)) {
    c.tick_count += 1

    now := tm.now()
    dur := tm.diff(c._now, now)
    dt := f64(c.time_scale) * tm.duration_seconds(dur)
    c.time += T(dt)

    c._now = now
}
