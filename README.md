# SpaceLib

* /clock                - clock with time scale support
* /core                 - core types and utility procs
* /events               - [planned] event bus
* /raylib               - helpers when using Raylib
* /sdl3                 - [planned] set of helpers when using SDL3
* /terse                - text layout calculation
* /tracking_allocator   - tracking allocator
* /tweens               - [planned] [maybe] tweening support
* /ui                   - ui manager

## TODOs

TODO: ui: add "wait=f32(0)" arg to ui.animate(),
          add Frame.anim.state (enum: none, waiting, animating)
          it should do: waiting (if wait>0) -> animating (for dur) -> ratio=0 -> ... ratio=1 -> none

TODO: ui: add support for wrapping items ("wrap=true") when using "layout"; rework "gap" and "pad" to be Vec2

TODO: ui: add slider support // maybe Actor_Slider_Thumb with { min=0, max=5, current=3 }

TODO: [?] ui: maybe add support for Frame.drag: Drag_Proc (f: ^Frame, op: Drag_Operation) // enum: is_drag_target, dragging_started, dragging_now, dragging_ended, is_drop_target, dropping_now

TODO: [?] ui: maybe add support for logic resolution 1280x720

TODO: [?] ui: add UI.drawing_frames and .updating phase should fill it to be later used in .drawing phase
