package hi

import "core:math"
import "core:math/linalg"
import "core:slice"
import "../core"

// TODO: add support for ref_size={}, when it is zero, it is effectively means ref_size==screen_size (for dev ui)
// TODO: make Context.views sparse array size to be a parameter somehow (now its hardcoded), maybe provide storage interface with add/remove (?)
// TODO: add in_root_rect(v) -> bool, check if v.solved fully in the {0,0,ref_size.x,ref_size.y}
// TODO: add Views.opacity and Views.solved.opacity (propagated opacity)

VIEWS_MAX :: 2000

Context_Init :: struct {
    // Reference size, e.g. 320x180, 1280x720 etc.
    ref_size: Vec2,

    // Reference font height, e.g. 8, 10, 16 etc.
    ref_font_height: int,

    // Aspect ratio logic
    // - Fixed Aspect Ratio, value is `<0`
    // - Adaptive Aspect Ratio, a lerp ratio
    //      - `0.0` Full width
    //      - `0.5` Average
    //      - `1.0` Full height
    aspect_ratio_matching: f32,

    // The lower bound for `screen_pixel_scale`
    min_pixel_scale: f32,

    // If `true`, the `screen_pixel_scale` will get floored
    integer_scaling: bool,

    // If `true`, the `screen_top_left` might not be `{0,0}`
    align_center: bool,

    // Event callback
    on_event: proc (ctx: ^Context, event: Context_Event),

    // Scissor callback. Scissor should be disabled when `scissor == {}`.
    set_scissor: proc (ctx: ^Context, scissor: Rect),

    // Debug drawing callbacks. Used with `.debug` views.
    // All positions and sizes are in screen space.
    debug_draw_line: proc (from, to: Vec2, thick: f32, color: Color),
    debug_draw_text: proc (text: string, pos: Vec2, color: Color),
}

Context :: struct {
    views           : core.Sparse_Array(View, VIEWS_MAX),
    visible_views   : [dynamic; VIEWS_MAX] ^View,
    next_view_sid   : View_SID,
    root            : ^View,
    solved          : bool, // if `false`, the `update_context()` will do `solve_context()` automatically which clears this flag

    using init: Context_Init,

    dt: f32,
    time: f32,

    screen_size         : Vec2,
    screen_pixel_scale  : f32,
    screen_top_left     : Vec2,
    screen_font_height  : int,

    mouse: struct {
        using input     : Mouse_Input,  // The value passed to `update_context()`
        ref_pos         : Vec2,
        lmb_down_prev   : bool,
        lmb_pressed     : bool,         // For this frame only
        consumed        : bool,         // For this frame only
    },
}

Mouse_Input :: struct {
    screen_pos  : Vec2,
    lmb_down    : bool,
    wheel_delta : f32,
}

Mouse_Event :: struct {
    type: Mouse_Event_Type,
}

Mouse_Event_Type :: enum {
    moved,
    pressed,
    released,
    scrolled,
    // entered,
    // left,
}

Context_Event :: struct {
    type: Context_Event_Type,
}

Context_Event_Type :: enum {
    screen_size_changed,
    screen_font_height_changed,
    context_solved,
}

create_context :: proc (init: Context_Init, allocator := context.allocator) -> ^Context {
    ctx := new(Context, allocator)
    ctx.init = init
    ctx.next_view_sid = 1

    core.sparse_array_init(&ctx.views)

    root_idx, root := core.sparse_array_add(&ctx.views, View { ctx=ctx, name="root" })
    ensure(root_idx == 0)
    ctx.root = root
    ctx.root.sid = _next_view_sid(ctx)

    return ctx
}

destroy_context :: proc (ctx: ^Context) {
    free(ctx)
}

update_context :: proc (ctx: ^Context, screen_size: Vec2, mouse_input: Mouse_Input, dt: f32) -> (mouse_input_consumed: bool) {
    screen_size_changed := screen_size != ctx.screen_size

    if screen_size_changed {
        _set_screen_size(ctx, screen_size)
        ctx.solved = false
    }

    if !ctx.solved {
        solve_context(ctx)
    }

    ctx.dt = dt
    ctx.time += dt

    ctx.mouse = {
        input = mouse_input,
        ref_pos = screen_pos_to_ref(ctx, mouse_input.screen_pos),
        lmb_down_prev = ctx.mouse.lmb_down,
        lmb_pressed = !ctx.mouse.lmb_down && mouse_input.lmb_down,
    }

    // TODO: Process input tree using hi.mouse, return true if input was consumed
    // ctx.mouse.consumed = process_input_tree(ctx.root)

    // TODO: Animate and layout tree
    // animate_and_layout_tree(ctx.root, dt)

    return ctx.mouse.consumed
}

draw_context :: proc (ctx: ^Context) {
    parent_scissor: Rect = {-1,-1,-1,-1}
    for v in ctx.visible_views {
        if parent_scissor != v.solved.parent_scissor {
            parent_scissor = v.solved.parent_scissor
            if ctx.set_scissor != nil {
                ctx->set_scissor(parent_scissor)
            }
        }
        if v.on_draw != nil {
            v->on_draw()
        }
        if .debug in v.flags {
            _debug_draw_view(v)
        }
    }
}

// - Re-solves `View.solved` for every visible view
// - Rebuilds `Context.visible_views`
// - Sets `Context.solved`
solve_context :: proc (ctx: ^Context) {
    defer {
        ctx.solved = true
        if ctx.on_event != nil {
            ctx->on_event({ type=.context_solved })
        }
    }

    clear(&ctx.visible_views)

    if .hidden in ctx.root.flags do return

    ctx.root.solved = { rect={0,0,ctx.ref_size.x,ctx.ref_size.y} }
    append(&ctx.visible_views, ctx.root)

    _solve_view_fit_and_fixed_size(ctx.root)
    _solve_children_fill_and_ratio_size(ctx.root)

    slice.sort_by(ctx.visible_views[:], less=proc (i, j: ^View) -> bool {
        switch {
        case i.strata != j.strata   : return i.strata < j.strata
        case i.level  != j.level    : return i.level  < j.level
        case                        : return i.sid    < j.sid
        }
    })
}

@require_results
_next_view_sid :: proc (ctx: ^Context) -> View_SID {
    n := ctx.next_view_sid
    ctx.next_view_sid += 1
    return n
}

_set_screen_size :: proc (ctx: ^Context, new_size: Vec2) {
    new_scale := new_size / ctx.ref_size

    new_pixel_scale := ctx.aspect_ratio_matching < 0\
        ? min(new_scale.x, new_scale.y)\
        : linalg.lerp(new_scale.x, new_scale.y, ctx.aspect_ratio_matching)

    if ctx.integer_scaling {
        new_pixel_scale = math.floor(new_pixel_scale)
    }

    new_pixel_scale = max(new_pixel_scale, max(ctx.min_pixel_scale, 0.001))

    ctx.screen_top_left = ctx.align_center\
        ? 0.5 * (new_size - ctx.ref_size * new_pixel_scale)\
        : {}

    if 0.001 < abs(new_pixel_scale-ctx.screen_pixel_scale) {
        new_font_height := int(f32(ctx.ref_font_height) * new_pixel_scale)
        if new_font_height != ctx.screen_font_height {
            ctx.screen_font_height = new_font_height
            if ctx.on_event != nil {
                ctx->on_event({ type=.screen_font_height_changed })
            }
        }
    }

    ctx.screen_size = new_size
    ctx.screen_pixel_scale = new_pixel_scale

    if ctx.on_event != nil {
        ctx->on_event({ type=.screen_size_changed })
    }
}

screen_pos_to_ref :: proc (ctx: ^Context, screen_pos: Vec2) -> Vec2 {
    return (screen_pos-ctx.screen_top_left) / ctx.screen_pixel_scale
}

screen_size_to_ref :: proc (ctx: ^Context, screen_size: Vec2) -> Vec2 {
    return screen_size / ctx.screen_pixel_scale
}

ref_pos_to_screen :: proc (ctx: ^Context, ref_pos: Vec2) -> Vec2 {
    return ctx.screen_top_left + (ref_pos * ctx.screen_pixel_scale)
}

ref_size_to_screen :: proc (ctx: ^Context, ref_size: Vec2) -> Vec2 {
    return ref_size * ctx.screen_pixel_scale
}

ref_rect_to_screen :: proc (ctx: ^Context, ref_rect: Rect) -> Rect {
    return {
        expand_values(ref_pos_to_screen(ctx, { ref_rect.x, ref_rect.y })),
        expand_values(ref_size_to_screen(ctx, { ref_rect.w, ref_rect.h })),
    }
}

ref_view_to_screen :: proc (v: ^View) -> Rect {
    return ref_rect_to_screen(v.ctx, v.solved.rect)
}
