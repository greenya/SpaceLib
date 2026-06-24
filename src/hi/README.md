# hi

## TODOs

TODO: View: Add .modal flag, should block any events propagation to parent views

TODO: Context: add support for ref_size={}, when it is zero, it is effectively means ref_size==screen_size (for dev ui)

- At the moment, user can achieve this easily just by doing `ctx.ref_size = screen_size` just before calling update_context(). Maybe keep like this, and do not add extra logic (?)

TODO: Context: make `Context.views` sparse array size to be a parameter somehow (now it is hardcoded)

- Maybe provide storage interface with add/remove (?)
- Maybe use `#config()` args, so user tune exact amount needed for the game. Small games might need only 100 views, medium 1000+ and large 5000+.

TODO: Text: Fix issue with wrapping overflow text between commands where no real whitespaces

At the moment, if we have say "He|c=#0f0|ll|c=#fff|o", the tokens are "He", "|c=#0f0|", "ll", "|c=#fff|", "o" and anywhere wrapping can happen, e.g. "He/llo", "Hell/o". Maybe we need to extend Text_Token struct, and the tokenizer should track whitespaces and if no whitespaces between .word tokens, they are considered one word chunk, and should be on the same line: if drop from overflow -- drop whole chunk.

Maybe we need to introduce new builtin commands like "break" and "nobreak" (similar to .br, which user can put manually via "\n" or "|br|" and we use it for overflow wrap). The default style setting will be `breaking=true`. We will be using it automatically when we need to disallow overflow wrap, and user can use it manually, when multiple words with spaces needs to be on the same line no matter what. For example "Your final score is |nobreak|1 000 000|break|." -- the ending "." should be part of "1 000 000" automatically if we do it correctly, as there is no whitespaces before.

TODO: Text: [?] support `.text_wordy_static` flag, which would tell to never re-tokenizer and re-measure the text, only re-wrap. This can be a win for any large text (and most large texts are never changes anyway; we also can provide some `set_wordy_text()` to discard cache and re-do all).

TODO: Text: [?] do not automatically re-tokenize and re-measure text if Context.ref_font_height is not changed

    At the moment, we regenerate text tokens completely (re-tokenize, re-measure, re-wrap), i guess we could just re-wrap existing measured tokens. Need to test timings, if this optimization is necessary.

TODO: Text: [?] support multiple commands in a tag, example: "|wrap,left|This is |c=#f0f,f=big|Big Pink Text!"

TODO: Text: [?] support stack of fonts and colors with simple [dynamic; N] T, so next is possible: |c=#fff|He|c=#ff0|ll|/c|o, World!

## Notes on number of stratas

[?] 6 stratas idea for more granular layer control. Do we need it? For now lets keep 4.

Note: at the moment we use 4 bits to store the value, so we can have up 16 levels. Also we do not store any preallocated array for each strata, so memory footprint should not change when increasing number of stratas.

```odin
Strata :: enum {
    background  = -2,   // For background and generally non-interactive views, e.g. HUD, world object labels, decorations and ground art
    low         = -1,   // For underlying views, e.g. backdrop art, a child of `medium` which needs to be drawn below and skip the scissor
    medium      = 0,    // For the most views, e,g. panels, buttons, health bars, action bars, non-modal dialogs
    high        = 1,    // For priority views, e.g. menus, dropdowns, a child of `medium` which needs to be draw above and skip the scissor
    overlay     = 2,    // For screen non-interactive views like popup auto-hiding messages and notifications. For screen interactive views requiring immediate attention, like system menus and modal dialogs, often with screen darkening layer to focus attention and block input.
    tooltip     = 3,    // For topmost and generally non-interactive transient views like tooltips, system messages
}
```

## Notes on building ui from code with writing less of it (scoped building or extra generator/builder)

[?] Maybe remove view_scoped.odin, and Context.scoped_views_stack, as this value is very temporary, but lives in Context for all time. So instead, we can maybe do like

```odin
add_dialog :: proc (ctx: Context, name: string, ...) {
    v := hi.view_generator(ctx)

    v->begin("dialog", { name=name })

    if v->group("header") {
        v->one("title")
        v->one("close_btn")
    }

    v->one("content")

    if v->group("columns") {
        v->one("name")
        v->one("desc")
        v->one("actions")
    }

    if v->group("footer") {
        add_button(ctx, "ok")
        add_button(ctx, "cancel")
    }

    v->end("dialog") // pass name for consistency check and code readability
}

add_button :: proc (ctx: Context, name: string) {
    v := hi.view_generator(ctx)
    if v->group("button", { name=name }) {
        v->one("icon")
        v->one("text")
    }
}
```

The `View_Generator` holds the state, and has arrow procs. The `begin()` and `end()` is no different from `if group() { ...`, the point is that large groups like whole dialog is not nice to put all code inside "if". So the `group()` does the same as `begin()` plus defers `end()` call.

Not sure how `add_button()` using only Context can deduct the parent to be used. If we will be passing View_Generator to add_button(), then there is no point in View_Generator i guess, all the procs can be held by the Context itself.

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
