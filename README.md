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

TODO: [?] terse: add support for extra gap for a line, e.g. <gap=.8> should set gap for current line (0.8*font.height), default value is 0, the value is not transferred to next line (e.g. new line starts with gap=0); maybe do not parse float, just have predefined set of values: .1, .2, .3, .4, .5, .6, .7, .8, .9, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.5, 3.0, 4.0

TODO: [?] terse: maybe add support for optional icon size: <icon=title^1.75>, should use 1.75*font.height for icon size

TODO: [?] terse: maybe add support for nested groups? need to see good reason with example first

TODO: terse: add support for "image" command <image=title[:left][:right]>, add proc for query image size by name (Query_Image_Proc). Image should support alignment: center (default), left, right:
- when "center", the image starts with new line, positioned at the center, text continues after image from next new line
- when "left" or "right", image will stick to given size, text should flow on other size of the image, e.g. the image basically affects the following lines width, until image height end

TODO: res: sprite: add support for animations (Sprite.info variant)
    would be nice to support animation names, so its possible to express something like:
    draw_sprite(character_sprite.anim.seq["walk"], rect, tint)
    simple animation has single sequence named "default"

TODO: res: audio: add support for variations, e.g. book_flip-1, book_flip-2, book_flip-3 should be single sound "book_flip" with 3 variations; need thinking how to make it, but the idea is to use rl.PlaySound(app.res.sounds["bool_flip"]) and get random variation
    // [?] maybe we need "spacelib:raylib/audio" package to have "play_random(list: [] rl.Sound)"
    // ...maybe not // -- needs thinking
    // [?] maybe just load "book_flip-1" as "book_flip", and extend Sound struct to have
    // "variations: [dynamic] rl.Sound"; keep "using sound_rl" so its possible to just
    // rl.PlaySound() the Sound value directly.

TODO: ui: add support for automatic child frames generation for each text_terse.groups item
    // - Frame.name should be group name
    // - updating terse should handle child frames (add/remove/update)
    // - the idea is to be able to have enter/leave/click for any group in terse
    // - maybe we need to add Frame.draw/enter/leave/click_terse_group for handling events for those dynamic children

TODO: ui: add "wait=f32(0)" arg to ui.animate(),
    add Frame.anim.state (enum: none, waiting, animating)
    it should do: waiting (if wait>0) -> animating (for dur) -> ratio=0 -> ... ratio=1 -> none

TODO: ui: add support for wrapping items ("wrap=true") when using "layout"; rework "gap" and "pad" to be Vec2

TODO: ui: add slider support // maybe Actor_Slider_Thumb with { min=0, max=5, current=3 }

TODO: [?] ui: maybe add support for Frame.drag: Drag_Proc (f: ^Frame, op: Drag_Operation) // enum: is_drag_target, dragging_started, dragging_now, dragging_ended, is_drop_target, dropping_now

TODO: [?] ui: maybe add support for logic resolution 1280x720

TODO: [?] ui: add UI.drawing_frames and .updating phase should fill it to be later used in .drawing phase
