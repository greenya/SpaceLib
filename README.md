# SpaceLib

* /clock                - clock with time scale support
* /core                 - core types and utility procs
* /raylib               - set of helpers when using Raylib
* /res                  - resources automation
* /sdl3                 - [planned] set of helpers when using SDL3
* /terse                - text layout calculation
* /tracking_allocator   - tracking allocator
* /tweens               - [planned] [maybe] tweening support
* /ui                   - ui manager

## TODOs

TODO: add slider support // maybe Actor_Slider_Thumb with { min=0, max=5, current=3 }

TODO: [?] maybe add support for Frame.drag: Drag_Proc (f: ^Frame, op: Drag_Operation) // enum: is_drag_target, dragging_started, dragging_now, dragging_ended, is_drop_target, dropping_now

TODO: [?] maybe add support for logic resolution 1280x720

TODO: [?] add UI.drawing_frames and .updating phase should fill it to be later used in .drawing phase
