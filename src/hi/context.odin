package hi

import "core:math"
import "core:math/linalg"

Context_Init :: struct {
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

    // If `true`, the `update_context()` will automatically re-solve the view tree.
    // Otherwise, solving of the view tree is only performed on explicit `solve_context()` call.
    // When different `screen_size` value passed to the `update_context()`, the view tree will be
    // re-solved regardless of this setting.
    //
    // Recommendations:
    // - Use `true`:
    //      * for small view tree, when performance is not an issue
    //      * for In-Game Context with many animations
    // - Use `false` for Debug Context with no animations and visible large view tree,
    //   you need to call `solve_context()` after making changes to the view tree
    continuous_solving: bool,

    // Optional debug rectangle drawing callback.
    // Used to overdraw view with `.debug` flag.
    debug_draw_rect: Debug_Draw_Rect_Proc,
}

Context :: struct {
    views       : [dynamic] View,       // The view tree
    views_stack : [dynamic; 64] ID,     // Current views stack

    using init: Context_Init,

    time_dt: f32,
    time_total: f32,

    screen: struct {
        size        : [2] f32,
        pixel_scale : f32,
        top_left    : [2] f32,
        font_height : int,
    },

    mouse: struct {
        using input     : Mouse_Input,  // The value passed to `update_context()`
        ref_pos         : [2] f32,
        lmb_down_prev   : bool,
        lmb_pressed     : bool,         // For this frame only
        consumed        : bool,         // For this frame only
    },
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

Rect :: struct { x, y, w, h: f32 }

Debug_Draw_Rect_Proc :: proc (rect: Rect, thick: f32, color: [4] u8)

create_context :: proc (init: Context_Init, views_init_cap := 64, allocator := context.allocator) -> ^Context {
    ctx := new(Context, allocator)
    ctx.init = init

    ctx.views = make([dynamic] View, len=0, cap=views_init_cap, allocator=allocator)
    append(&ctx.views, View { name="root" })

    return ctx
}

destroy_context :: proc (ctx: ^Context) {
    delete(ctx.views)
}

update_context :: proc (ctx: ^Context, screen_size: [2] f32, mouse_input: Mouse_Input, dt: f32) -> (mouse_input_consumed: bool) {
    screen_size_changed := screen_size != ctx.screen.size

    if screen_size_changed {
        set_screen_size(ctx, screen_size)
    }

    if screen_size_changed || ctx.continuous_solving {
        solve_context(ctx)
    }

    ctx.time_dt = dt
    ctx.time_total += dt

    ctx.mouse = {
        input = mouse_input,
        ref_pos = screen_pos_to_ref(ctx, mouse_input.screen_pos),
        lmb_down_prev = ctx.mouse.lmb_down,
        lmb_pressed = !ctx.mouse.lmb_down && mouse_input.lmb_down,
    }

    // TODO: Process input tree using hi.mouse, return true if input was consumed
    // hi.mouse.consumed = process_input_tree(hi.root_view)

    // TODO: Animate and layout tree
    // animate_and_layout_tree(hi.root_view, dt)

    return ctx.mouse.consumed
}

draw_context :: proc (ctx: ^Context) {
    if .hidden in ctx.views[0].flags do return

    debug := .debug in ctx.views[0].flags
    if debug do debug_draw_view(ctx, 0)

    draw_view_children(ctx, 0, debug)
}

solve_context :: proc (ctx: ^Context) {
    solve_root_view(ctx)
    solve_view_fit_and_fixed_size(ctx, 0)
    solve_children_fill_and_ratio_size(ctx, 0)
}

print_context :: proc (ctx: ^Context) {
    debug_print_tree(ctx, 0)
}

@private
set_screen_size :: proc (ctx: ^Context, new_size: [2] f32) {
    new_scale := new_size / ctx.ref_size

    new_pixel_scale := ctx.aspect_ratio_matching < 0\
        ? min(new_scale.x, new_scale.y)\
        : linalg.lerp(new_scale.x, new_scale.y, ctx.aspect_ratio_matching)

    if ctx.integer_scaling {
        new_pixel_scale = math.floor(new_pixel_scale)
    }

    new_pixel_scale = max(new_pixel_scale, max(ctx.min_pixel_scale, 0.001))

    ctx.screen.top_left = ctx.align_center\
        ? 0.5 * (new_size - ctx.ref_size * new_pixel_scale)\
        : {}

    if 0.001 < abs(new_pixel_scale-ctx.screen.pixel_scale) {
        new_font_height := int(f32(ctx.ref_font_height) * new_pixel_scale)
        if new_font_height != ctx.screen.font_height {
            // TODO: Reload fonts using new_font_height
            // .....
            ctx.screen.font_height = new_font_height
        }
    }

    ctx.screen.size = new_size
    ctx.screen.pixel_scale = new_pixel_scale
}

screen_pos_to_ref :: proc (ctx: ^Context, screen_pos: [2] f32) -> [2] f32 {
    return (screen_pos-ctx.screen.top_left) / ctx.screen.pixel_scale
}

screen_size_to_ref :: proc (ctx: ^Context, screen_size: [2] f32) -> [2] f32 {
    return screen_size / ctx.screen.pixel_scale
}

ref_pos_to_screen :: proc (ctx: ^Context, ref_pos: [2] f32) -> [2] f32 {
    return ctx.screen.top_left + (ref_pos * ctx.screen.pixel_scale)
}

ref_size_to_screen :: proc (ctx: ^Context, ref_size: [2] f32) -> [2] f32 {
    return ref_size * ctx.screen.pixel_scale
}

ref_rect_to_screen :: proc (ctx: ^Context, ref_rect: Rect) -> Rect {
    return {
        expand_values(ref_pos_to_screen(ctx, { ref_rect.x, ref_rect.y })),
        expand_values(ref_size_to_screen(ctx, { ref_rect.w, ref_rect.h })),
    }
}

ref_view_to_screen :: proc (ctx: ^Context, v: ^View) -> Rect {
    return {
        expand_values(ref_pos_to_screen(ctx, v.solved.pos)),
        expand_values(ref_size_to_screen(ctx, v.solved.size)),
    }
}

ref_id_to_screen :: proc (ctx: ^Context, id: ID) -> Rect {
    return ref_view_to_screen(ctx, &ctx.views[id])
}

// Translates `view.solved` rect into screen rect
ref_to_screen :: proc {
    ref_view_to_screen,
    ref_id_to_screen,
}
