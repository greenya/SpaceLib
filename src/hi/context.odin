package hi

import "core:math"
import "core:math/linalg"

SCOPED_VIEWS_STACK_MAX :: 20

Context :: struct {
    // Reference size, e.g. 320x180, 1280x720 etc.
    ref_size: [2] f32,

    // Reference font height, e.g. 8, 10, 16 etc.
    ref_font_height: int,

    // Aspect ratio logic
    // - Fixed Aspect Ratio, value is `<0`
    // - Adaptive Aspect Ratio, a lerp ratio
    //      - `0.0` Full width
    //      - `0.5` Average
    //      - `1.0` Full height
    //
    // Note: Root anchoring is performed to ref space for "Fixed", and to screen space for "Adaptive".
    aspect_ratio_matching: f32,

    // The lower bound for `screen_pixel_scale`
    min_pixel_scale: f32,

    // If `true`, the `screen_pixel_scale` will get floored
    integer_scaling: bool,

    // If `true`, the `screen_top_left` might not be `{0,0}`
    align_center: bool,

    screen_size: [2] f32,
    screen_pixel_scale: f32,
    screen_top_left: [2] f32,
    screen_font_height: int,

    time_dt: f32,
    time_total: f32,

    mouse: struct {
        using input     : Mouse_Input,  // The value passed to `update_context()`
        ref_pos         : [2] f32,
        lmb_down_prev   : bool,
        lmb_pressed     : bool,         // For this frame only
        consumed        : bool,         // For this frame only
    },

    views: [dynamic] View,
    scoped_views_stack: [dynamic; SCOPED_VIEWS_STACK_MAX] ID,

    on_draw_view: proc (v: ^View),
}

Mouse_Input :: struct {
    screen_pos  : [2] f32,
    lmb_down    : bool,
    scroll_delta: f32,
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

create_context :: proc (init: Context, views_init_cap := 64, allocator := context.allocator) -> Context {
    ctx := init
    ctx.views = make([dynamic] View, len=0, cap=views_init_cap, allocator=allocator)
    append(&ctx.views, View { name="root" })

    // example of root with safe margins of 2.5% on all sides:
    /*
    append(&ctx.views, View {
        name="root",
        flags={ .ratio_x, .ratio_y },
        sizing=.fixed_ratio,
        size=.95,
        placement={ anchor=.5, pivot=.5 },
    })
    */

    return ctx
}

destroy_context :: proc (ctx: ^Context) {
    delete(ctx.views)
    ctx^ = {}
}

update_context :: proc (ctx: ^Context, screen_size: [2] f32, mouse_input: Mouse_Input, dt: f32) -> (mouse_input_consumed: bool) {
    set_screen_size(ctx, screen_size)

    // TODO: consider adding some kind of "is_dirty" to the Context; add if no changes detected, skip this step
    solve_view_tree(ctx)

    ctx.time_dt = dt
    ctx.time_total += dt

    ctx.mouse = {
        input = mouse_input,
        ref_pos = screen_to_ref(ctx^, mouse_input.screen_pos),
        lmb_down_prev = ctx.mouse.lmb_down,
        lmb_pressed = !ctx.mouse.lmb_down && mouse_input.lmb_down,
    }

    // TODO: Process input tree using hi.mouse, return true if input was consumed
    // hi.mouse.consumed = process_input_tree(hi.root_view)

    // TODO: Animate and layout tree
    // animate_and_layout_tree(hi.root_view, dt)

    return ctx.mouse.consumed
}

draw_context :: proc (ctx: Context) {
    draw_children(ctx, 0)

    // rel_pos: [2] f32
    // rel_size: ctx.ref_size

    // for v, i in ctx.views {
    //     if i == 0 do continue

        // pos := view_pos(v.placement, v.size, rel_pos, rel_size)
        // v.draw_pos
        // v.draw_size

    // }
}

set_screen_size :: proc (ctx: ^Context, new_size: [2] f32) {
    if new_size == ctx.screen_size do return

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
            // TODO: Reload fonts using new_font_height
            // .....
            ctx.screen_font_height = new_font_height
        }
    }

    ctx.screen_size = new_size
    ctx.screen_pixel_scale = new_pixel_scale
}

screen_to_ref :: proc (ctx: Context, screen_pos: [2] f32) -> [2] f32 {
    return (screen_pos-ctx.screen_top_left) / ctx.screen_pixel_scale
}

ref_to_screen :: proc (ctx: Context, ref_pos: [2] f32) -> [2] f32 {
    return ctx.screen_top_left + (ref_pos * ctx.screen_pixel_scale)
}

get_anchor_root :: proc (ctx: Context) -> (pos: [2] f32, size: [2] f32) {
    if ctx.aspect_ratio_matching < 0 {
        return ctx.screen_top_left, ctx.ref_size * ctx.screen_pixel_scale
    } else {
        return {0,0}, { f32(ctx.screen_size.x), f32(ctx.screen_size.y) }
    }
}
