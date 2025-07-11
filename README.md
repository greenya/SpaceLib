# SpaceLib

* /clock                - clock with time scale support
* /core                 - core types and utility procs
* /events               - [planned] [maybe] event bus
* /raylib               - helpers when using Raylib
* /sdl3                 - [planned] set of helpers when using SDL3
* /terse                - text layout calculation
* /tracking_allocator   - tracking allocator
* /tweens               - [planned] [maybe] tweening support
* /ui                   - ui manager

## TODOs

TODO: add support for HSL color format --- https://www.youtube.com/watch?v=vvPklRN0Tco

TODO: terse: add support for <overflow> command

    allow to have text fit to any size without need for scrollbar; very needed for dropdown boxes and similar limited space controls; at least to be able to use it for one liners (not wrapping text); ideally support two modes:
    - overflow=ellipsis: [default] should truncate whole word (or chars) and add "..." to the end
    - overflow=scrolling: should repeat smooth scrolling to the end (revealing whole text for reading) and faster to the start for repetition

TODO: terse: add ability to have a line with differently aligned parts -- ability to have a single line with text at left and at right, like in WOW's tooltips ("| Head <---> Leather |", "| Main Hand <---> Mace |")

TODO: terse: add ability to have "<" and ">" in the text as part of the content, probably should support something like "<<test>>" which should give "<test>" as a text for displayed (not interpreted as code sequence)

TODO: terse: rework parse_f32, parse_int, parse_vec_i, parse_vec -- should be only parse_vec and parse f32, which just handle any f32 text value

TODO: terse: add support for "image" command <image=name[:left][:right]>, add proc for query image size by name (Query_Image_Proc). Image should support alignment: center (default), left, right:
- when "center", the image starts with new line, positioned at the center, text continues after image from next new line
- when "left" or "right", image will stick to given size, text should flow on other size of the image, e.g. the image basically affects the following lines width, until image height end
[MAYBE] do not add "query" proc, but have format like: <image=name:200x200[:left][:right]> width and height are required, if width=0, the width will be input rect.w, if height=0 -- input rect.h

TODO: terse: investigate if text measuring of a word can be improved (performance wise) by caching font+text keys, so next time we measure same text with same font, we immediately know the size (Vec2)

TODO: draw.texture() should take arg of enum { .fill (default), .contain/fit, .cover }. The idea is to have it like this https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit, e.g.:
    - .fill -- draw src rect -> dest rect
    - .fit -- aspect-ratio aware fit into dest rect
    - .cover -- aspect ratio aware cover dest rect
    p.s.: use center alignment always OR add additional enum arg { .center (default), .start, .end }

TODO: res: when printing error about "Generate atlas texture failed: Unable to fit SPRITE", set its coords to lower right corner of the texture, so it will be like 1x1 of color (255,0,255,255) and should be visible on the screen

TODO: res: sprite: add support for animations (Sprite.info variant)
    would be nice to support animation names, so its possible to express something like:
    draw_sprite(character_sprite.anim.seq["walk"], rect, tint)
    simple animation has single sequence named "default"

TODO: ui: [maybe] add support for "size_ratio"

    just like "size", but allows to set size relative to parent.rect.w/h in ratio; if set, has priority over "size" field ("size" is ignored)

TODO: ui: key press handling

    The idea is to be able express frame handles "Esc" or "A" and when that happens, the frame gets "click". Ideally, we want to add all the structure, which will include multiple elements wanting "Esc" (or any other button), but the UI should automatically route "click" to correct one, checking visibility and hierarchy of the frame; it should be possible to open dialog which would close by "Esc" and the "Esc" is also visible below, as dialog has semitransparent layer and the tree is visible below. Any single key can be handled only be single frame at any time, e.g. even if we have tab bar with "Q" and "E" navigation and another tab bar with same keys is shown, only one should consume the key input.

TODO: ui: add global opacity handling

    The idea is to allow any frame drawing function to not worry about f.opacity, as long as any drawing is done using raylib/draw.* procs. A lot of calls like "core.alpha(..., f.opacity)" should be possible to get rid of. In case when some manual drawing needed directly using Raylib, the actual opacity can be read using draw.opacity().

    The following steps i see needs to be done:

    - raylib/draw & terse:
        - add set_opacity(f32), opacity() -> f32, @private _opacity := f32(1)
        - every drawing proc (shapes and text) should tweak alpha of the color before drawing, maybe something like:
            color_rl := rl.Color(core.alpha(color, _opacity))
        - remove Terse.opacity, i guess we don't need it anymore
    - ui:
        - ui.create() should allow optional opacity set proc, so the ui creating can be extended with:
            opacity_set_proc = proc (o: f32) {
                draw.set_opacity(o)
            },
        - after drawing frame tree, reset opacity to 1, something like:
            if f.ui.opacity_set_proc != nil do f.ui.opacity_set_proc(1)
        - inside frame drawing, before any drawing we set frame' opacity, like:
            if f.ui.opacity_set_proc != nil do f.ui.opacity_set_proc(f.opacity)
        - notes:
            * we do not use opacity stack, as we expect to set opacity for every frame
            * we always restore opacity to 1.0; this should be fine, but if not, then we need to add f.ui.opacity_get_proc() and save the value to restore it after the drawing; lets keep blind 1.0 for now

TODO: ui: add support for cancelable animations, e.g. ui.cancel_animation(f), which should set ratio to -1, tick the animation and remove it

TODO: ui: add "wait=f32(0)" arg to ui.animate(),
    add Frame.anim.state (enum: none, waiting, animating)
    it should do: waiting (if wait>0) -> animating (for dt) -> ratio=0 -> ... ratio=1 -> none

TODO: ui: add support for wrapping items ("wrap=true") when using "layout"; rework "gap" and "pad" to be Vec2

TODO: ui: add slider support // maybe Actor_Slider_Thumb with { min=0, max=5, current=3 }

TODO: [?] ui: add support for automatic child frames generation for each text_terse.groups item
    // - Frame.name should be group name
    // - updating terse should handle child frames (add/remove/update)
    // - the idea is to be able to have enter/leave/click for any group in terse
    // - maybe we need to add Frame.draw/enter/leave/click_terse_group for handling events for those dynamic children

TODO: [?] ui: maybe add support for Frame.drag: Drag_Proc (f: ^Frame, op: Drag_Operation) // enum: is_drag_target, dragging_started, dragging_now, dragging_ended, is_drop_target, dropping_now

TODO: [?] ui: maybe add support for logic resolution 1280x720

TODO: [?] ui: add UI.drawing_frames and .updating phase should fill it to be later used in .drawing phase

TODO: [?] terse: maybe add support for nested groups? need to see good reason with example first

TODO: [?] res: audio: maybe add support for variations, e.g. book_flip-1, book_flip-2, book_flip-3 should be single sound "book_flip" with 3 variations; need thinking how to make it, but the idea is to use rl.PlaySound(app.res.sounds["bool_flip"]) and get random variation
    // [?] maybe we need "spacelib:raylib/audio" package to have "play_random(list: [] rl.Sound)"
    // ...maybe not // -- needs thinking
    // [?] maybe just load "book_flip-1" as "book_flip", and extend Sound struct to have
    // "variations: [dynamic] rl.Sound"; keep "using sound_rl" so its possible to just
    // rl.PlaySound() the Sound value directly.
