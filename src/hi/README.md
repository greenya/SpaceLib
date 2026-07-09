# hi

## TODOs

TODO: Text: Add .intext_full modification to .intext. Also refactor "Text_Custom_Token_Hint.scale_full_line" to "full_line" and it should be used for both cases: "intext_view" and "scale". At the moment "intext_view" ignores "scale" and "scale_full_line".

When .intext_full is used, the token should dictate not only position for the view, but also width; the view only dictates height for the token.

TODO: View: Add .modal flag, should block any events propagation to parent views

TODO: Context: add support for ref_size={}, when it is zero, it is effectively means ref_size==screen_size (for dev ui)

- At the moment, user can achieve this easily just by doing `ctx.ref_size = screen_size` just before calling update_context(). Maybe keep like this, and do not add extra logic (?)

TODO: Context: make `Context.views` sparse array size to be a parameter somehow (now it is hardcoded)

- Maybe provide storage interface with add/remove (?)
- Maybe use `#config()` args, so user tune exact amount needed for the game. Small games might need only 100 views, medium 1000+ and large 5000+.

TODO: Text: Fix issue with wrapping overflow text between tokens where no real whitespaces

At the moment, if we have say "He|c=#0f0|ll|c=#fff|o", the tokens are "He", "|c=#0f0|", "ll", "|c=#fff|", "o" and anywhere wrapping can happen, e.g. "He/llo", "Hell/o". Maybe we need to extend Text_Token struct, and the tokenizer should track whitespaces and if no whitespaces between .word tokens, they are considered one word chunk, and should be on the same line: if drop from overflow -- drop whole chunk.

Maybe we need to introduce new builtin tokens like "break" and "nobreak" (similar to .br, which user can put manually via "\n" or "|br|" and we use it for overflow wrap). The default style setting will be `breaking=true`. We will be using it automatically when we need to disallow overflow wrap, and user can use it manually, when multiple words with spaces needs to be on the same line no matter what. For example "Your final score is |nobreak|1 000 000|break|." -- the ending "." should be part of "1 000 000" automatically if we do it correctly, as there is no whitespaces before.

TODO: Text: [?] support stack of fonts and colors with simple [dynamic; N] T, so next is possible: |c=#fff|He|c=#ff0|ll|/c|o, World!

## in_root_rect

```odin
@require_results
in_root_rect :: proc (v: ^View) -> bool {
    return core.rect_in_rect(v.solved_rect, v.ctx.root.solved_rect)
}
```

## .auto_hide

```odin
// auto_hide // TODO: think more on auto_hide flag.
//              In spacelib:ui, this flag was intended to be used for dropdown menus and similar popups
//              which should be closed if clicked outside; the task apparently wasn't that simple and
//              obvious, and the flag wasn't very useful.
```
