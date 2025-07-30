# SpaceLib

    /core                       - core types and utilities
        /clock                  - clock with time scale support
        /stack                  - fixed size stack
        /timed_scope            - evaluate scope execution time
        /tracking_allocator     - memory allocation tracker
    /events                     - [planned] [maybe] event bus
    /raylib                     - helpers when using Raylib
    /sdl2 (3?)                  - [planned] helpers when using SDL
    /terse                      - text layout calculation
    /tweens                     - [planned] [maybe] tween manager
    /ui                         - ui manager

## TODOs

TODO: core: add support for HSL color format

    https://www.youtube.com/watch?v=vvPklRN0Tco

    - maybe consider changing Color to be [4]f32 instead of [4]u8, as we are doing a lot of alpha and brightness tweaking and every time we convert 4 values to f32 and back to u8

TODO: terse: add support for <overflow> command

    allow to have text fit to any size without need for scrollbar; very needed for dropdown boxes and similar limited space controls; at least to be able to use it for one liners (not wrapping text); ideally support two modes:
    - overflow=ellipsis: [default] should truncate whole word (or chars) and add "..." to the end
    - overflow=scrolling: should repeat smooth scrolling to the end (revealing whole text for reading) and faster to the start for repetition

TODO: terse: add ability to have a line with differently aligned parts -- ability to have a single line with text at left and at right, like in WOW's tooltips ("| Head <---> Leather |", "| Main Hand <---> Mace |")

TODO: terse: rework parse_f32, parse_int, parse_vec_i, parse_vec -- should be only parse_vec and parse f32, which just handle any f32 text value

TODO: terse: add support for "image" command

    Maybe <image=name[:left][:right]>, add proc for query image size by name (Query_Image_Proc). Image should support alignment: center (default), left, right:
        - when "center", the image starts with new line, positioned at the center, text continues after image from next new line
        - when "left" or "right", image will stick to given size, text should flow on other size of the image, e.g. the image basically affects the following lines width, until image height end

    [MAYBE] do not add "query" proc, but have format like: <image=name:200x200[:left][:right]> width and height are required, if width=0, the width will be input rect.w, if height=0 -- input rect.h

TODO: terse: investigate if text measuring of a word can be improved (performance wise) by caching font+text keys, so next time we measure same text with same font, we immediately know the size (Vec2)

TODO: ui: add slider support // maybe Actor_Slider_Thumb with { min=0, max=5, current=3 }

TODO: ui: Grid: support other directions

TODO: ui: support multiple callbacks for some events

    currently when we need to handle an event, we assign a callback, and if its already had some callback, that would just get replaced. Maybe we should add some way to add callbacks into list; maybe not for all, the draw and tick might be just pointers as they are called often (needs testing).

    callbacks:
        - called every frame if .hidden not_in f.flags:
            - tick
            - draw
            - draw_after
        - called on demand:
            - show
            - hide
            - enter
            - leave
            - click
            - wheel
            - drag (called every frame when f.captured)

    // this is how we could add "click" callback to some_frame without need of managing actual value of some_frame.click
    ui.on_click(some_frame, proc (f: ^ui.Frame) {
        // ...
    })

    // it would do something like: append(&f.click, click_proc)
    // and probably ensure() such callback is not in the list yet
    // click list should be like: Frame.click: [dynamic] Frame_Proc

    // extend arg list of add_frame() so it takes "click: Frame_Proc = nil", "enter:...", "leave:..." etc.
    // and will call proper on_xxx(); just like with set_anchors()

    maybe add some callback lists to the UI, so its possible to have global events, for example
        - on_ui_root_resize     // can be useful when frame want to support different layout depends on screen size
        - on_ui_capture_start
        - on_ui_capture_end
        - on_ui_click
        - on_ui_wheel
        - on_ui_drag

TODO: ui: key press handling

    The idea is to be able express frame handles "Esc" or "A" and when that happens, the frame gets "click". Ideally, we want to add all the structure, which will include multiple elements wanting "Esc" (or any other button), but the UI should automatically route "click" to correct one, checking visibility and hierarchy of the frame; it should be possible to open dialog which would close by "Esc" and the "Esc" is also visible below, as dialog has semitransparent layer and the tree is visible below. Any single key can be handled only be single frame at any time, e.g. even if we have tab bar with "Q" and "E" navigation and another tab bar with same keys is shown, only one should consume the key input.

TODO: ui: add global opacity handling

    ---- // also consider switching Color from [4] u8 to [4] f32, as we are doing a lot of alpha and brightness tweaks and every time we basically convert each component to f32 and back; and with this "global opacity" change, we will do it even more (well, only for one component... but for every drawing); test the speed of such change. // ----

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

TODO: ui: fix hover_ratio(): fix twitching for large duration and short enter/leave times

    maybe we should add a separate field -- Frame.hover: Hovering,

    Hovering :: struct {
        enter_ease  : core.Ease,
        enter_dur   : f32,
        leave_ease  : core.Ease,
        leave_dur   : f32,
        ratio       : f32,
    }

    in tick() check if f.hover.enter_dur != 0 && f.hover.enter_dur != 0 -- calc hover.ratio; no need to use buggy hover_ratio(), now we have hover.ratio value, and we can ensure it changes smoothly.

TODO: [?] ui: add support for cancelable animations, e.g. ui.cancel_animation(f), which should set ratio to -1, tick the animation and remove it

TODO: [?] ui: add "wait=f32(0)" arg to ui.animate(),
    add Frame.anim.state (enum: none, waiting, animating)
    it should do: waiting (if wait>0) -> animating (for dt) -> ratio=0 -> ... ratio=1 -> none

TODO: [?] ui: add support for automatic child frames generation for each text_terse.groups item

    - Frame.name should be group name
    - updating terse should handle child frames (add/remove/update)
    - the idea is to be able to have enter/leave/click for any group in terse
    - maybe we need to add Frame.draw/enter/leave/click_terse_group for handling events for those dynamic children

TODO: [?] ui: drag-n-drop frame info

    currently the dragged frame is always the one who has captured mouse; this means that no other frames receive any enter/leave events; now considered a scenario where we want to create an inventory with ability to drag-n-drop items. The item that got drag is fine, as it receives continuous drag callback; now, how can user get item below the dragged item, to highlight it or perform drop operation when drag is finished. at the moment, there is no other way (i don't see) as manually tinker with ui.mouse_frames list; but it would be nice to be able to express that some frame are drop targets;

    ideas:
    - add callback drop/drag_beat/drag_target/drop_target... something like that (?)
    - so the frame can be notified about other's drag activity

    - maybe we should just extend Drag_Info, so it has current hovering frame, and the drag callback can decide what to do with it. This seems better and in one place (the dragged frame has all logic; again, the drag callback will be the same for all inventory slots in most cases, so no issues there).

    - very nice if we could have a way for a group of frames to highlight itself as indication for a user that they are valid targets (like dragging a weapon from inventory, could highlight weapon slots on the character as valid targets); this is probably has nothing to do with drag-target, as the drag handler of the frame who is doing the drag, can ask those frames to highlight itself at phase==.start and ask to disable such highlight at the phase==.end of the drag.

TODO: [?] ui: maybe add support for logic resolution 1280x720

    maybe we don't need it, as its possible to do following:
        - always report needed resolution, regardless of actual, e.g. call ui.tick() with {0,0,1280,720}
        - when drawing, user can scale frame's rect to actual resolution

TODO: [?] ui: add UI.drawing_frames and .updating phase should fill it to be later used in .drawing phase

TODO: [?] ui: add support for template loading

    the idea is to reduce manual add_frame() calls and be able to describe ui in json (?), after its loaded (a tree), we need to hook draw, click etc.; each element could be retrieved by path (already supported). A template for simple dialog could look like below.

```json
{
    "name": "dialog",
    "size": [ 640, 0 ],
    "layout": {
        // this is Flow, but somehow loader should understand it
        "dir": "down",
        "pad": 30,
        "auto_size": [ "height" ],
        "anchors": [
            { "point": "center" }
        ]
    },
    "children": [
        {
            "name": "title",
            "flags": [ "terse", "terse_height" ],
            "text_format": "<wrap,pad=30,font=text_4m,color=primary_d2>%s"
        },
        {
            "name": "message",
            "flags": [ "terse", "terse_height" ],
            "text_format": "<wrap,font=text_4l,color=primary_d2>%s"
        },
        {
            "name": "buttons",
            "size": [ 0, 90 ],
            "layout": { // Flow
                "dir": "right_center",
                "gap": 20,
                "align": "end"
            },
            "children": [
                {
                    {
                        "name": "button_1",
                        "text_format": "<pad=12:6,font=text_4l,color=primary>%s",
                        "flags": [ "capture", "terse", "terse_size" ]
                    },
                    {
                        "name": "button_2",
                        "text_format": "<pad=12:6,font=text_4l,color=primary>%s",
                        "flags": [ "capture", "terse", "terse_size" ]
                    }
                }
            ]
        }
    ],
}
```

    the usage could be something like:

```odin
// hypothetical init (once)
dialog := ui.add_template(parent, "/* template text or simple loaded object is here */")
dialog.draw = draw_dialog_rect
for btn in ui.get(dialog, "buttons").children {
    btn.draw = draw_button
    btn.click = proc (f: ^ui.Frame) {
        fmt.printfln("%s was clicked!", f.name)
    }
}

// hypothetical use
ui.set_text(ui.get(dialog, "title"), "Quit Game?")
ui.set_text(ui.get(dialog, "message"), "Are you sure you want to quit?")
ui.set_text(ui.get(dialog, "buttons/button_1"), "Confirm")
ui.set_text(ui.get(dialog, "buttons/button_2"), "Cancel")
ui.show(dialog)
```

TODO: [?] terse: maybe add support for nested groups? need to see good reason with example first

-----------------------------------------
---- maybe remove raylib/res package ----
-----------------------------------------

TODO: raylib/res: when printing error about "Generate atlas texture failed: Unable to fit SPRITE", set its coords to lower right corner of the texture, so it will be like 1x1 of color (255,0,255,255) and should be visible on the screen

TODO: raylib/res: sprite: add support for animations (Sprite.info variant)

    would be nice to support animation names, so its possible to express something like:
    draw_sprite(character_sprite.anim.seq["walk"], rect, tint)
    simple animation has single sequence named "default"

TODO: [?] raylib/res: audio: maybe add support for variations

    e.g. book_flip-1, book_flip-2, book_flip-3 should be single sound "book_flip" with 3 variations; the idea is to use rl.PlaySound(app.res.sounds["bool_flip"]) and get random variation

    // [?] maybe we need "spacelib:raylib/audio" package to have "play_random(list: [] rl.Sound)"
    // ...maybe not
    // [?] maybe just load "book_flip-1" as "book_flip", and extend Sound struct to have
    // "variations: [dynamic] rl.Sound"; keep "using sound_rl" so its possible to just
    // rl.PlaySound() the Sound value directly.
