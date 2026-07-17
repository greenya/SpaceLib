# hi

## [todo] Context: Add drag support

- [fix] handle removing stored views (source and target), in set_parent()
- [fix] drag_drop() and drag_cancel() are unsafe inside user callbacks; deferred/pending approach is needed
- [fix] drag_start() is fine to call only on .clicked and .wheeled; calling it in .entered, .left, .solved will make so it operates on stale hit view; also _drag_cleanup_state_from_prev_frame() cleans ".started" state; deferred/pending approach is needed

## [todo] View: Add .modal, should block any events propagation to parent views

At the moment, interaction stops on strata boundaries, and new flag would allow to add such boundary without strata elevation. Probably the change is only needed in `_interaction_parent()`.

## [todo] View: Add .auto_hide, should auto hide() the view on outside click

The idea is to simplify/automate dropdowns logic. When menu shows dropdown, the simple way is to create extra container (fullscreen later) which is invisible and will do only one thing -- catch the outside click and close the menu. The issue with such approach is that all views below will never react to mouse hover, so it will look like they cannot be clicked (which is true), so user will have to do click two times, one to cancel menu, another to click the view underneath. Not nice.

With the new flag, the view should get `hide()` when clicked outside. While the menu is shown, all the events continue work for all underneath views. Only click is special, wheeling should just continue work as before and obey normal interaction path (the menu is most likely is on separate strata, so it is naturally an interaction boundary and `.wheeled` event will not propagate from the menu to underneath views.

Observations:
- In Google Chrome, when context menu opened, the page underneath doesn't receive any events (no wheel, no hover); clicking on active element of the page below only dismissed the context menu and enables events for the page; meaning user need to click two times if context menu open to actually click the button.
- In Mozilla Firefox, when context menu opened, the page underneath does receive hover events but not wheel; clicking on hovered element dismisses context menu and doesn't click the element; second click needed.
- In VS Code, when context menu opened, wheel continue work for underneath opened file; no hover effects work; click outside close the menu.

## [todo] Context: Add support for ref_size={}, when it is zero, it is effectively means ref_size==screen_size

At the moment, user can achieve this easily just by doing `ctx.ref_size = screen_size` just before calling `update_context()`. Maybe keep like this, and do not add extra logic (?)

## [todo] Context: Make `Context.views` sparse array size to be a parameter somehow (now it is hardcoded)

- Maybe provide storage interface with add/remove (?)
- Maybe use `#config()` args, so user tune exact amount needed for the game. Small games might need only 100 views, medium 1000+ and large 5000+.

## [todo] Text: Fix issue with wrapping overflow text between tokens where no real whitespaces

At the moment, if we have say "He|c=#0f0|ll|c=#fff|o", the tokens are "He", "|c=#0f0|", "ll", "|c=#fff|", "o" and anywhere wrapping can happen, e.g. "He/llo", "Hell/o". Maybe we need to extend Text_Token struct, and the tokenizer should track whitespaces and if no whitespaces between .word tokens, they are considered one word chunk, and should be on the same line: if drop from overflow -- drop whole chunk.

Maybe we need to introduce new builtin tokens like "break" and "nobreak" (similar to .br, which user can put manually via "\n" or "|br|" and we use it for overflow wrap). The default style setting will be `breaking=true`. We will be using it automatically when we need to disallow overflow wrap, and user can use it manually, when multiple words with spaces needs to be on the same line no matter what. For example "Your final score is |nobreak|1 000 000|break|." -- the ending "." should be part of "1 000 000" automatically if we do it correctly, as there is no whitespaces before.

## [?] [todo] Text: support small stack of fonts and colors

- [?] With simple [dynamic; N] T, so next is possible: `|c=#fff|He|c=#ff0|ll|/c|o, World!`
- [?] Maybe support generic `text_style_push/pop()`, which hold whole Text_Style copy, so custom tokens can do group styling and have stacking too
