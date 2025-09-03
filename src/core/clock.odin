package spacelib_core

import "base:intrinsics"
import tm "core:time"
_ :: tm

Clock :: struct ($T: typeid) where intrinsics.type_is_float(T) {
    time        : T,
    time_scale  : T,
    dt          : T,
    tick        : int,
    _now        : tm.Tick,
}

clock_init :: proc (c: ^Clock($T)) {
    c^ = {
        time_scale  = 1,
        _now        = tm.tick_now(),
    }
}

clock_tick :: proc (c: ^Clock($T)) {
    c.tick += 1

    now := tm.tick_now()
    diff := tm.tick_diff(c._now, now)
    dt := f64(c.time_scale) * tm.duration_seconds(diff)
    c.dt = T(dt)
    c.time += c.dt

    c._now = now
}
