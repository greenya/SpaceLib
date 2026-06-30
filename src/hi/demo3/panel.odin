package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"

import "../../core"
import hi ".."
import k2 "../../../../karl2d"

Panel :: struct {
    arena       : mem.Dynamic_Arena,
    allocator   : mem.Allocator,

    path    : string,
    files   : [] os.File_Info,

    ui_root         : ^hi.View,
    ui_title_bar    : ^hi.View,
    ui_status_bar   : ^hi.View,
    ui_file_list    : ^hi.View,
    ui_file_info    : ^hi.View,
    ui_file_open_btn: ^hi.View,
    ui_no_files_note: ^hi.View,
}

panel_create :: proc (parent: ^hi.View, path: string) -> ^Panel {
    panel := new(Panel)

    mem.dynamic_arena_init(&panel.arena)
    panel.allocator = mem.dynamic_arena_allocator(&panel.arena)

    panel.ui_root = hi.add_view(parent, { flags={.fill_y,.scissor}, layout={dir=.column}, size={300,0} })

    panel.ui_title_bar = hi.add_view(panel.ui_root, { flags={.fill_x,.text}, padding=10 })

    panel.ui_file_list = hi.add_view(panel.ui_root, {
        flags   = { .fill_x, .fill_y, .scissor, .wheel_scroll_layout },
        layout  = { dir=.column },
        on_draw = proc (v: ^hi.Visible_View) {
            rect := hi.viewport_rect(v)
            k2.draw_rect_outline(k2.Rect(rect), 1, core.gray4)
        },
    })

    panel.ui_file_info = hi.add_view(panel.ui_root, { flags={.fill_x,.text}, padding=10, user_ptr=panel })

    panel.ui_status_bar = hi.add_view(panel.ui_root, { flags={.fill_x,.text}, padding=10 })

    panel.ui_file_open_btn = _panel_add_file_open_btn(panel.ui_root, panel)

    panel.ui_no_files_note = hi.add_view(panel.ui_root, {
        flags   = { .text, .text_fit_x },
        padding = 10,
        place   = { anchor=.5, pivot=.5 },
        strata  = .high,
    })

    _panel_reload_path(panel, path)

    hi.set_debug(panel.ui_root, .debug in parent.flags)

    return panel
}

panel_destroy :: proc (panel: ^Panel) {
    hi.remove_view(panel.ui_root)
    mem.dynamic_arena_destroy(&panel.arena)
    free(panel)
}

_panel_reload_path :: proc (panel: ^Panel, path: string) {
    path := path
    if path == "" do path, _ = os.user_home_dir(context.temp_allocator)
    log(#procedure, path)

    hi.remove_children(panel.ui_file_list)
    mem.dynamic_arena_free_all(&panel.arena)

    panel.path = strings.clone(path, panel.allocator)
    path_dir, path_filename := os.split_path(panel.path)
    panel.ui_title_bar.text = fmt.aprintf("|s=large||i=Directory| %s", path_filename, allocator=panel.allocator)
    hi.hide(panel.ui_file_open_btn)

    err: os.Error
    panel.files, err = os.read_all_directory_by_path(panel.path, panel.allocator)
    if err == nil {
        slice.sort_by(panel.files, less=proc (i, j: os.File_Info) -> bool {
            switch {
            case i.type == .Directory && j.type == .Directory   : fallthrough
            case i.type != .Directory && j.type != .Directory   : return i.name < j.name
            case                                                : return i.type == .Directory
            }
        })
        for _, i in panel.files do _panel_add_file_view(panel.ui_file_list, panel, i)
        if len(panel.files) > 0 do _panel_state_ok_with_files(panel)
        else                    do _panel_state_ok_no_files(panel)
    } else {
        _panel_state_error(panel, error_msg=fmt.tprint(err))
    }
}

_panel_add_file_open_btn :: proc (parent: ^hi.View, panel: ^Panel) -> ^hi.View {
    return hi.add_view(parent, {
        flags   = { .text, .text_fit_x },
        text    = "Open",
        padding = 5,
        place   = { anchor={1,.5}, pivot={1,.5} },
        user_ptr= panel,
        on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
            if event.type != .clicked do return

            panel := cast (^Panel) v.user_ptr
            file_view := hi.child_by_any_flags(panel.ui_file_list, { .selected })
            assert(file_view != nil)
            file := &panel.files[file_view.user_idx]
            logf("open #%i: %#v", file_view.user_idx, file)

            if file.type == .Directory {
                app_destroy_all_panels_to_the_right(panel)
                app_add_panel(file.fullpath)
            } else {
                // TODO: spawn popup
            }

            return true
        },
        on_draw = proc (v: ^hi.Visible_View) {
            rect := k2.Rect(v.solved_rect)
            if .hovered in v.flags do k2.draw_rect(rect, core.gray6)
            else                   do k2.draw_rect(rect, core.gray5)
            v.ctx.on_draw_text(v)
        },
    })
}

_panel_add_file_view :: proc (parent: ^hi.View, panel: ^Panel, file_idx: int) {
    file := &panel.files[file_idx]
    log(#procedure, file_idx, file.type, file.name, file.size)

    hi.add_view(parent, {
        flags   = { .text, .fill_x, .radio },
        text    = fmt.aprintf("|nowrap||i=%v| |raw|%s", file.type, file.name, allocator=panel.allocator),
        padding = {10,5,10,5},
        user_ptr= panel,
        user_idx= file_idx,
        on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
            #partial switch event.type {
            case .selection_changed:
                panel := cast (^Panel) v.user_ptr
                if .selected in v.flags {
                    hi.set_parent(panel.ui_file_open_btn, v)
                    file := &panel.files[v.user_idx]
                    // ISSUE: always allocating
                    panel.ui_file_info.text = fmt.aprintf(
                        "|s=large|%s|s|\n\n"+
                        "|c=#999|Type|c||tab=80||i=%v| %v\n"+
                        "|c=#999|Size|c||tab=80||s=huge|%M|s|\n"+
                        "|c=#999|Mode|c||tab=80||perm_bits|\n"+
                        "|c=#999|Modified|c||tab=80|%s",
                        file.name,
                        file.type, file.type,
                        file.size,
                        _format_time(file.modification_time, context.temp_allocator),
                        allocator=panel.allocator,
                    )
                    _panel_update_status_bar(panel)
                }
            }
            return
        },
        on_draw = proc (v: ^hi.Visible_View) {
            if .selected in v.flags {
                rect := k2.Rect(v.solved_rect)
                k2.draw_rect(rect, core.gray4)
            }
            v.ctx.on_draw_text(v)
        },
    })
}

_panel_state_ok_with_files :: proc (panel: ^Panel) {
    hi.hide(panel.ui_no_files_note)
    hi.show(panel.ui_file_open_btn)
    hi.show(panel.ui_file_info)
    assert(panel.ui_file_list.first_child != nil)
    hi.click(panel.ui_file_list.first_child)
    _panel_update_status_bar(panel)
}

_panel_state_ok_no_files :: proc (panel: ^Panel) {
    panel.ui_no_files_note.text = "|c=muted|List is empty"
    hi.show(panel.ui_no_files_note)
    hi.hide(panel.ui_file_open_btn)
    hi.hide(panel.ui_file_info)
    _panel_update_status_bar(panel)
}

_panel_state_error :: proc (panel: ^Panel, error_msg: string) {
    panel.ui_no_files_note.text = fmt.aprintf("|c=error|%s", error_msg, allocator=panel.allocator)
    hi.show(panel.ui_no_files_note)
    hi.hide(panel.ui_file_open_btn)
    hi.hide(panel.ui_file_info)
    _panel_update_status_bar(panel)
}

_panel_update_status_bar :: proc (panel: ^Panel) {
    sel_file_text: string
    file_view := hi.child_by_any_flags(panel.ui_file_list, { .selected })
    if file_view != nil {
        sel_file_text = fmt.tprintf("Selected|tab=80|%i / %i\n", 1+file_view.user_idx, len(panel.files))
    }

    mme_allocated, mem_reserved := _dynamic_arena_mem_usage(panel.arena)
    mem_usage_text := fmt.tprintf("Memory|tab=80|%M / %M", mme_allocated, mem_reserved)

    // ISSUE: always allocating
    panel.ui_status_bar.text = fmt.aprintf(
        "|c=muted||s=small|%s%s",
        sel_file_text,
        mem_usage_text,
        allocator=panel.allocator,
    )
}

_perm_bits_bit_width_scale :: .8
_perm_bits_gap_width_scale :: .4

_perm_bits_width_scale :: proc () -> f32 {
    return\
        _perm_bits_bit_width_scale * len(os.Permission_Flag) +
        _perm_bits_gap_width_scale * 2
}

_perm_bits_draw :: proc (mode: os.Permissions, rect: k2.Rect) {
    bws :: _perm_bits_bit_width_scale
    gws :: _perm_bits_gap_width_scale
    for f, i in os.Permission_Flag {
        b := os.Permission_Flag(len(os.Permission_Flag) - int(f) - 1)
        r := core.Rect {
            rect.x + f32(i)*bws*rect.h + f32(i/3)*gws*rect.h,
            rect.y,
            rect.h*bws,
            rect.h,
        }
        core.rect_inflate(&r, -1)
        if b in mode do k2.draw_rect(k2.Rect(r), core.gray8)
        else         do k2.draw_rect_outline(k2.Rect(r), 1, core.gray6)
    }
}

_format_time :: proc (t: time.Time, allocator := context.allocator) -> string {
    y, m, d := time.date(t)
    h, i, _ := time.clock(t)
    m_str := fmt.tprint(m)
    // Testing baseline alignment with different font sizes in a line
    // (visible token baselines are expected to be in a straight line)
    return fmt.aprintf("|s=large|%d %s |s=small|%d |s=tiny|%02d:%02d|s|", d, m_str[:3], y, h, i, allocator=allocator)
}

_dynamic_arena_mem_usage :: proc (a: mem.Dynamic_Arena) -> (allocated, reserved: int) {
    // Proper way would be probably to use Tracking_Allocator,
    // but this seems to give some believable numbers too
    allocated = a.block_size - a.bytes_left +
                a.block_size * (    len(a.used_blocks) + len(a.unused_blocks))
    reserved  = a.block_size * (1 + len(a.used_blocks) + len(a.unused_blocks))
    return
}
