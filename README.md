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

TODO: add support for HSL color format --- https://www.youtube.com/watch?v=vvPklRN0Tco

TODO: ui: rename current "pass" flag to "pass_self"; add support for "pass", which should act as "pass_self" for the frame itself and its children; note: if not effective algo, then maybe add ui.set_pass_frame_tree(f)

TODO: terse: add support for "non-breakable space" ("&nbsp;" in HTML); the idea is to be able to add in the middle of the text something like "Cost: 12 345." and be able to express that each word must be on the same like (e.g. breaking between "2" and "3" is most undesirable). Approaches i see:
    - rework <wrap>: add support for <nowrap>; should allow change wrap frag inline, e.g. <wrap> enables wrapping, <nowrap> disables it; make sure it works in a way that each word of text inside "<nowrap>Cost: 12 345.<wrap>" always on the same line
        p.s.: we also can make <wrap> to be a container command, e.g. "</wrap>Cost: 12 345.<wrap>" (assuming we have <wrap> before)
    - add support for <nowrap> command, inside it, all spaces treated as non-breakable, e.g. "<nowrap>Cost: 12 345.</nowrap>"
    - add support for <nbsp> command, will look ugly but most close to html and probably the easiest to implement, e.g. "Cost:<nbsp>12<nbsp>345."

TODO: terse: add ability to have a line with differently aligned parts -- ability to have a single line with text at left and at right, like in WOW's tooltips ("| Head <---> Leather |", "| Main Hand <---> Mace |")

TODO: terse: add support for "tab" (or "offset") command <tab=150>, which should take single integer, should generate empty word with needed width so following word will start at that horizontal pos (e.g. 150px from line.rect.x)

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

TODO: [?] terse: add support for "</>" command, should close last opened command, e.g. "font", "color" or "group"; probably will look unintuitive when opening multiple commands in single code, e.g. <font=f1,color=c1>...</>, we could close "color" in this case as its last, but now we introduce dependency on order of commands in the code... seems not nice

TODO: [?] terse: maybe add support for nested groups? need to see good reason with example first

TODO: [?] res: audio: maybe add support for variations, e.g. book_flip-1, book_flip-2, book_flip-3 should be single sound "book_flip" with 3 variations; need thinking how to make it, but the idea is to use rl.PlaySound(app.res.sounds["bool_flip"]) and get random variation
    // [?] maybe we need "spacelib:raylib/audio" package to have "play_random(list: [] rl.Sound)"
    // ...maybe not // -- needs thinking
    // [?] maybe just load "book_flip-1" as "book_flip", and extend Sound struct to have
    // "variations: [dynamic] rl.Sound"; keep "using sound_rl" so its possible to just
    // rl.PlaySound() the Sound value directly.
