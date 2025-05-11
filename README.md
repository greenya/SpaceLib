# SpaceLib

* /assets               - [planned] assets automation
* /clock                - clock with time scale support
* /raylib               - set of helpers when using lib with Raylib
* /sdl3                 - [planned] set of helpers when using lib with SDL3
* /tracking_allocator   - simple tracking allocator
* /tweens               - [planned] tweening support (simpler version of core:math/ease with support for ^Rect)
* /ui                   - a retained mode ui library

## TODOs

TODO: add slider support // maybe Actor_Slider_Thumb with { min=0, max=5, current=3 }

TODO: [?] maybe add support for Frame.drag: Drag_Proc (f: ^Frame, op: Drag_Operation) // enum: is_drag_target, dragging_started, dragging_now, dragging_ended, is_drop_target, dropping_now

TODO: [?] maybe convert all Frame's bool fields // flags: bit_set [Flags]

TODO: [?] maybe add support for logic resolution 1280x720

TODO: add Manager.drawing_frames and .updating phase should fill it to be later used in .drawing phase
