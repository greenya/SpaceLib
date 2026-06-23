package main

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strings"
import "core:os"

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
    ui_file_open_btn: ^hi.View,
    ui_list_is_empty: ^hi.View,
}

panel_create :: proc (parent: ^hi.View, path: string) -> ^Panel {
    panel := new(Panel)

    mem.dynamic_arena_init(&panel.arena)
    panel.allocator = mem.dynamic_arena_allocator(&panel.arena)

    panel.ui_root = hi.add_view(parent, { flags={.fill_y}, layout={dir=.column}, size={300,0}, on_draw=_panel_draw_view })
    r := panel.ui_root

    panel.ui_title_bar = hi.add_view(r, { flags={.fill_x,.text}, padding=10 })
    panel.ui_file_list = hi.add_view(r, { flags={.fill_x,.fill_y,.scissor,.wheel_scroll_layout}, layout={dir=.column}, on_draw=_panel_draw_view })
    panel.ui_status_bar = hi.add_view(r, { flags={.fill_x,.text}, padding=10 })

    panel.ui_file_open_btn = hi.add_view(r, {
        flags   = {.text,.text_fit_x},
        text    = "Open",
        padding = 5,
        place   = {anchor={1,.5},pivot={1,.5}},
        user_ptr= panel,
        on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
            if event.type == .clicked {
                panel := cast (^Panel) v.user_ptr
                file := hi.child_by_any_flags(panel.ui_file_list, { .selected })
                assert(file != nil)

                fi := &panel.files[file.user_idx]
                logf("Clicked on file #%i: %#v", file.user_idx, fi)

                if fi.type == .Directory {
                    app_destroy_all_panels_to_the_right(panel)
                    app_add_panel(fi.fullpath)
                }
            }
            return
        },
        on_draw = _panel_draw_button_view,
    })

    panel.ui_list_is_empty = hi.add_view(panel.ui_title_bar, {
        flags   = { .text, .text_fit_x },
        text    = "|muted|List is empty",
        padding = 10,
        place   = { anchor={.5,1}, pivot={.5,0} },
        strata  = .overlay,
    })

    _panel_reload_path(panel, path)

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
    panel.ui_title_bar.text = fmt.aprintf("|header|%s", path_filename, allocator=panel.allocator)
    hi.hide(panel.ui_file_open_btn)

    err: os.Error
    panel.files, err = os.read_all_directory_by_path(panel.path, panel.allocator)
    assert(err == nil)

    slice.sort_by(panel.files, less=proc (i, j: os.File_Info) -> bool {
        switch {
        case i.type == .Directory && j.type == .Directory   : fallthrough
        case i.type != .Directory && j.type != .Directory   : return i.name < j.name
        case                                                : return i.type == .Directory
        }
    })

    for f, i in panel.files {
        // logf("\t[%4i] %10v %#v (%m)", i, f.type, f.name, f.size)

        hi.add_view(panel.ui_file_list, {
            flags   = {.text,.fill_x,.radio},
            text    = fmt.aprintf("|nowrap||icon=%v| |-raw-|%s", f.type, f.name, allocator=panel.allocator),
            padding = {10,5,10,5},
            user_ptr= panel,
            user_idx= i,
            on_event= _panel_event_file_view,
            on_draw = _panel_draw_file_row_view,
        })
    }

    if len(panel.files) > 0 {
        hi.hide(panel.ui_list_is_empty)
        hi.show(panel.ui_file_open_btn)
        hi.click(panel.ui_file_list.first_child)
    } else {
        hi.show(panel.ui_list_is_empty)
        hi.hide(panel.ui_file_open_btn)
    }
}

_panel_event_file_view :: proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
    #partial switch event.type {
    case .selection_changed:
        panel := cast (^Panel) v.user_ptr
        if .selected in v.flags {
            hi.set_parent(panel.ui_file_open_btn, v)
            f := panel.files[v.user_idx]
            // ISSUE: we allocate more and more in panel.allocator; maybe have some pre-allocated buffer; maybe some panel.file_status_cache[file_name]=fmt.aprintf(...)
            panel.ui_status_bar.text = fmt.aprintf("Name|tab=60|%s\nSize|tab=60|%m", f.name, f.size, allocator=panel.allocator)
        }
        v.ctx.solved = false
    }
    return
}

_panel_draw_view :: proc (v: ^hi.Visible_View) {
    rect := k2.Rect(core.rect_inflated(v.solved_rect, 1))
    k2.draw_rect_outline(rect, 1, core.gray8)
}

_panel_draw_file_row_view :: proc (v: ^hi.Visible_View) {
    if .selected in v.flags {
        rect := k2.Rect(v.solved_rect)
        k2.draw_rect(rect, core.gray4)
    }
    v.ctx.on_draw_text(v)
}

_panel_draw_button_view :: proc (v: ^hi.Visible_View) {
    rect := k2.Rect(v.solved_rect)
    k2.draw_rect(rect, core.gray4)
    if .hovered in v.flags do k2.draw_rect_outline(rect, 1, core.gray9)
    else                   do k2.draw_rect_outline(rect, 1, core.gray5)
    v.ctx.on_draw_text(v)
}
