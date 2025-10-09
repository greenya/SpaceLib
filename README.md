# SpaceLib

    /core                       - core types and utilities
        /stack_trace            - debug stack trace
        /timed_scope            - evaluate scope execution time
        /tracking_allocator     - memory allocation tracker
    /events                     - [planned] [maybe] event bus
    /raylib                     - helpers when using Raylib
    /sdl2 (3?)                  - [planned] helpers when using SDL
    /terse                      - text layout calculation
    /tweens                     - [planned] [maybe] tween manager
    /ui                         - ui manager
    /userfs                     - user file system: save/load a file in user data dir or localStorage

## TODOs

TODO: userfs: expose error status

    maybe not, as i hardly believe somebody would handle the error properly;
    if in a web browser for some reason userfs fails, i guess the last thing we want to tell user about it;
    so maybe just silently do nothing (don't load or save), the app should act like nothing previously
    was saved and just use default preset, and any further writes will do nothing

    anyway; if added, the developer can decided to handle error or don't; at the moment there is no way to know
    that something went wrong

TODO: userfs: replace localStorage with indexedDB

TODO: terse: make line alignment to be stack-based (open and close) OR at least change line alignment when actual word is added

    the problem at the moment is that using "left", "right" or "center" immediately sets current line alignment;
    consider following formatting:

        Some text goes left aligned
        <center> -- this is already a new line
        centered text
        <left> -- another new line
        Left aligned text continues

    To have no line skips we need to write:

        Some text goes left aligned
        <center>centered text
        <left>Left aligned text continues

    Ugly and stupid :)

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

TODO: ui: fix hover_ratio(): fix twitching for large duration and short enter/leave times

    maybe we should add a separate field -- Frame.hover: Hovering,

    Hovering :: struct {
        enter_ease  : ease.Ease,
        enter_dur   : f32,
        leave_ease  : ease.Ease,
        leave_dur   : f32,
        ratio       : f32,
    }

    in tick() check if f.hover.enter_dur != 0 && f.hover.enter_dur != 0 -- calc hover.ratio; no need to use buggy hover_ratio(), now we have hover.ratio value, and we can ensure it changes smoothly.

TODO: [?] core: maybe consider changing Color to be 4 floats instead 4 bytes

    we are doing a lot of alpha and brightness tweaking and every time we convert 1-3 values to f32 and back to u8

TODO: [?] ui: slider actor: add track click handling

    maybe make it optional with some data.flag; clicking should set thumb to most close valid position;
    [?] if added, i guess scrollbar also needs it [?]

TODO: [?] ui: add support for automatic child frames generation for each text_terse.groups item

    - Frame.name should be group name
    - updating terse should handle child frames (add/remove/update)
    - the idea is to be able to have enter/leave/click for any group in terse
    - maybe we need to add Frame.draw/enter/leave/click_terse_group for handling events for those dynamic children

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
