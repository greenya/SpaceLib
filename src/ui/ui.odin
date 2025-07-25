package spacelib_ui

// import "core:fmt"
import "core:slice"
import "core:time"
import "../clock"
import "../core"
import "../terse"

UI :: struct {
    root                : ^Frame,

    mouse               : Mouse_Input,
    mouse_prev          : Mouse_Input,

    clock               : clock.Clock(f32),
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

    frame_overdraw_proc : Frame_Proc,
    stats               : Stats,

    get                 : proc (ui: ^UI, path: string) -> ^Frame,
    find                : proc (ui: ^UI, path: string) -> ^Frame,
    show                : proc (ui: ^UI, path: string, hide_siblings := false),
    hide                : proc (ui: ^UI, path: string),
    click               : proc (ui: ^UI, path: string),
    wheel               : proc (ui: ^UI, path: string, dy: f32) -> (consumed: bool),
    animate             : proc (ui: ^UI, path: string, tick: Frame_Proc, dur: f32),
    set_text            : proc (ui: ^UI, path: string, values: ..any),
}

Mouse_Input :: struct {
    pos     : Vec2,
    wheel_dy: f32,
    lmb_down: bool,
}

Processing_Phase :: enum {
    none,
    ticking,
    drawing,
}

Captured_Info :: struct {
    frame   : ^Frame,
    pos     : Vec2,
    outside : bool,
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
        set_text                = ui_set_text,
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
    delete(ui.scissor_rects)
    free(ui)
}

tick :: proc (ui: ^UI, root_rect: Rect, mouse: Mouse_Input) -> (mouse_input_consumed: bool) {
    ui.stats = {}
    phase_started := time.tick_now()
    ui.phase = .ticking
    defer {
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
                    // fmt.println("->", i.name)
                }
            }

            if lmb_pressed && ui.captured.frame == nil {
                ui.captured = { frame=f, pos=ui.mouse.pos-{f.rect.x,f.rect.y} }
                if .capture in f.flags do keep_capture = true
            }

            break
        }

        if ui.captured.frame != nil {
            mouse_input_consumed = true

            ui.captured.frame.captured = true
            drag(ui.captured.frame, ui.mouse.pos, ui.captured.pos)

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
            // fmt.println("<-", f.name)
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

    ui.mouse_prev = mouse
    return
}

draw :: proc (ui: ^UI) {
    phase_started := time.tick_now()
    ui.phase = .drawing
    defer {
        ui.phase = .none
        ui.stats.draw_time = time.tick_since(phase_started)
    }

    assert(len(ui.scissor_rects) == 0)
    ui.scissor_rect = ui.root.rect

    draw_frame_tree(ui.root)
}

reset_terse :: proc (ui: ^UI) {
    destroy_terse_frame_tree(ui.root)
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
ui_set_text :: #force_inline proc (ui: ^UI, path: string, values: ..any) {
    set_text(get(ui.root, path), ..values)
}
