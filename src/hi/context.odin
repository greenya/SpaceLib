package hi

import "core:math"
import "core:math/linalg"
import "core:slice"
import "../core"

// TODO: add support for ref_size={}, when it is zero, it is effectively means ref_size==screen_size (for dev ui)
// TODO: make Context.views sparse array size to be a parameter somehow (now its hardcoded), maybe provide storage interface with add/remove (?)
// TODO: add in_root_rect(v) -> bool, check if v.solved fully in the {0,0,ref_size.x,ref_size.y}

VIEWS_MAX :: 2000
STRATA_BUCKET_VIEWS_MAX :: VIEWS_MAX / 2

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

    // Debug drawing callbacks. Used with `.debug` views.
    // All positions and sizes are in screen space.
    debug_draw_line: proc (from, to: Vec2, thick: f32, color: Color),
    debug_draw_text: proc (text: string, pos: Vec2, color: Color),
}

Context :: struct {
    views           : core.Sparse_Array(View, VIEWS_MAX),
    strata_buckets  : [Strata] [dynamic; STRATA_BUCKET_VIEWS_MAX] View_ID,
    // views_stack     : [dynamic; 64] ^View,
    root            : ^View,
    solved          : bool, // if `false`, the `update_context()` will do `solve_context()` automatically

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
}

create_context :: proc (init: Context_Init, allocator := context.allocator) -> ^Context {
    ctx := new(Context, allocator)
    ctx.init = init

    core.sparse_array_init(&ctx.views)

    root_id, root := core.sparse_array_add(&ctx.views, View { ctx=ctx, name="root" })
    ensure(root_id == _ROOT_VIEW_ID)
    ctx.root = root

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
    for bucket in ctx.strata_buckets {
        for v_id in bucket {
            v := &ctx.views.items[v_id]
            if v.on_draw != nil     do v->on_draw()
            if .debug in v.flags    do _debug_draw_view(v)
        }
    }
}

// - Re-solves `View.solved` for every non-`.hidden` view
// - Rebuilds `Context.strata_buckets`
// - Sets `Context.solved`
solve_context :: proc (ctx: ^Context) {
    for &bucket in ctx.strata_buckets do clear(&bucket)

    ctx.root.solved = { size=ctx.ref_size }
    append(&ctx.strata_buckets[ctx.root.strata], ctx.root.id)

    _solve_view_fit_and_fixed_size(ctx.root)
    _solve_children_fill_and_ratio_size(ctx.root)
    _sort_strata_buckets(ctx)

    ctx.solved = true
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

_sort_strata_buckets :: proc (ctx: ^Context) {
    context.user_ptr = ctx
    for &bucket in ctx.strata_buckets {
        slice.sort_by(bucket[:], less=proc (i, j: View_ID) -> bool {
            ctx := cast (^Context) context.user_ptr
            return ctx.views.items[i].level != ctx.views.items[j].level\
                 ? ctx.views.items[i].level  < ctx.views.items[j].level\
                 : i < j
        })
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
    return {
        expand_values(ref_pos_to_screen(v.ctx, v.solved.pos)),
        expand_values(ref_size_to_screen(v.ctx, v.solved.size)),
    }
}
