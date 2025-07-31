package spacelib_ui

import "core:slice"
import "core:time"
import "../core"
import "../core/clock"
import "../core/stack"
import "../terse"

UI :: struct {
    // Root frame.
    root: ^Frame,

    // Mouse state passed to `tick()`.
    mouse       : Mouse_Input,
    mouse_prev  : Mouse_Input,

    // Clock.
    // Use `clock.time` and `clock.dt` for timing and smooth updates.
    // Adjust `clock.time_scale` to control the speed of all animations.
    clock: clock.Clock(f32),

    // Processing phase.
    // This value is usually not needed, as each frame's callback runs in a known phase:
    // `draw` and `draw_after` are called during the `.draw` phase; all others during the `.tick` phase.
    phase: Processing_Phase,

    // Mouse capture state.
    // Typically not needed directly, as `Frame.captured` reflects this state within any frame's callback.
    captured: Captured_Info,

    // Visible frames currently under the mouse cursor, updated every tick.
    mouse_frames: [dynamic] ^Frame,
    // Frames that received the `enter` event (candidates for future `leave` event).
    entered_frames: [dynamic] ^Frame,
    // Frames with `.auto_hide` flag, updated every tick.
    auto_hide_frames: [dynamic] ^Frame,

    // Current scissor absolute rectangle.
    // Usually not needed directly, as it is automatically applied during a child frame's `draw` callback.
    // This value may change between frame `draw` calls, and represents the intersection of all parent scissors,
    // defining the actual visible area on screen for the frame currently being drawn.
    scissor_rect: Rect,

    // Current stack of all scissor absolute rectangles.
    scissor_rects: stack.Stack(Rect, 16),

    // Callback for applying scissor rectangle during drawing phase.
    scissor_set_proc: Scissor_Set_Proc,

    // Callback for clearing scissor rectangle during drawing phase.
    scissor_clear_proc: Scissor_Clear_Proc,

    // Callback for querying font information. Should be set if you use `.terse` frames.
    terse_query_font_proc: terse.Query_Font_Proc,

    // Callback for querying color information. Should be set if you use `.terse` frames.
    terse_query_color_proc: terse.Query_Color_Proc,

    // Fallback drawing callback for `.terse` frames.
    // Used when a frame does not have its own `draw` callback.
    terse_draw_proc: Terse_Draw_Proc,

    // Callback for extra drawing for every frame. Called after frame's `draw` and before drawing any children.
    frame_overdraw_proc: Frame_Proc,

    // Usage statistics counters.
    // Automatically reset at the start of each `tick()` and updated until the end of `draw()`.
    // Access these values only after all phases are complete, e.g., at the end of the main loop.
    stats: Stats,

    // Shortcut for `get(ui.root, ...)`
    get: proc (ui: ^UI, path: string) -> ^Frame,
    // Shortcut for `find(ui.root, ...)`
    find: proc (ui: ^UI, path: string) -> ^Frame,
    // Shortcut for `show(ui.root, ...)`
    show: proc (ui: ^UI, path: string, hide_siblings := false),
    // Shortcut for `hide(ui.root, ...)`
    hide: proc (ui: ^UI, path: string),
    // Shortcut for `click(ui.root, ...)`
    click: proc (ui: ^UI, path: string),
    // Shortcut for `wheel(ui.root, ...)`
    wheel: proc (ui: ^UI, path: string, dy: f32) -> (consumed: bool),
    // Shortcut for `animate(ui.root, ...)`
    animate: proc (ui: ^UI, path: string, tick: Frame_Proc, dur: f32),
    // Shortcut for `set_name(ui.root, ...)`
    set_name: proc (ui: ^UI, path: string, name: string),
    // Shortcut for `set_text(ui.root, ...)`
    set_text: proc (ui: ^UI, path: string, values: ..any, shown := false),
    // Shortcut for `set_text_format(ui.root, ...)`
    set_text_format: proc (ui: ^UI, path: string, text_format: string),
}

Mouse_Input :: struct {
    pos     : Vec2,
    wheel_dy: f32,
    lmb_down: bool,
}

Processing_Phase :: enum {
    none,
    tick,
    draw,
}

Captured_Info :: struct {
    outside : bool,
    frame   : ^Frame,
    drag    : Drag_Info,
}

Stats :: struct {
    tick_time   : time.Duration,
    draw_time   : time.Duration,
    frames_total: int,
    frames_drawn: int,
    scissors_set: int,
}

Scissor_Set_Proc    :: proc (r: Rect)
Scissor_Clear_Proc  :: proc ()
Terse_Draw_Proc     :: proc (terse: ^terse.Terse)

create :: proc (
    scissor_set_proc        : Scissor_Set_Proc = nil,
    scissor_clear_proc      : Scissor_Clear_Proc = nil,
    terse_query_font_proc   : terse.Query_Font_Proc = nil,
    terse_query_color_proc  : terse.Query_Color_Proc = nil,
    terse_draw_proc         : Terse_Draw_Proc = nil,
    frame_overdraw_proc     : Frame_Proc = nil,
) -> ^UI {
    ui := new(UI)

    ui^ = {
        root                    = add_frame(nil, { flags={.pass_self} }),

        scissor_set_proc        = scissor_set_proc,
        scissor_clear_proc      = scissor_clear_proc,
        terse_query_font_proc   = terse_query_font_proc,
        terse_query_color_proc  = terse_query_color_proc,
        terse_draw_proc         = terse_draw_proc,
        frame_overdraw_proc     = frame_overdraw_proc,

        get                     = ui_get,
        find                    = ui_find,
        show                    = ui_show,
        hide                    = ui_hide,
        click                   = ui_click,
        wheel                   = ui_wheel,
        animate                 = ui_animate,
        set_name                = ui_set_name,
        set_text                = ui_set_text,
        set_text_format         = ui_set_text_format,
    }

    clock.init(&ui.clock)

    ui.root.ui = ui
    return ui
}

destroy :: proc (ui: ^UI) {
    destroy_frame_tree(ui.root)
    delete(ui.mouse_frames)
    delete(ui.entered_frames)
    delete(ui.auto_hide_frames)
    free(ui)
}

reset_terse :: proc (ui: ^UI) {
    destroy_terse_in_frame_tree(ui.root)
}

tick :: proc (ui: ^UI, root_rect: Rect, mouse: Mouse_Input) -> (mouse_input_consumed: bool) {
    ui.stats = {}
    phase_started := time.tick_now()
    ui.phase = .tick
    defer {
        ui.mouse_prev = mouse
        ui.phase = .none
        ui.stats.tick_time = time.tick_since(phase_started)
    }

    clock.tick(&ui.clock)

    ui.root.rect = root_rect
    ui.scissor_rect = root_rect

    ui.mouse = mouse
    lmb_pressed := !ui.mouse_prev.lmb_down && ui.mouse.lmb_down
    lmb_released := ui.mouse_prev.lmb_down && !ui.mouse.lmb_down

    clear(&ui.mouse_frames)
    clear(&ui.auto_hide_frames)

    prepare_frame_tree(ui.root)
    update_frame_tree(ui.root)

    if !ui.captured.outside {
        keep_capture := ui.captured.frame != nil

        #reverse for f in ui.mouse_frames {
            if passed(f) do continue
            if keep_capture && ui.captured.frame != nil && ui.captured.frame != f do continue

            mouse_input_consumed = true

            for i:=f; i!=nil; i=i.parent {
                i.entered = true
                if !i.entered_prev {
                    i.entered_time = ui.clock.time
                    append(&ui.entered_frames, i)
                    if i.enter != nil do i.enter(i)
                }
            }

            if lmb_pressed && ui.captured.frame == nil && .disabled not_in f.flags {
                ui.captured = { frame=f }
                if .capture in f.flags do keep_capture = true
            }

            break
        }

        if ui.captured.frame != nil {
            mouse_input_consumed = true

            if keep_capture {
                f := ui.captured.frame
                d := &ui.captured.drag

                f.captured = true

                switch {
                case lmb_pressed:
                    assert(d^ == {})
                    d^ = {
                        phase           = .start,
                        start_mouse_pos = ui.mouse.pos,
                        start_offset    = ui.mouse.pos - {f.rect.x,f.rect.y},
                    }
                case lmb_released:
                    d.phase = .end
                case:
                    d.phase = .dragging
                }

                new_total_offset := ui.mouse.pos - d.start_mouse_pos
                d.delta = new_total_offset - d.total_offset
                d.total_offset = new_total_offset

                drag(f, d^)
            }

            if lmb_released || !keep_capture {
                if ui.captured.frame.entered do click(ui.captured.frame)
                ui.captured = {}
            }
        }

        if mouse.wheel_dy != 0 do #reverse for f in ui.mouse_frames {
            if passed(f) do continue
            consumed := wheel(f, mouse.wheel_dy)
            if consumed do break
        }
    }

    for i := len(ui.entered_frames) - 1; i >= 0; i -= 1 {
        f := ui.entered_frames[i]
        if !f.entered {
            f.left_time = ui.clock.time
            unordered_remove(&ui.entered_frames, i)
            if f.leave != nil do f.leave(f)
        }
    }

    if lmb_pressed do for f in ui.auto_hide_frames {
        if .hidden not_in f.flags {
            _, found := slice.linear_search_reverse(ui.mouse_frames[:], f)
            if !found do hide(f)
        }
    }

    if !mouse_input_consumed && lmb_pressed do ui.captured = { outside=true }
    if ui.captured.outside && lmb_released do ui.captured = {}

    return
}

draw :: proc (ui: ^UI) {
    phase_started := time.tick_now()
    ui.phase = .draw
    defer {
        ui.phase = .none
        ui.stats.draw_time = time.tick_since(phase_started)
    }

    assert(ui.scissor_rects.size == 0)
    ui.scissor_rect = ui.root.rect

    draw_frame_tree(ui.root)
}

@private
push_scissor_rect :: proc (ui: ^UI, new_rect: Rect) {
    assert(ui.phase != .none)

    new_rect := new_rect

    if ui.scissor_rects.size > 0 {
        new_rect = core.rect_intersection(new_rect, stack.top(ui.scissor_rects))
    }

    stack.push(&ui.scissor_rects, new_rect)

    ui.scissor_rect = new_rect
    if ui.phase == .draw && ui.scissor_set_proc != nil {
        ui.scissor_set_proc(new_rect)
        ui.stats.scissors_set += 1
    }
}

@private
pop_scissor_rect :: proc (ui: ^UI) {
    assert(ui.phase != .none)

    stack.drop(&ui.scissor_rects)

    if ui.scissor_rects.size > 0 {
        ui.scissor_rect = stack.top(ui.scissor_rects)
        if ui.phase == .draw && ui.scissor_set_proc != nil do ui.scissor_set_proc(ui.scissor_rect)
    } else {
        ui.scissor_rect = ui.root.rect
        if ui.phase == .draw && ui.scissor_clear_proc != nil do ui.scissor_clear_proc()
    }
}

@private
ui_get :: #force_inline proc (ui: ^UI, path: string) -> ^Frame {
    return get(ui.root, path)
}

@private
ui_find :: #force_inline proc (ui: ^UI, path: string) -> ^Frame {
    return find(ui.root, path)
}

@private
ui_show :: #force_inline proc (ui: ^UI, path: string, hide_siblings := false) {
    show_by_path(ui.root, path, hide_siblings=hide_siblings)
}

@private
ui_hide :: #force_inline proc (ui: ^UI, path: string) {
    hide_by_path(ui.root, path)
}

@private
ui_click :: #force_inline proc (ui: ^UI, path: string) {
    click_by_path(ui.root, path)
}

@private
ui_wheel :: #force_inline proc (ui: ^UI, path: string, dy: f32) -> (consumed: bool) {
    return wheel_by_path(ui.root, path, dy)
}

@private
ui_animate :: #force_inline proc (ui: ^UI, path: string, tick: Frame_Proc, dur: f32) {
    animate(get(ui.root, path), tick, dur)
}

@private
ui_set_name :: #force_inline proc (ui: ^UI, path: string, name: string) {
    set_name(get(ui.root, path), name)
}

@private
ui_set_text :: #force_inline proc (ui: ^UI, path: string, values: ..any, shown := false) {
    set_text(get(ui.root, path), ..values, shown=shown)
}

@private
ui_set_text_format :: #force_inline proc (ui: ^UI, path: string, text_format: string) {
    set_text_format(get(ui.root, path), text_format)
}
