package spacelib_ui

import "core:slice"
import "core:time"
import "../core"
import "../terse"

UI :: struct {
    root                : ^Frame,

    mouse               : Mouse_Input,
    prev_mouse          : Mouse_Input,

    phase               : Processing_Phase,
    captured            : Captured_Info,

    mouse_frames        : [dynamic] ^Frame,
    entered_frames      : [dynamic] ^Frame,
    auto_hide_frames    : [dynamic] ^Frame,

    scissor_rect        : Rect,
    scissor_rects       : [dynamic] Rect,
    scissor_set_proc    : Scissor_Set_Proc,
    scissor_clear_proc  : Scissor_Clear_Proc,

    terse_query_font_proc   : terse.Query_Font_Proc,
    terse_query_color_proc  : terse.Query_Color_Proc,
    terse_draw_proc         : Terse_Draw_Proc,

    overdraw_proc       : Frame_Proc,

    stats               : Stats,
}

Mouse_Input :: struct {
    pos     : Vec2,
    wheel_dy: f32,
    lmb_down: bool,
}

Processing_Phase :: enum {
    none,
    updating,
    drawing,
}

Captured_Info :: struct {
    outside : bool,
    frame   : ^Frame,
    pos     : Vec2,
}

Stats :: struct {
    updating_time   : time.Duration,
    drawing_time    : time.Duration,
    frames_total    : int,
    frames_drawn    : int,
    scissors_set    : int,
}

Scissor_Set_Proc    :: proc (r: Rect)
Scissor_Clear_Proc  :: proc ()
Terse_Draw_Proc     :: proc (terse: ^terse.Terse)

create_ui :: proc (
    scissor_set_proc        : Scissor_Set_Proc = nil,
    scissor_clear_proc      : Scissor_Clear_Proc = nil,
    terse_query_font_proc   : terse.Query_Font_Proc = nil,
    terse_query_color_proc  : terse.Query_Color_Proc = nil,
    terse_draw_proc         : Terse_Draw_Proc = nil,
    overdraw_proc           : Frame_Proc = nil,
) -> ^UI {
    ui := new(UI)
    ui.scissor_set_proc = scissor_set_proc
    ui.scissor_clear_proc = scissor_clear_proc
    ui.terse_query_font_proc = terse_query_font_proc
    ui.terse_query_color_proc = terse_query_color_proc
    ui.terse_draw_proc = terse_draw_proc
    ui.overdraw_proc = overdraw_proc
    ui.root = add_frame(nil, { flags={ .pass } })
    return ui
}

destroy_ui :: proc (ui: ^UI) {
    destroy_frame_tree(ui.root)
    delete(ui.mouse_frames)
    delete(ui.entered_frames)
    delete(ui.auto_hide_frames)
    delete(ui.scissor_rects)
    free(ui)
}

update_ui :: proc (ui: ^UI, root_rect: Rect, mouse: Mouse_Input) -> (mouse_input_consumed: bool) {
    ui.stats = {}
    phase_started := time.tick_now()
    ui.phase = .updating
    defer {
        ui.phase = .none
        ui.stats.updating_time = time.tick_since(phase_started)
    }

    ui.root.rect = root_rect
    ui.scissor_rect = root_rect

    ui.mouse = mouse
    lmb_pressed := !ui.prev_mouse.lmb_down && ui.mouse.lmb_down
    lmb_released := ui.prev_mouse.lmb_down && !ui.mouse.lmb_down

    clear(&ui.mouse_frames)
    clear(&ui.auto_hide_frames)

    mark_frame_tree_rect_dirty(ui.root, ui)
    update_frame_tree(ui.root, ui)

    if !ui.captured.outside {
        #reverse for f in ui.mouse_frames {
            if .pass in f.flags do continue
            if ui.captured.frame != nil && ui.captured.frame != f do continue

            mouse_input_consumed = true

            f.hovered = true
            if !f.prev_hovered {
                append(&ui.entered_frames, f)
                if f.enter != nil do f.enter(f)
            }

            if lmb_pressed do ui.captured = { frame=f, pos=ui.mouse.pos-{f.rect.x,f.rect.y} }

            break
        }

        if ui.captured.frame != nil {
            mouse_input_consumed = true

            ui.captured.frame.captured = true
            drag(ui.captured.frame, ui.mouse.pos, ui.captured.pos)

            if lmb_released {
                if ui.captured.frame.hovered do click(ui.captured.frame)
                ui.captured = {}
            }
        }

        if mouse.wheel_dy != 0 do #reverse for f in ui.mouse_frames {
            if .pass in f.flags do continue
            consumed := wheel(f, mouse.wheel_dy)
            if consumed do break
        }
    }

    for i := len(ui.entered_frames) - 1; i >= 0; i -= 1 {
        f := ui.entered_frames[i]
        if f.prev_hovered && !f.hovered {
            unordered_remove(&ui.entered_frames, i)
            if f.leave != nil do f.leave(f)
        }
    }

    if lmb_pressed do for f in ui.auto_hide_frames {
        if .hidden not_in f.flags {
            _, found := slice.linear_search_reverse(ui.mouse_frames[:], f)
            if !found do f.flags += { .hidden }
        }
    }

    if !mouse_input_consumed && lmb_pressed do ui.captured = { outside=true }
    if ui.captured.outside && lmb_released do ui.captured = {}

    ui.prev_mouse = mouse
    return
}

draw_ui :: proc (ui: ^UI) {
    phase_started := time.tick_now()
    ui.phase = .drawing
    defer {
        ui.phase = .none
        ui.stats.drawing_time = time.tick_since(phase_started)
    }

    assert(len(ui.scissor_rects) == 0)
    ui.scissor_rect = ui.root.rect

    draw_frame_tree(ui.root, ui)
}

@private
push_scissor_rect :: proc (ui: ^UI, new_rect: Rect) {
    assert(ui.phase != .none)

    new_rect := new_rect

    last_rect := slice.last_ptr(ui.scissor_rects[:])
    if last_rect != nil {
        new_rect = core.rect_intersection(new_rect, last_rect^)
    }

    append(&ui.scissor_rects, new_rect)
    ui.scissor_rect = new_rect
    if ui.phase == .drawing && ui.scissor_set_proc != nil {
        ui.scissor_set_proc(new_rect)
        ui.stats.scissors_set += 1
    }
}

@private
pop_scissor_rect :: proc (ui: ^UI) {
    assert(ui.phase != .none)
    assert(len(ui.scissor_rects) > 0)

    pop(&ui.scissor_rects)

    last_rect := slice.last_ptr(ui.scissor_rects[:])
    if last_rect != nil {
        ui.scissor_rect = last_rect^
        if ui.phase == .drawing && ui.scissor_set_proc != nil do ui.scissor_set_proc(last_rect^)
    } else {
        ui.scissor_rect = ui.root.rect
        if ui.phase == .drawing && ui.scissor_clear_proc != nil do ui.scissor_clear_proc()
    }
}
