package main

// TODO: Fix issue when resizing, scrollable views should validate current scroll bounds
// TODO: Add child_by_selected()

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
}

panel_create :: proc (parent: ^hi.View, path: string) -> ^Panel {
    panel := new(Panel)

    mem.dynamic_arena_init(&panel.arena)
    panel.allocator = mem.dynamic_arena_allocator(&panel.arena)

    panel.ui_root = hi.add_view(parent, { flags={.fill_y}, layout={dir=.column}, size={300,0}, on_draw=_panel_draw_view })
    panel.ui_title_bar = hi.add_view(panel.ui_root, { flags={.fill_x,.text}, padding=10 })
    panel.ui_file_list = hi.add_view(panel.ui_root, { flags={.fill_x,.fill_y,.scissor,.wheel_scroll_layout}, layout={dir=.column}, on_draw=_panel_draw_view })
    panel.ui_status_bar = hi.add_view(panel.ui_root, { flags={.fill_x,.text}, padding=10 })
    panel.ui_file_open_btn = hi.add_view(panel.ui_root, {
        flags   = {.text,.text_fit_x},
        text    = "Open",
        on_event= proc (v: ^hi.View, event: hi.Event) -> (consumed: bool) {
            if event.type == .clicked do log("click", v.text)
            return
        },
        on_draw = proc (v: ^hi.Visible_View) {
            rect := k2.Rect(v.solved_rect)
            k2.draw_rect(rect, core.gray5)
            if .hovered in v.flags do k2.draw_rect_outline(rect, 1, core.gray8)
            else                   do k2.draw_rect_outline(rect, 1, core.gray6)
            v.ctx.on_draw_text(v)
        },
    })

    _panel_reload_path(panel, path)

    return panel
}

panel_destroy :: proc (panel: ^Panel) {
    hi.remove_view(panel.ui_root)
    mem.dynamic_arena_destroy(&panel.arena)
    free(panel)
}

// If `path == ""` then it uses user's Home dir
_panel_reload_path :: proc (panel: ^Panel, path: string) {
    path := path
    if path == "" do path, _ = os.user_home_dir(context.temp_allocator)
    log(#procedure, path)

    hi.remove_children(panel.ui_file_list)
    mem.dynamic_arena_free_all(&panel.arena)

    panel.path = strings.clone(path, panel.allocator)
    panel.ui_title_bar.text = fmt.aprintf("|center|%s", panel.path, allocator=panel.allocator)
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
        file_card := hi.add_view(panel.ui_file_list, {
            flags   = {.fill_x,.fit_y,.radio},
            layout  = {dir=.row,gap=10},
            padding = {10,5,10,5},
            user_ptr= panel,
            user_idx= i,
            on_event= _panel_event_file_view,
            on_draw = _panel_draw_file_card_view,
        })
        hi.add_view(file_card, {
            flags   = {.text,.text_fit_x},
            text    = fmt.aprintf("[%v]", f.type, allocator=panel.allocator),
        })
        hi.add_view(file_card, {
            flags   = {.text,.fill_x},
            text    = f.name,
        })
    }

    if len(panel.files) > 0 {
        hi.show(panel.ui_file_open_btn)
        hi.click(panel.ui_file_list.first_child)
    } else {
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

_panel_draw_file_card_view :: proc (v: ^hi.Visible_View) {
    if .selected in v.flags {
        rect := k2.Rect(v.solved_rect)
        k2.draw_rect(rect, core.gray4)
    }
}
