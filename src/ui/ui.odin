package spacelib_ui

import "core:slice"
import "core:time"
import "../core"

UI :: struct {
    // Root frame.
    root: ^Frame,

    // Mouse state passed to `tick()`.
    mouse       : Mouse_Input,
    mouse_prev  : Mouse_Input,

    // Clock.
    // Use `clock.time` and `clock.dt` for timing and smooth updates.
    // Adjust `clock.time_scale` to control the speed of all animations.
    clock: core.Clock(f32),

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
    // Useful when drawing heavy frame and need to perform scissor tests yourself so large chunks of drawing
    // can be discarded quickly.
    //
    // This value may change between frame `draw` calls, and represents the intersection of all parent scissors,
    // defining the actual visible area on screen for the frame currently being drawn.
    //
    // You can apply extra scissor rects via pair `push_scissor_rect()` and `pop_scissor_rect()`.
    scissor_rect: Rect,

    // Current stack of all scissor absolute rectangles.
    scissor_rects: core.Stack(Rect, 16),

    // Callback for applying scissor rectangle during drawing phase.
    scissor_set_proc: Scissor_Set_Proc,

    // Callback for clearing scissor rectangle during drawing phase.
    scissor_clear_proc: Scissor_Clear_Proc,

    // Fallback drawing callback for `.terse` frames.
    // Used when a frame does not have its own `draw` callback.
    terse_draw_proc: Frame_Proc,

    // Fallback clicking callback for `.terse` frames.
    // Used when a frame does not have its own `click` callback.
    // Useful to handle clicks on groups in terse content, for example, navigation links.
    terse_click_proc: Frame_Proc,

    // Callback for extra drawing for every frame.
    // Called after frame's `draw` and before drawing any children.
    frame_overdraw_proc: Frame_Proc,

    // Usage statistics counters.
    // Automatically reset at the start of each `tick()` and updated until the end of `draw()`.
    // Accurate values are expected only after all phases are complete.
    stats: Stats,
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

create :: proc (
    root_rect               : Rect = {},
    scissor_set_proc        : Scissor_Set_Proc = nil,
    scissor_clear_proc      : Scissor_Clear_Proc = nil,
    terse_draw_proc         : Frame_Proc = nil,
    terse_click_proc        : Frame_Proc = nil,
    frame_overdraw_proc     : Frame_Proc = nil,
) -> ^UI {
    ui := new(UI)
    ui^ = {
        root = add_frame(nil, {
            flags   = { .pass_self },
            rect    = root_rect,
        }),

        scissor_set_proc        = scissor_set_proc,
        scissor_clear_proc      = scissor_clear_proc,
        terse_draw_proc         = terse_draw_proc,
        terse_click_proc        = terse_click_proc,
        frame_overdraw_proc     = frame_overdraw_proc,
    }

    ui.root.ui = ui

    core.clock_init(&ui.clock)

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

    core.clock_tick(&ui.clock)

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
            if passing(f) do continue
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

                // keep entered state for all parents of the captured frame until uncaptured
                if f.parent != nil do for i:=f.parent; i!=nil; i=i.parent {
                    if i.entered_prev do i.entered = true
                }

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

                d.target = nil
                #reverse for k in ui.mouse_frames do if k != f && !passing(k) {
                    d.target = k
                    break
                }

                drag(ui.captured.frame, ui.captured.drag)
            }

            if lmb_released || !keep_capture {
                if ui.captured.frame != nil && ui.captured.frame.entered {
                    click(ui.captured.frame)
                }
                ui.captured = {}
            }
        }

        if mouse.wheel_dy != 0 do #reverse for f in ui.mouse_frames {
            if passing(f) do continue
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

    assert(ui.scissor_rects.size == 0, "Mismatched push/pop_scissor_rect() calls")
    ui.scissor_rect = ui.root.rect

    draw_frame_tree(ui.root)
}

push_scissor_rect :: proc (ui: ^UI, new_rect: Rect) {
    assert(ui.phase != .none)

    new_rect := new_rect

    if ui.scissor_rects.size > 0 {
        new_rect = core.rect_intersection(new_rect, core.stack_top(ui.scissor_rects))
    }

    core.stack_push(&ui.scissor_rects, new_rect)

    ui.scissor_rect = new_rect
    if ui.phase == .draw && ui.scissor_set_proc != nil {
        ui.scissor_set_proc(new_rect)
        ui.stats.scissors_set += 1
    }
}

pop_scissor_rect :: proc (ui: ^UI) {
    assert(ui.phase != .none)

    core.stack_drop(&ui.scissor_rects)

    if ui.scissor_rects.size > 0 {
        ui.scissor_rect = core.stack_top(ui.scissor_rects)
        if ui.phase == .draw && ui.scissor_set_proc != nil do ui.scissor_set_proc(ui.scissor_rect)
    } else {
        ui.scissor_rect = ui.root.rect
        if ui.phase == .draw && ui.scissor_clear_proc != nil do ui.scissor_clear_proc()
    }
}

@private
forget_frame :: proc (ui: ^UI, f: ^Frame) {
    assert(f != nil)

    if ui.captured.frame == f       do ui.captured.frame = nil
    if ui.captured.drag.target == f do ui.captured.drag.target = nil

    known_frame_arrays := [?] ^[dynamic] ^Frame {
        &ui.mouse_frames,
        &ui.entered_frames,
        &ui.auto_hide_frames,
    }

    for arr in known_frame_arrays {
        for i := len(arr)-1; i >= 0; i -= 1 {
            if f == arr[i] {
                unordered_remove(arr, i)
            }
        }
    }
}
