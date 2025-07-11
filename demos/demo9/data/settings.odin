package demo9_data

import "core:encoding/json"
import "core:fmt"
import "core:slice"
import "core:strings"

Settings_Item :: struct {
    // page
    page_name   : string,
    page_title  : string,

    // group
    group_name  : string,
    group_title : string,

    // actual setting
    name    : string,
    title   : string,
    desc    : union { string, [] string },
    control : struct {
        names       : [] string,
        titles      : [] string,
        default_idx : int,
        // min     : int,
        // max     : int,
        appearance  : enum {
            auto,
            button_group,
            pins,
            dropdown,
            // slider,
        },
    },
}

@private settings: [] Settings_Item

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
        delete(s.page_name)
        delete(s.page_title)
        delete(s.group_name)
        delete(s.group_title)
        delete(s.name)
        delete(s.title)
        switch v in s.desc {
        case string     : delete(v)
        case [] string  : for s in v do delete(s); delete(v)
        }
        for s in s.control.names do delete(s); delete(s.control.names)
        for s in s.control.titles do delete(s); delete(s.control.titles)
    }
    delete(settings)
    settings = nil
}

get_settings_pages :: proc (allocator := context.allocator) -> [] Settings_Item {
    return slice.filter(settings, proc (i: Settings_Item) -> bool {
        return i.page_name != ""
    }, allocator)
}

get_settings_page_items :: proc (page_name: string) -> [] Settings_Item {
    assert(page_name != "")
    start_i := -1

    for s, i in settings {
        if s.page_name == "" do continue

        if s.page_name == page_name {
            assert(start_i == -1)
            start_i = i + 1
        } else if start_i >= 0 {
            return settings[start_i:i]
        }
    }

    fmt.assertf(start_i >= 0, "Page \"%s\" not found", page_name)

    return settings[start_i:]
}

get_settings_item :: proc (name: string) -> Settings_Item {
    for s in settings {
        if s.name == name {
            assert(s.page_name == "" && s.group_name == "")
            return s
        }
    }
    fmt.panicf("Item \"%s\" was not found", name)
}

get_settings_item_desc :: proc (name: string, allocator := context.allocator) -> string {
    item := get_settings_item(name)
    sb := strings.builder_make(context.temp_allocator)
    switch v in item.desc {
    case string     : strings.write_string(&sb, v)
    case [] string  : for s in v do fmt.sbprintf(&sb, "%s%s", strings.builder_len(sb) > 0 ? "\n" : "", s)
    }
    return strings.to_string(sb)
}
