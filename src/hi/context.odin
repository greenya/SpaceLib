package hi

import "core:math"
import "core:math/linalg"
import "core:slice"
import "../core"

MAX_VIEWS           :: 2000
MAX_ACTIVE_VIEWS    :: MAX_VIEWS / 4
MAX_TEXT_TOKENS     :: 1000

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
    on_event: Context_Event_Proc,

    // Scissor callback. Scissor should be disabled when `scissor == {}`.
    on_scissor: Context_Scissor_Proc,

    // Text measure callback. Used only with `.text` views.
    // - `style` Current style; font details are in `style.font` and `style.user_*` (if used)
    // - `type` token type, expect only:
    //      * `.word` Letters/numbers/punctuations
    //      * `.whitespace` Spaces `" "` and tabs `"\t"`
    // - `text` Non-empty string to measure
    //
    // Use `ctx.ref_font_height` as base font size multiplier. Returned value is in ref units.
    on_measure_text: Context_Measure_Text_Proc,

    // Text custom command callback. Used only with `.text` views.
    //
    // Builtin commands:
    // - `br` Line break
    // - `tab=XXX` Tab stop; moves cursor X position to XXX if it is lower than XXX
    // - `wrap` / `nowrap` Toggle wrapping mode
    // - `left`, `center`, `right` Set alignment (applied at line break or text end)
    //
    // The callback is NOT called for any command above.
    // Return non-zero size (in ref units) for physical space, e.g. `[icon=sword]`.
    // Update `style` for styling, use `style.user_*` to store custom state.
    //
    // Called on every custom command in both phases: updating and drawing.
    // Check `ctx.drawing` if need to know the phase.
    on_text_custom_command: Context_Text_Custom_Command_Proc,

    // Text style callback. Used only with `.text` views.
    // Allows overriding default style (font, color, align, wrapping).
    //
    // Called once before traversing the tokens in both phases: updating and drawing.
    // Check `ctx.drawing` if need to know the phase.
    on_text_style: Context_Text_Style_Proc,

    // Fallback for all `.text` view drawing. Use `ctx.screen_font_height` as base font size multiplier.
    //
    // Note: The call is skipped if `v.solved_text_tokens` is empty.
    on_draw_text: proc (v: ^Active_View),

    // Debug drawing callbacks. Used with `.debug` views.
    // All positions and sizes are in screen space.
    debug_draw_line: proc (from, to: Vec2, thick: f32, color: Color),
    debug_draw_text: proc (text: string, pos: Vec2, color: Color),
}

Context :: struct {
    views               : core.Sparse_Array(View, MAX_VIEWS),
    active_views        : [dynamic; MAX_ACTIVE_VIEWS] Active_View,
    active_text_tokens  : [dynamic; MAX_TEXT_TOKENS] Text_Token,
    next_view_sid       : View_SID,
    root                : ^View,
    solved              : bool, // if cleared, the `update_context()` will do `solve_context()` automatically which sets this flag
    drawing             : bool, // if set, the `draw_context()` phase is currently running; useful when implementing custom text commands which should set some gpu or audio state and this should not be done when updating context, only when drawing

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

    stats: struct {
        max_views_used              : int,
        max_active_views_used       : int,
        max_active_text_tokens_used : int,
    },
}

// An active view.
//
// A view is considered *inactive* and skipped by the solver if:
// - the view itself or any parent of the view is `.hidden`
// - the view does not intersect `solved_scissor` (completely clipped out)
// - the view is a child of an *inactive* view
//
// Note: Zero opacity alone does not make the view *inactive*.
Active_View :: struct {
    using view          : ^View,
    solved_scissor      : Rect,             // Scissor rect this view is clipped by in ref units. If empty, the scissor is disabled.
    solved_text_tokens  : [] Text_Token,    // Text tokens of this view. Only for `.text` views.
}

Mouse_Input :: struct {
    screen_pos  : Vec2,
    lmb_down    : bool,
    wheel_delta : f32,
}

// Mouse_Event :: struct {
//     type: Mouse_Event_Type,
// }

// Mouse_Event_Type :: enum {
//     moved,
//     pressed,
//     released,
//     scrolled,
//     // entered,
//     // left,
// }

Context_Event :: struct {
    type: Context_Event_Type,
}

Context_Event_Type :: enum {
    screen_size_changed,
    screen_font_height_changed,
    solved,
}

Context_Event_Proc              :: proc (ctx: ^Context, event: Context_Event)
Context_Scissor_Proc            :: proc (ctx: ^Context, scissor: Rect)
Context_Measure_Text_Proc       :: proc (ctx: ^Context, style: Text_Style, type: Text_Token_Type, text: string) -> (size: [2] f32)
Context_Text_Custom_Command_Proc:: proc (ctx: ^Context, style: ^Text_Style, cmd, args: string) -> (size: [2] f32)
Context_Text_Style_Proc         :: proc (ctx: ^Context, style: ^Text_Style)

create_context :: proc (init: Context_Init, allocator := context.allocator) -> ^Context {
    ctx := new(Context, allocator)
    ctx.init = init
    ctx.next_view_sid = 1

    core.sparse_array_init(&ctx.views)

    root_init := View { ctx=ctx, name="root", opacity=1 }
    root_idx, root := core.sparse_array_add(&ctx.views, root_init)
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
    } else {
        _propagate_active_views_opacity(ctx)
    }

    ctx.dt = dt
    ctx.time += dt

    ctx.mouse = {
        input           = mouse_input,
        ref_pos         = screen_pos_to_ref(ctx, mouse_input.screen_pos),
        lmb_down_prev   = ctx.mouse.lmb_down,
        lmb_pressed     = !ctx.mouse.lmb_down && mouse_input.lmb_down,
    }

    // TODO: Process input tree using hi.mouse, return true if input was consumed
    // ctx.mouse.consumed = process_input_tree(ctx.root)

    // TODO: Animate and layout tree
    // animate_and_layout_tree(ctx.root, dt)

    for &v in ctx.active_views {
        _emit(v, { type=.updated })
    }

    return ctx.mouse.consumed
}

// - Rebuilds `Context.active_views`
// - Rebuilds `Context.active_text_tokens`
// - Updates `View.solved` for every active view
// - Sets `Context.solved`
//
// Note: This procedure is executed automatically by the `update_context()` when `Context.solved` is cleared.
// Generally, after you do all the manual modifications to the views and at the end you do `ctx.solved = false`.
// But sometimes you need to solve the context to know updated (solved) values in advance, for example when
// spawning a tooltip -- after adding dynamic content to the tooltip, you want to reposition it (or re-anchor)
// if it happens to go partially off-screen, to do that you do manual call to `solve_context()` so your
// `tooltip.solved_rect` is updated, and now you can check that and re-position/re-anchor the tooltip to fit
// the screen.
solve_context :: proc (ctx: ^Context) {
    clear(&ctx.active_views)

    defer {
        ctx.stats.max_active_views_used = max(ctx.stats.max_active_views_used, len(ctx.active_views))
        ctx.stats.max_active_text_tokens_used = max(ctx.stats.max_active_text_tokens_used, len(ctx.active_text_tokens))

        ctx.solved = true
        if ctx.on_event != nil {
            ctx->on_event({ type=.solved })
        }
    }

    if .hidden in ctx.root.flags do return

    ctx.root.solved_rect = { 0, 0, ctx.ref_size.x, ctx.ref_size.y }
    ctx.root.solved_opacity = ctx.root.opacity
    ctx.root.solved_layout_child_count = 0
    append(&ctx.active_views, Active_View { ctx.root, {}, nil })

    // never repeat layout and text measurement more than twice
    for _ in 0..<2 {
        _solve_view_fit_and_fixed_size(ctx.root)
        _solve_children_fill_and_ratio_size(ctx.root, {})
        text_height_mismatch := _regenerate_active_text_tokens(ctx)
        if text_height_mismatch {
            resize(&ctx.active_views, 1) // keep root only
            continue
        }
        break
    }

    _sort_active_views(ctx)
    _propagate_active_views_opacity(ctx)
}

draw_context :: proc (ctx: ^Context) {
    ctx.drawing = true
    defer ctx.drawing = false

    solved_scissor: Rect = {-1,-1,-1,-1}
    has_on_scissor := ctx.on_scissor != nil
    has_on_draw_text := ctx.on_draw_text != nil

    for &v in ctx.active_views {
        if solved_scissor != v.solved_scissor {
            solved_scissor = v.solved_scissor
            if has_on_scissor do ctx->on_scissor(solved_scissor)
        }

        if v.on_draw != nil {
            v->on_draw()
        } else if .text in v.flags && has_on_draw_text && len(v.solved_text_tokens) > 0 {
            ctx.on_draw_text(&v)
        }

        if .debug in v.flags {
            if solved_scissor != {} && has_on_scissor do ctx->on_scissor({})
            _debug_draw_view(v)
            if solved_scissor != {} && has_on_scissor do ctx->on_scissor(solved_scissor)
        }
    }
}

_sort_active_views :: proc (ctx: ^Context) {
    slice.sort_by(ctx.active_views[:], less=proc (i, j: Active_View) -> bool {
        switch {
        case i.strata != j.strata   : return i.strata < j.strata
        case i.level  != j.level    : return i.level  < j.level
        case                        : return i.sid    < j.sid
        }
    })
}

_regenerate_active_text_tokens :: proc (ctx: ^Context) -> (text_height_mismatch: bool) {
    clear(&ctx.active_text_tokens)

    for &v in ctx.active_views {
        if .text not_in v.flags do continue

        if v.text == "" {
            v.solved_text_tokens = nil
            continue
        }

        v.solved_text_tokens = _text_tokenize(ctx, v.text)
        _text_measure_tokens(ctx, v.solved_text_tokens)

        context_w := v.solved_rect.w - v.padding[0] - v.padding[2]
        text_height := _text_wrap_tokens(ctx, v.solved_text_tokens, max_width=context_w)
        solved_rect_h := text_height + v.padding[1] + v.padding[3]
        if 0.1 < abs(v.solved_rect.h - solved_rect_h) do text_height_mismatch = true
        v.solved_rect.h = solved_rect_h
    }

    return
}

_propagate_active_views_opacity :: proc (ctx: ^Context) {
    for v in ctx.active_views {
        parent_opacity := v.parent != nil ? v.parent.solved_opacity : 1.0
        v.solved_opacity = parent_opacity * v.opacity
    }
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
    return ref_rect_to_screen(v.ctx, v.solved_rect)
}
