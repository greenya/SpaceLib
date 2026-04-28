package hi

// Begins new scope for the child views to be added in order.
// Returned pointer must be assigned to the `context.user_ptr`.
//
// If you don't want to modify `context.user_ptr`, use verbose `append_view()` instead.
//
// Example:
// ```
// context.user_ptr = hi.begin_scope(&ctx)
//
// hi.add_view({ name="title" })
//
// hi.begin_view({ name="buttons", size={200,40}, layout={dir=.row,gap=10} })
//     hi.add_view({ name="one", flags={.fill_x,.fill_y} })
//     hi.add_view({ name="two", flags={.fill_x,.fill_y} })
//     hi.add_view({ name="three", flags={.fill_x,.fill_y} })
// hi.end_view()
//
// hi.end_scope()
// ```
begin_scope :: proc (ctx: ^Context, parent := ID(0)) -> (user_ptr: rawptr) {
    n := append(&ctx.scoped_views_stack, parent)
    assert(n == 1, "SCOPED_VIEWS_STACK_MAX overflow")
    return ctx
}

end_scope :: proc () {
    ctx := current_context()
    pop(&ctx.scoped_views_stack)
}

current_context :: proc () -> ^Context {
    assert(context.user_ptr != nil, "No context, did you forget to call `begin_scope()`?")
    return auto_cast context.user_ptr
}

current_parent :: proc (ctx: ^Context) -> ID {
    return len(ctx.scoped_views_stack) > 0\
        ? ctx.scoped_views_stack[-1 + len(ctx.scoped_views_stack)]\
        : 0
}

add_view :: proc (init: View) -> ID {
    c := current_context()
    return append_view(c, current_parent(c), init)
}

begin_view :: proc (init: View) -> ID {
    c := current_context()
    id := append_view(c, current_parent(c), init)
    begin_scope(c, id)
    return id
}

end_view :: end_scope
