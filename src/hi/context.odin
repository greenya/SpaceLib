package hi

import "core:math"
import "core:math/linalg"
import "core:slice"
import "../core"

MAX_VIEWS               :: 2000
MAX_VISIBLE_VIEWS       :: 200
MAX_VISIBLE_TEXT_TOKENS :: 1000

Context_Init :: struct {
    // Reference size, e.g. 320x180, 1280x720
    ref_size: Vec2,

    // Reference font height, e.g. 8, 10, 16
    // This value is also used as a fallback for empty `scroll_step`.
    ref_font_height: f32,

    // Aspect ratio logic
    // - Fixed Aspect Ratio, value is `<0`
    // - Adaptive Aspect Ratio, a lerp ratio
    //      - `0.0` Full width
    //      - `0.5` Average
    //      - `1.0` Full height
    aspect_ratio_matching: f32,

    // The lower bound for `screen_pixel_scale`
    min_pixel_scale: f32,

    // If `true`, `screen_pixel_scale` is floored
    integer_scaling: bool,

    // If `true`, `screen_top_left` might not be `{0,0}`
    align_center: bool,

    // Scroll step used by `scroll_*_step()`, which can be used for mouse wheel scrolling.
    // If not set, the value of `ref_font_height` is used for vertical and horizontal step.
    scroll_step: Vec2,

    // Event callback
    on_event: Context_Event_Proc,

    // Scissor callback. Scissor should be disabled when `scissor == {}`.
    // The value is in ref units.
    on_scissor: Context_Scissor_Proc,

    // Text measure callback. Used only with `.text` views.
    // - `style` Current style
    //      * `ctx.ref_font_height * style.font_scale` current font size
    // - `type` Token type, expect only:
    //      * `.word` Letters/numbers/punctuations
    //      * `.whitespace` Spaces `" "` and tabs `"\t"`
    // - `text` Non-empty string to measure
    //
    // Returned value is in ref units.
    on_text_measure: Context_Text_Measure_Proc,

    // Text style callback. Used only with `.text` views.
    // Allows overriding default style (font, color, align, wrapping).
    //
    // Called once before traversing the tokens in both phases: updating and drawing.
    // Check `ctx.drawing` if need to know the phase.
    on_text_style: Context_Text_Style_Proc,

    // Text custom command callback. Used only with `.text` views.
    // - The callback is called for `Text_Token_Type.custom` tokens only. See all token types
    //   of `Text_Token_Type` to know what they do and which tag names are reserved.
    // - Return non-zero size (in ref units) for physical space, e.g. `[icon=sword]`.
    // - Update `style` for styling, use `style.user_*` to read/write your custom state.
    //
    // Called on every custom command in both phases: updating and drawing.
    // Check `ctx.drawing` if need to know the phase.
    on_text_custom_command: Context_Text_Custom_Command_Proc,

    // Text wordy callback. Used only with `.text_wordy` views.
    // Allows specifying a separate text token buffer for large/heavy text views.
    //
    // The buffer will be automatically cleared before use.
    // `View.solved_text_tokens` will slice into this buffer.
    on_text_wordy: Context_Text_Wordy_Proc,

    // Fallback for all `.text` view drawing.
    // - Use `visible_text_iterate/next()` to iterate over the tokens
    // - Use `iterator.style` for current style information, e.g. font, color, user state
    // - Use `ref_pos_to_screen()` for current token screen position
    //
    // Note: The call is skipped if `v.solved_text_tokens` is empty.
    on_draw_text: proc (v: ^Visible_View),

    // Debug draw filter. Used with `.debug` views and `debug_draw_*` callbacks. Default value is `~{}` (all types).
    debug_draw_filter: bit_set [Debug_Draw_Type],
    // Debug draw line callback. Used with `.debug` views.
    debug_draw_line: proc (from_screen, to_screen: Vec2, thick_screen: f32, color: Color),
    // Debug draw text callback. Used with `.debug` views.
    debug_draw_text: proc (text: string, pos_screen: Vec2, color: Color),
}

Context :: struct {
    views               : core.Sparse_Array(View, MAX_VIEWS),
    visible_views       : [dynamic; MAX_VISIBLE_VIEWS] Visible_View,
    visible_text_tokens : [MAX_VISIBLE_TEXT_TOKENS] Text_Token,
    visible_text_tokens_used: int,
    next_view_sid       : View_SID,
    root                : ^View, // Root view, created by `create_context()` and always set
    hit                 : ^View, // Current mouse hit view from the last `update_context()`, or nil. The view and its parents have `.hovered` set.
    solved              : bool, // If true, `update_context()` skips `solve_context()`. It is cleared automatically for add/remove/reparent and screen-size changes. Clear it manually after direct layout-affecting mutations, e.g. changing `View.padding`.
    drawing             : bool, // If true, `draw_context()` phase is currently running; useful when implementing custom text commands which should set some gpu or audio state and this should not be done when updating context, only when drawing

    using init: Context_Init,

    dt: f32,
    time: f32,

    screen_size         : Vec2,
    screen_pixel_scale  : f32,
    screen_top_left     : Vec2,
    screen_font_height  : f32,  // Floored value of `ref_font_size * screen_pixel_scale`, e.g. 20.0, 21.0, 22.0

    mouse: struct {
        using input     : Mouse_Input,  // The value passed to `update_context()`
        ref_pos         : Vec2,
        lmb_down_prev   : bool,
        lmb_pressed     : bool,         // For this frame only
        consumed        : bool,         // For this frame only
    },

    stats: struct {
        views_peak              : int,
        visible_views_peak      : int,
        visible_text_tokens_peak: int,
    },
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
Context_Text_Measure_Proc       :: proc (ctx: ^Context, style: Text_Style, type: Text_Token_Type, text: string) -> (size: [2] f32)
Context_Text_Style_Proc         :: proc (ctx: ^Context, style: ^Text_Style)
Context_Text_Custom_Command_Proc:: proc (ctx: ^Context, style: ^Text_Style, cmd, args: string) -> (size: [2] f32)
Context_Text_Wordy_Proc         :: proc (ctx: ^Context, v: ^View) -> (buf: ^[dynamic] Text_Token)

@require_results
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

    ctx.stats.views_peak = 1

    if ctx.debug_draw_filter == {} do ctx.debug_draw_filter = ~{}

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

    if !ctx.solved do solve_context(ctx)
    _propagate_visible_views_opacity(ctx)

    ctx.dt = dt
    ctx.time += dt

    ctx.mouse = {
        input           = mouse_input,
        ref_pos         = screen_pos_to_ref(ctx, mouse_input.screen_pos),
        lmb_down_prev   = ctx.mouse.lmb_down,
        lmb_pressed     = !ctx.mouse.lmb_down && mouse_input.lmb_down,
    }

    visible_view_hit := _hit_test(ctx, ctx.mouse.ref_pos)
    _hit_set_view(ctx, visible_view_hit != nil ? visible_view_hit.view : nil)

    if ctx.hit != nil {
        if ctx.mouse.lmb_pressed        do ctx.mouse.consumed ||= click(ctx.hit)
        if ctx.mouse.wheel_delta != 0   do ctx.mouse.consumed ||= wheel(ctx.hit)
    }

    // TODO: Animate and layout tree
    // animate_and_layout_tree(ctx.root, dt)

    for &v in ctx.visible_views {
        if .updating in v.flags {
            _emit(v, { type=.updated })
        }
    }

    return ctx.mouse.consumed
}

_hit_set_view :: proc (ctx: ^Context, new_hit: ^View) {
    old_hit := ctx.hit
    if old_hit == new_hit {
        ctx.hit = new_hit
        return
    }

    depth :: proc (v: ^View) -> (result: int) {
        for i := v; i != nil; i = i.parent do result += 1
        return
    }

    old_path := old_hit
    new_path := new_hit
    old_depth := depth(old_path)
    new_depth := depth(new_path)

    for old_depth > new_depth {
        old_path = old_path.parent
        old_depth -= 1
    }

    for new_depth > old_depth {
        new_path = new_path.parent
        new_depth -= 1
    }

    for old_path != new_path {
        old_path = old_path.parent
        new_path = new_path.parent
    }

    common_parent := old_path

    for v := old_hit; v != common_parent; v = v.parent {
        v.flags -= { .hovered }
        _emit(v, { type=.left })
    }

    for v := new_hit; v != common_parent; v = v.parent {
        v.flags += { .hovered }
        _emit(v, { type=.entered })
    }

    ctx.hit = new_hit
}

_hit_test :: proc (ctx: ^Context, ref_pos: Vec2) -> ^Visible_View {
    #reverse for &v in ctx.visible_views {
        in_rect := core.vec_in_rect(ref_pos, v.solved_rect)
        in_scissor := v.solved_scissor != {}\
            ? core.vec_in_rect(ref_pos, v.solved_scissor)\
            : true
        if in_rect && in_scissor do return &v
    }
    return nil
}

// - Rebuilds `Context.visible_views`
// - Rebuilds `Context.visible_text_tokens`
// - Updates `View.solved` for every *visible* view
// - Sets `Context.solved`
//
// Note: This procedure is executed automatically by `update_context()` when `Context.solved` is cleared.
// Generally, after you do all the manual modifications to the views and at the end you do `ctx.solved = false`.
// But sometimes you need to solve the context to know updated (solved) values in advance, for example when
// spawning a tooltip -- after adding dynamic content to the tooltip, you want to reposition it (or re-anchor)
// if it happens to go partially off-screen, to do that you do manual call to `solve_context()` so your
// `tooltip.solved_rect` is updated, and now you can check that and re-position/re-anchor the tooltip to fit
// the screen.
solve_context :: proc (ctx: ^Context) {
    clear(&ctx.visible_views)

    defer {
        ctx.stats.visible_views_peak = max(ctx.stats.visible_views_peak, len(ctx.visible_views))
        ctx.stats.visible_text_tokens_peak = max(ctx.stats.visible_text_tokens_peak, ctx.visible_text_tokens_used)

        ctx.solved = true
        if ctx.on_event != nil {
            ctx->on_event({ type=.solved })
        }
    }

    if .hidden in ctx.root.flags do return

    ctx.root.solved_rect = { 0, 0, ctx.ref_size.x, ctx.ref_size.y }
    ctx.root.solved_opacity = ctx.root.opacity
    ctx.root.solved_layout_child_count = 0
    append(&ctx.visible_views, Visible_View { ctx.root, {}, nil })

    // never repeat layout and text measurement more than twice
    for i in 0..<2 {
        if i > 0 do resize(&ctx.visible_views, 1) // keep root only
        _solve_view_fit_and_fixed_size(ctx.root)
        _solve_children_fill_and_ratio_size(ctx.root, {})
        extent_mismatch := _regenerate_visible_text_tokens(ctx)
        if !extent_mismatch do break
    }

    _sort_visible_views(ctx)
}

draw_context :: proc (ctx: ^Context) {
    ctx.drawing = true
    defer ctx.drawing = false

    solved_scissor: Rect = {-1,-1,-1,-1}
    has_on_scissor := ctx.on_scissor != nil
    has_on_draw_text := ctx.on_draw_text != nil

    for &v in ctx.visible_views {
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
            _debug_draw_view(&v, ctx.debug_draw_filter)
            if solved_scissor != {} && has_on_scissor do ctx->on_scissor(solved_scissor)
        }
    }

    if .debug in ctx.root.flags && .stats in ctx.debug_draw_filter {
        if has_on_scissor do ctx->on_scissor({})
        _debug_draw_stats(ctx)
    }
}

_sort_visible_views :: proc (ctx: ^Context) {
    slice.sort_by(ctx.visible_views[:], less=proc (i, j: Visible_View) -> bool {
        switch {
        case i.strata != j.strata   : return i.strata < j.strata
        case i.level  != j.level    : return i.level  < j.level
        case                        : return i.sid    < j.sid
        }
    })
}

_regenerate_visible_text_tokens :: proc (ctx: ^Context) -> (extent_mismatch: bool) {
    ctx.visible_text_tokens_used = 0

    for &v in ctx.visible_views {
        if .text not_in v.flags do continue

        if v.text == "" {
            v.solved_text_tokens = nil
            continue
        }

        if .text_wordy in v.flags {
            pool: ^[dynamic] Text_Token
            assert(ctx.on_text_wordy != nil, "Context.on_text_wordy must be set when using .text_wordy views")
            pool = ctx->on_text_wordy(v)
            assert(pool != nil, "Context.on_text_wordy must not return nil")
            clear(pool)
            v.solved_text_tokens = _text_tokenize(pool, v.text, .text_literal in v.flags)
        } else {
            pool := slice.into_dynamic(ctx.visible_text_tokens[ctx.visible_text_tokens_used:len(ctx.visible_text_tokens)])
            v.solved_text_tokens = _text_tokenize(&pool, v.text, .text_literal in v.flags)
            ctx.visible_text_tokens_used += len(v.solved_text_tokens)
            assert(ctx.visible_text_tokens_used < len(ctx.visible_text_tokens), "Context.visible_text_tokens overflow; increase MAX_VISIBLE_TEXT_TOKENS or use .text_wordy for large text views")
        }

        _text_measure_tokens(ctx, v.solved_text_tokens)

        if .text_fit_x in v.flags {
            extent := _text_wrap_tokens(ctx, v.solved_text_tokens, 0)
            solved_w := extent.x + v.padding[0] + v.padding[2]
            solved_h := extent.y + v.padding[1] + v.padding[3]
            if abs(solved_w-v.solved_rect.w)>.1 || abs(solved_h-v.solved_rect.h)>.1 do extent_mismatch = true
            v.solved_rect.w = solved_w
            v.solved_rect.h = solved_h
        } else {
            limit_x := v.solved_rect.w - v.padding[0] - v.padding[2]
            extent := _text_wrap_tokens(ctx, v.solved_text_tokens, limit_x)
            solved_h := extent.y + v.padding[1] + v.padding[3]
            if abs(solved_h-v.solved_rect.h)>.1 do extent_mismatch = true
            v.solved_rect.h = solved_h
        }
    }

    return
}

_propagate_visible_views_opacity :: proc (ctx: ^Context) {
    for v in ctx.visible_views {
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
        new_font_height := math.floor(ctx.ref_font_height * new_pixel_scale)
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

@require_results
screen_pos_to_ref :: proc (ctx: ^Context, screen_pos: Vec2) -> Vec2 {
    return (screen_pos-ctx.screen_top_left) / ctx.screen_pixel_scale
}

@require_results
screen_size_to_ref :: proc (ctx: ^Context, screen_size: Vec2) -> Vec2 {
    return screen_size / ctx.screen_pixel_scale
}

@require_results
ref_pos_to_screen :: proc (ctx: ^Context, ref_pos: Vec2) -> Vec2 {
    return ctx.screen_top_left + (ref_pos * ctx.screen_pixel_scale)
}

@require_results
ref_size_to_screen :: proc (ctx: ^Context, ref_size: Vec2) -> Vec2 {
    return ref_size * ctx.screen_pixel_scale
}

@require_results
ref_rect_to_screen :: proc (ctx: ^Context, ref_rect: Rect) -> Rect {
    return {
        **ref_pos_to_screen(ctx, { ref_rect.x, ref_rect.y }),
        **ref_size_to_screen(ctx, { ref_rect.w, ref_rect.h }),
    }
}

@require_results
ref_view_to_screen :: proc (v: ^View) -> Rect {
    return ref_rect_to_screen(v.ctx, v.solved_rect)
}
