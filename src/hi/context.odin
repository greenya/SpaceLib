package hi

import "core:math"
import "core:math/linalg"
import "core:slice"
import "../core"

MAX_VIEWS               :: 2000
MAX_VISIBLE_VIEWS       :: 400
MAX_VISIBLE_TEXT_TOKENS :: 2000

MAX_VIEW_SOLVER_PASSES      :: 2
MAX_SCROLL_SOLVER_PASSES    :: 4

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
    on_event: proc (ctx: ^Context, event: Context_Event),

    // Scissor callback. Scissor should be disabled when `scissor == {}`.
    // The value is in ref units.
    on_scissor: proc (ctx: ^Context, scissor: Rect),

    // Text measure callback. Used only with `.text` views.
    // - `style` Current style
    //      * Use `text_style_font_height()` for current font height
    // - `type` Token type, expect only:
    //      * `.word` Letters/numbers/punctuations
    //      * `.whitespace` Spaces `" "` and tabs `"\t"`
    // - `text` Non-empty string to measure
    //
    // Returned value is in ref units.
    on_text_measure: proc (style: Text_Style, type: Text_Token_Type, text: string) -> (size: [2] f32),

    // Text style init callback. Used only with `.text` views.
    // Allows overriding default style (font, color, align, wrapping).
    //
    // Called once every time before traversing the tokens.
    // Expect to be called in both phases: updating and drawing.
    on_text_style_init: proc (v: ^View, style: ^Text_Style),

    // Text custom token callback. Used only with `.text` views.
    // - The callback is called for `Text_Token_Type.custom` tokens only. See all token types
    //   of `Text_Token_Type` to know what they do and which tag names are reserved.
    // - If `out_hint != nil`, you can change its properties. Setting `out_hint.scale` to
    //   non-zero value makes the token occupy physical space, e.g. for `|icon=sword|` you might
    //   want to set `out_hint.scale = 1`, which would occupy square of physical space for
    //   inline icon. Additionally, you can change `out_hint.baseline_ratio` default value,
    //   which is `style.font_baseline_ratio`.
    // - Update `style` for styling, use `style.user_*` to read/write your custom state.
    //
    // Called on every custom token in both phases: updating and drawing.
    on_text_custom_token: proc (v: ^View, style: ^Text_Style, name, args: string, out_hint: ^Text_Custom_Token_Hint),

    // Text wordy callback. Used only with `.text_wordy` views.
    // Allows specifying a separate text token buffer for large/heavy text views.
    //
    // `Visible_View.solved_text_tokens` will slice into this buffer.
    on_text_wordy: proc (v: ^View) -> (buf: ^[dynamic] Text_Token),

    // Fallback for all `.text` view drawing.
    // - Use `visible_text_iterate/next()` to iterate over the tokens
    // - Use `iterator.style` for current style information, e.g. font, color, user state
    //      * Use `text_style_font_height_screen()` for current font height in screen units
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
    views           : core.Sparse_Array(View, MAX_VIEWS),
    visible_views   : [dynamic; MAX_VISIBLE_VIEWS] Visible_View,
    visible_text_tokens : [MAX_VISIBLE_TEXT_TOKENS] Text_Token,
    visible_text_tokens_used: int,
    next_view_sid   : View_SID,
    root            : ^View, // Root view, created by `create_context()` and always set
    hit             : ^View, // Current mouse hit view from the last `update_context()`, or `nil`. The view and its native strata parents have `.hovered` set.

    updating        : bool, // If true, `update_context()` phase is currently running
    solving         : bool, // If true, `solve_context()` is currently running. If another solve is needed, queue it for later with `queue_solve_context()`.
    drawing         : bool, // If true, `draw_context()` phase is currently running

    solved          : bool, // If true, `update_context()` skips `solve_context()`. It is cleared automatically at some obvious moments like add/remove/re-parent views, screen-size changes etc. Call `queue_solve_context()` after direct layout-affecting mutations, e.g. changing `View.padding`.

    using init: Context_Init,

    dt: f32,
    time: f32,

    screen_size         : Vec2,
    screen_pixel_scale  : f32,
    screen_top_left     : Vec2,

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

    perf: Perf_State,
}

Mouse_Input :: struct {
    screen_pos  : Vec2,
    lmb_down    : bool,
    wheel_delta : f32,
}

Context_Event :: struct {
    type: Context_Event_Type,
}

Context_Event_Type :: enum {
    screen_size_changed,
    screen_pixel_scale_changed,
    solved,                     // The context was solved. Note: user call to `solve_context()` is silent.
}

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
    ensure(!ctx.drawing, "update_context() cannot be called while draw_context() is running")
    ensure(!ctx.updating, "update_context() is already running")

    when PERF_ON {
        _perf_frame_start(ctx)
        _perf_track_start(ctx, .update)
        defer _perf_track_stop(ctx, .update)
    }

    ctx.updating = true
    defer ctx.updating = false

    ctx.dt = dt
    ctx.time += dt

    if screen_size != ctx.screen_size {
        _set_screen_size(ctx, screen_size)
    }

    ctx.mouse = {
        input           = mouse_input,
        ref_pos         = screen_pos_to_ref(ctx, mouse_input.screen_pos),
        lmb_down_prev   = ctx.mouse.lmb_down,
        lmb_pressed     = !ctx.mouse.lmb_down && mouse_input.lmb_down,
    }

    if !ctx.solved {
        solve_context(ctx)
        if ctx.solved && ctx.on_event != nil {
            ctx->on_event({ type=.solved })
        }
    }

    visible_view_hit := _hit_test(ctx, ctx.mouse.ref_pos)
    _hit_set_view(ctx, visible_view_hit != nil ? visible_view_hit.view : nil)

    if ctx.hit != nil {
        click_consumed := ctx.mouse.lmb_pressed      && click(ctx.hit)
        wheel_consumed := ctx.mouse.wheel_delta != 0 && wheel(ctx.hit)
        ctx.mouse.consumed = click_consumed || wheel_consumed
    }

    _propagate_visible_views_opacity(ctx)
    _emit_visible_views_updated(ctx)

    if !ctx.solved {
        solve_context(ctx)
        _propagate_visible_views_opacity(ctx)
    }

    return ctx.mouse.consumed
}

// Re-solves all the visible state.
// - Rebuilds `Context.visible_views`
// - Rebuilds `Context.visible_text_tokens`
// - Updates `View.solved_*` for every *visible* view
// - Updates `Context.solved` and returns its value
//   (true, if all sub-solvers passed within internal pass limits)
//
// Note: This procedure is executed automatically by `update_context()` when context needs
// solving. Generally, after you do all the manual modifications to the views and at the end
// you do `queue_solve_context(ctx)`. But sometimes you need to solve the context to know
// updated (solved) values in advance, for example when spawning a tooltip -- after adding
// dynamic content to it, you want to reposition it (or re-anchor) if it happens to go partially
// off-screen, to do that you do manual call to `solve_context()` so your `tooltip.solved_rect`
// is updated, and now you can re-position/re-anchor the tooltip to fit the screen.
//
// Note: Use `solve_context_passes()` to allow repeated calling. In normal update flow,
// this is not necessary: if the context remains unsolved, the next `update_context()` will
// continue solving it automatically.
solve_context :: proc (ctx: ^Context) -> (solved: bool) {
    ensure(!ctx.drawing, "solve_context() cannot be called while draw_context() is running")
    ensure(!ctx.solving, "solve_context() is already running. Use queue_solve_context() to defer an extra pass.")

    when PERF_ON {
        _perf_track_start(ctx, .solve)
        defer _perf_track_stop(ctx, .solve)
    }

    ctx.solving = true
    defer ctx.solving = false

    view_solver_passed := true
    scroll_solver_passed := true

    clear(&ctx.visible_views)
    if .hidden in ctx.root.flags {
        ctx.solved = true
        return true
    }

    ctx.root.solved_rect = { 0, 0, ctx.ref_size.x, ctx.ref_size.y }
    ctx.root.solved_opacity = ctx.root.opacity
    ctx.root.solved_layout_child_count = 0
    append(&ctx.visible_views, Visible_View { ctx.root, {}, nil })

    for i in 0..<MAX_SCROLL_SOLVER_PASSES {
        if i > 0 do resize(&ctx.visible_views, 1) // keep root only

        for j in 0..<MAX_VIEW_SOLVER_PASSES {
            if j > 0 do resize(&ctx.visible_views, 1) // keep root only
            _solve_view_fit_and_fixed_size(ctx.root)
            _solve_children_fill_and_ratio_size(ctx.root, {})
            extent_mismatch, intext_mismatch := _regenerate_visible_text_tokens(ctx)
            view_solver_passed = !extent_mismatch && !intext_mismatch
            if view_solver_passed do break
        }

        _filter_intext_views(ctx)

        scroll_solver_passed = true
        for v in ctx.visible_views {
            scroll_min_ := scroll_min(v)
            new_scroll := Vec2 {
                clamp(v.scroll.x, scroll_min_.x, 0),
                clamp(v.scroll.y, scroll_min_.y, 0),
            }
            if new_scroll != v.scroll {
                // allow mutating v.scroll only for non-final pass
                if i < -1+MAX_SCROLL_SOLVER_PASSES do v.scroll = new_scroll
                scroll_solver_passed = false
            }
        }
        if scroll_solver_passed do break
    }

    _sort_visible_views(ctx)

    ctx.stats.visible_views_peak = max(ctx.stats.visible_views_peak, len(ctx.visible_views))
    ctx.solved = view_solver_passed && scroll_solver_passed
    return ctx.solved
}

// Run `solve_context()` up to `max_passes` times.
solve_context_passes :: proc (ctx: ^Context, max_passes: int) -> (solved: bool) {
    for _ in 0..<max_passes do if solve_context(ctx) do return true
    return
}

// Marks context unsolved for the next `update_context()` to call `solve_context()`
queue_solve_context :: proc (ctx: ^Context) {
    ctx.solved = false
}

draw_context :: proc (ctx: ^Context) {
    ensure(!ctx.updating, "draw_context() cannot be called while update_context() is running")
    ensure(!ctx.drawing, "draw_context() is already running")

    when PERF_ON do _perf_track_start(ctx, .draw)

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
            when PERF_ON do _perf_track_start(ctx, .draw_view)
            v->on_draw()
            when PERF_ON do _perf_track_stop(ctx, .draw_view)
        } else if .text in v.flags && has_on_draw_text && len(v.solved_text_tokens) > 0 {
            when PERF_ON do _perf_track_start(ctx, .draw_text)
            ctx.on_draw_text(&v)
            when PERF_ON do _perf_track_stop(ctx, .draw_text)
        }

        if .debug in v.flags {
            if solved_scissor != {} && has_on_scissor do ctx->on_scissor({})
            _debug_draw_view(&v, ctx.debug_draw_filter)
            if solved_scissor != {} && has_on_scissor do ctx->on_scissor(solved_scissor)
        }
    }

    when PERF_ON {
        _perf_track_stop(ctx, .draw)
        _perf_frame_stop(ctx)
    }

    if .debug in ctx.root.flags {
        if has_on_scissor do ctx->on_scissor({})
        if .stats in ctx.debug_draw_filter do _debug_draw_stats(ctx)
        when PERF_ON do if .perf in ctx.debug_draw_filter do _perf_draw(ctx)
    }
}

set_ref_font_height :: proc (ctx: ^Context, height: f32) {
    ensure(!ctx.solving)
    ensure(!ctx.drawing)

    if ctx.ref_font_height == height do return
    ctx.ref_font_height = height

    it := core.sparse_array_iterate(&ctx.views)
    for v in core.sparse_array_next(&it) {
        if .text_wordy in v.flags do clear(_text_wordy_buffer(v))
    }

    queue_solve_context(ctx)
}

_regenerate_visible_text_tokens :: proc (ctx: ^Context) -> (extent_mismatch, intext_mismatch: bool) {
    when PERF_ON {
        _perf_track_start(ctx, .text_total)
        defer _perf_track_stop(ctx, .text_total)
    }

    ctx.visible_text_tokens_used = 0

    for &v in ctx.visible_views {
        if .text not_in v.flags do continue

        _clear_children_intext_bound_flag(&v)

        if v.text == "" {
            v.solved_text_tokens = nil
            continue
        }

        if .text_wordy in v.flags {
            pool := _text_wordy_buffer(v)
            if len(pool) == 0 {
                when PERF_ON do _perf_track_start(ctx, .text_tokenize)
                v.solved_text_tokens = _text_tokenize(pool, v.text, .text_raw in v.flags)
                when PERF_ON do _perf_track_stop(ctx, .text_tokenize)
                when PERF_ON do _perf_track_start(ctx, .text_measure)
                _text_measure_tokens(&v)
                when PERF_ON do _perf_track_stop(ctx, .text_measure)
            } else {
                v.solved_text_tokens = pool[:]
            }
        } else {
            pool := slice.into_dynamic(ctx.visible_text_tokens[ctx.visible_text_tokens_used:len(ctx.visible_text_tokens)])
            when PERF_ON do _perf_track_start(ctx, .text_tokenize)
            v.solved_text_tokens = _text_tokenize(&pool, v.text, .text_raw in v.flags)
            when PERF_ON do _perf_track_stop(ctx, .text_tokenize)
            ctx.visible_text_tokens_used += len(v.solved_text_tokens)
            ctx.stats.visible_text_tokens_peak = max(ctx.stats.visible_text_tokens_peak, ctx.visible_text_tokens_used)
            assert(ctx.visible_text_tokens_used < len(ctx.visible_text_tokens), "Context.visible_text_tokens overflow; increase MAX_VISIBLE_TEXT_TOKENS or use .text_wordy for large text views")
            when PERF_ON do _perf_track_start(ctx, .text_measure)
            _text_measure_tokens(&v)
            when PERF_ON do _perf_track_stop(ctx, .text_measure)
        }

        if .text_fit_x in v.flags {
            when PERF_ON do _perf_track_start(ctx, .text_wrap)
            extent, v_intext_mismatch := _text_wrap_tokens(&v, 0)
            when PERF_ON do _perf_track_stop(ctx, .text_wrap)
            solved_w := extent.x + v.padding[0] + v.padding[2]
            solved_h := extent.y + v.padding[1] + v.padding[3]
            extent_mismatch ||= abs(solved_w-v.solved_rect.w)>.1 || abs(solved_h-v.solved_rect.h)>.1
            intext_mismatch ||= v_intext_mismatch
            v.solved_rect.w = solved_w
            v.solved_rect.h = solved_h
        } else {
            limit_x := v.solved_rect.w - v.padding[0] - v.padding[2]
            when PERF_ON do _perf_track_start(ctx, .text_wrap)
            extent, v_intext_mismatch := _text_wrap_tokens(&v, limit_x)
            when PERF_ON do _perf_track_stop(ctx, .text_wrap)
            solved_h := extent.y + v.padding[1] + v.padding[3]
            extent_mismatch ||= abs(solved_h-v.solved_rect.h)>.1
            intext_mismatch ||= v_intext_mismatch
            v.solved_rect.h = solved_h
        }
    }

    return
}

// Modifies `ctx.visible_views`, removes `.intext` views with their subtree if they are
// not `._intext_bound` or are fully clipped out. This must run after text wrapping so
// `.intext` views have their token-driven position.
_filter_intext_views :: proc (ctx: ^Context) {
    keep_i: int
    skip_root: ^View

    for v in ctx.visible_views {
        if skip_root != nil {
            if view_tree_contains(skip_root, v.view) do continue
            skip_root = nil
        }

        if .intext in v.flags {
            // We need to clip out bound .intext views here, because the solver skips scissor test
            // for .intext views as their position assigned later by text wrapping step

            clipped_out :=\
                v.solved_scissor != {} &&
                !core.rects_intersect(v.solved_scissor, v.solved_rect)

            if clipped_out || ._intext_bound not_in v.flags {
                skip_root = v.view
                continue
            }
        }

        ctx.visible_views[keep_i] = v
        keep_i += 1
    }

    resize(&ctx.visible_views, keep_i)
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

_propagate_visible_views_opacity :: proc (ctx: ^Context) {
    for v in ctx.visible_views {
        parent_opacity := v.parent != nil ? v.parent.solved_opacity : 1.0
        v.solved_opacity = parent_opacity * v.opacity
    }
}

_emit_visible_views_updated :: proc (ctx: ^Context) {
    // We cannot iterate over ctx.visible_views and call user event handler at the same time,
    // as user can solve_context() and rebuild ctx.visible_views

    Target :: struct { v: ^View, sid: View_SID }
    targets: [dynamic; MAX_VISIBLE_VIEWS] Target

    for v in ctx.visible_views {
        if .updating in v.flags {
            append(&targets, Target { v.view, v.sid })
        }
    }

    for t in targets {
        if t.v.sid == t.sid {
            _emit(t.v, { type=.updated })
        }
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
    pixel_scale_changed := new_pixel_scale != ctx.screen_pixel_scale

    ctx.screen_pixel_scale = new_pixel_scale
    ctx.screen_size = new_size
    ctx.screen_top_left = ctx.align_center\
        ? 0.5 * (new_size - ctx.ref_size * new_pixel_scale)\
        : {}

    if ctx.on_event != nil {
        ctx->on_event({ type=.screen_size_changed })
        if pixel_scale_changed {
            ctx->on_event({ type=.screen_pixel_scale_changed })
        }
    }

    queue_solve_context(ctx)
}

_hit_set_view :: proc (ctx: ^Context, new_hit: ^View) {
    old_hit := ctx.hit
    if old_hit == new_hit {
        ctx.hit = new_hit
        return
    }

    depth :: proc (v: ^View) -> (result: int) {
        for i := v; i != nil; i = _interaction_parent(i) do result += 1
        return
    }

    old_path := old_hit
    new_path := new_hit
    old_depth := depth(old_path)
    new_depth := depth(new_path)

    for old_depth > new_depth {
        old_path = _interaction_parent(old_path)
        old_depth -= 1
    }

    for new_depth > old_depth {
        new_path = _interaction_parent(new_path)
        new_depth -= 1
    }

    for old_path != new_path {
        old_path = _interaction_parent(old_path)
        new_path = _interaction_parent(new_path)
    }

    common_parent := old_path

    for v := old_hit; v != common_parent; v = _interaction_parent(v) {
        v.flags -= { .hovered }
        _emit(v, { type=.left })
    }

    for v := new_hit; v != common_parent; v = _interaction_parent(v) {
        v.flags += { .hovered }
        _emit(v, { type=.entered })
    }

    ctx.hit = new_hit
}

_hit_test :: proc (ctx: ^Context, ref_pos: Vec2) -> ^Visible_View {
    #reverse for &v in ctx.visible_views {
        if .hitless in v.flags do continue
        in_rect := core.vec_in_rect(ref_pos, v.solved_rect)
        in_scissor := v.solved_scissor != {}\
            ? core.vec_in_rect(ref_pos, v.solved_scissor)\
            : true
        if in_rect && in_scissor do return &v
    }
    return nil
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
