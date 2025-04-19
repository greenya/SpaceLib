# SpaceLib

* /                     - a retained mode ui library
* /raylib               - set of helpers when using lib with Raylib
* /sdl3                 - [planned] set of helpers when using lib with SDL3
* /tracking_allocator   - simple tracking allocator
* /tweens               - [planned] tweening support (simpler version of core:math/ease with support for ^Rect)
* /ui                   - [planned] after code refactor, right now it is in the root (/)
* /utils                - [planned] after code refactor, all from root (/) not related directly to ui

## TODO

- code refactor: move all ui related stuff to /ui subdir (package)
- proj refactor: use collection:
    * build: odin run src/demo4 -collection:spacelib=../SpaceLib/src/spacelib -out:build/demo4.exe -debug -o:none
    * ols.json: "collections": [ { "name": "spacelib", "path": "../SpaceLib/src/spacelib" } ]

- add slider support // maybe Actor_Slider_Thumb with { min=0, max=5, current=3 }

- [?] maybe add support for Frame.drag: Drag_Proc (f: ^Frame, op: Drag_Operation) // enum: is_drag_target, dragging_started, dragging_now, dragging_ended, is_drop_target, dropping_now
- [?] maybe convert all Frame's bool fields // flags: bit_set [Flags]
- [?] maybe add support for logic resolution 1280x720

- improve Measured_Text, so its possible to split frame update and draw

// * currently when drawing text we update f.rect.h which is not nice
// * idea is to have Frame.text with all info for updating (measure) and drawing
// * rework /text.odin, maybe move to separate package /measured_text
// * add Manager.drawing_frames and .updating phase should fill it to be later used in .drawing phase

// * maybe use shorthands in the formatting text:
    "v" for "valign"
    "a" for "align"
    "f" for "font"
    "c" for "color"
    "i" for "icon"
    "g" for "group"

>>---- examples ----<<
* Your <group:spell#456>fireball</group> deals <icon:fire> <color:fire>17 damage</color> to <group:npc#123>The Monster Name</group> and <icon:stun> <group:spell#789>stuns</group> the target.
* Your <g:spell#456>fireball</g> deals <i:fire> <c:fire>17 damage</c> to <g:npc#123>The Monster Name</g> and <i:stun> <g:spell#789>stuns</g> the target.
* <i:hp> <c:hp>140</c> <i:mana> <c:mana>120</c>
* [maybe] <c:red>Hell</c>o

>>---- formatting per text ----<<
* <valign:top>  -- set valign (top, center, bottom)

>>---- formatting per line ----<<
* <align:left>  -- push align (left, center, right)
* </align>      -- pop align

>>---- formatting per word ----<<
* <font:name>   -- push font
* </font>       -- pop font
* <color:name>  -- push color
* </color>      -- pop color

>>---- extra ----<<
* " ... "       -- space (treat multiple spaces as single space), e.g. if word == "" do continue
* \n            -- line break
* <icon:name>   -- insert icon
                -- // Measured_Icon, Measured_Line.children: [dynamic] union { Measured_Word, Measured_Icon }
* <group:name>  -- start group
                -- // Measured_Text.groups, element should contain "name" and "words", a list of ^Measured_Word
* </group>      -- end group
                -- // each word in the group should also group name, e.g. Measured_Word.group

>>---- default (implicit) values ----<<
* <valign:top>
* <align:left>
* <font:default>
* <color:default>
