package data

import "core:encoding/json"
import "core:fmt"
import "core:slice"

Setting :: struct {
    // page
    page_id     : string,
    page_title  : string,

    // group
    group_id    : string,
    group_title : string,

    // actual setting
    id      : string,
    title   : string,
    desc    : Text,
    control : struct {
        appearance: enum {
            auto,
            button_group,
            pins,
            dropdown,
            slider,
        },
        // for .button_group, .pins, .dropdown
        names       : [] string,
        titles      : [] string,
        default_idx : int,
        // for .slider
        min         : int,
        max         : int,
        default_val : int,
    },
}

@private settings: [] Setting

@private
create_settings :: proc () {
    assert(settings == nil)
    err := json.unmarshal_any(#load("settings.json"), &settings)
    fmt.ensuref(err == nil, "Failed to load settings.json: %v", err)
    // fmt.printfln("%#v", settings)
}

@private
destroy_settings :: proc () {
    for s in settings {
        delete(s.page_id)
        delete(s.page_title)
        delete(s.group_id)
        delete(s.group_title)
        delete(s.id)
        delete(s.title)
        delete_text(s.desc)
        for s in s.control.names do delete(s); delete(s.control.names)
        for s in s.control.titles do delete(s); delete(s.control.titles)
    }
    delete(settings)
    settings = nil
}

get_settings_pages :: proc (allocator := context.allocator) -> [] Setting {
    return slice.filter(settings, proc (i: Setting) -> bool {
        return i.page_id != ""
    }, allocator)
}

get_settings_page_items :: proc (page_id: string) -> [] Setting {
    assert(page_id != "")
    start_i := -1

    for s, i in settings {
        if s.page_id == "" do continue

        if s.page_id == page_id {
            assert(start_i == -1)
            start_i = i + 1
        } else if start_i >= 0 {
            return settings[start_i:i]
        }
    }

    fmt.assertf(start_i >= 0, "Page \"%s\" not found", page_id)

    return settings[start_i:]
}

get_setting :: proc (id: string) -> Setting {
    for s in settings {
        if s.id == id {
            assert(s.page_id == "" && s.group_id == "")
            return s
        }
    }
    fmt.panicf("Setting \"%s\" was not found", id)
}
