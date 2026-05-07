# hi Notes

----------

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

----------

// TODO: Support for Free-Floating Fit, e.g. when parent doesn't have `layout`,
//       but still want its size to be updated, to fit all children, who are placed
//       via their `placement`.

----------

```odin
// example of root with safe margins of 2.5% on all sides:
append(&ctx.views, View {
    name="root",
    flags={ .ratio_x, .ratio_y },
    sizing=.fixed_ratio,
    size=.95,
    placement={ anchor=.5, pivot=.5 },
})
```
