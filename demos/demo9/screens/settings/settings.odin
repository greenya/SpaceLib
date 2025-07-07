package demo9_screens_settings

import "core:fmt"
import "core:strings"
import "spacelib:ui"

import "../../data"
import "../../events"
import "../../partials"

@private screen: ^ui.Frame

add :: proc (parent: ^ui.Frame) {
    assert(screen == nil)

    screen = ui.add_frame(parent, { name="settings" },
        { point=.top_left },
        { point=.bottom_right },
    )

    partials.add_screen_base(screen)

    partials.add_screen_footer_key_button(screen, "close", "Close", key="Esc",
        click=proc (f: ^ui.Frame) {
            events.send_open_screen("opening")
        },
    )

    partials.add_screen_footer_key_button(screen, "reset_to_default", "Reset to Default", key="X")

    add_gameplay_page()

    ui.click(screen, "header_bar/tabs/gameplay")
}

@private
add_gameplay_page :: proc () {
    _, page := partials.add_screen_tab_and_page(screen, "gameplay", "GAMEPLAY")

    list := add_list_column(page)
    add_details_column(page, list)

    for name in ([] string {
        "sprint_lock",
        "equip_lock",
        "suspensor_lock",
        "invert_mouse_y_axis",
        "mouse_camera_sensitivity",
        "mouse_aiming_sensitivity",
        "camera_shakes",
        "show_helmet",
        "--< BUILDING >--",
        "building:placeable_rotation_building_mode",
        "--< VEHICLES >--",
        "vehicles:disable_camera_auto_center",
        "--< AIR VEHICLES >--",
        "air_vehicles:invert_mouse_y_axis",
        "air_vehicles:planar_lock",
        "--< RADIAL WHEEL >--",
        "radial_wheel:input_lock_mode_mouse",
        "radial_wheel:close_behaviour",
    }) {
        is_header := strings.has_prefix(name, "--< ") && strings.has_suffix(name, " >--")
        if is_header {
            add_setting_header(list, name[4:-4+len(name)]) // "4" for len of suffix and prefix
        } else {
            add_setting_card(list, name)
        }
    }
}

@private
add_setting_header :: proc (list: ^ui.Frame, text: string) {
    ui.add_frame(list, {
        name    = "header",
        flags   = {.terse,.terse_height},
        draw    = partials.draw_hexagon_rect,
        text    = fmt.tprintf("<left,pad=20:0,font=text_4l,color=primary_d2>%s", text),
    })
}

@private
add_setting_card :: proc (list: ^ui.Frame, setting_name: string) {
    assert(setting_name in data.info.settings)
    setting_info := data.info.settings[setting_name]

    card := ui.add_frame(list, {
        name = setting_name,
        draw = partials.draw_setting_card,
        enter = proc (f: ^ui.Frame) {
            details := ui.get(f, "../../details")
            assert(f.name != "")
            i := data.info.settings[f.name]
            if i != {} {
                ui.set_text(ui.get(details, "title"), i.title)
                ui.set_text(ui.get(details, "content/text"), i.desc)
                ui.show(details)
            } else {
                ui.hide(details)
            }
        },
    })

    title := ui.add_frame(card,
        { name="title", size={250,0}, flags={.pass_self,.terse}, text=setting_info.title,
            text_format="<wrap,left,font=text_4l,color=primary>%s" },
        { point=.top_left, offset={20,0} },
        { point=.bottom_left, offset={20,0} },
    )

    value := ui.add_frame(card,
        { name="value", flags={.pass_self} },
        { point=.top_left, rel_point=.top_right, rel_frame=title },
        { point=.bottom_right },
    )

    // for each data type should be a control, that is a lot of work :)
    // for now will use bool (on/off) only -- the easiest to do
    add_setting_card_control_bool(value)
}

@private
add_setting_card_control_bool :: proc (value: ^ui.Frame) {
    value.layout = { dir=.left_and_right, pad=20, size={120,0} }
    ui.add_frame(value, { name="off", text="OFF", flags={.radio,.continue_enter,.no_capture}, draw=partials.draw_button_radio })
    ui.add_frame(value, { name="on", text="ON", flags={.radio,.continue_enter,.no_capture}, draw=partials.draw_button_radio })
    value.children[0].selected = true
}

@private
add_list_column :: proc (page: ^ui.Frame) -> ^ui.Frame {
    pad :: partials.screen_pad

    list := ui.add_frame(page,
        { name="list", size={560,0}, layout={dir=.down,size={0,80},gap=15,scroll={step=20}}, flags={.scissor} },
        { point=.top_left, offset={1.5*pad,2*pad} },
        { point=.bottom_left, offset={1.5*pad,-2*pad} },
    )

    partials.add_scrollbar(list)

    return list
}

@private
add_details_column :: proc (page, list: ^ui.Frame) -> ^ui.Frame {
    pad :: partials.screen_pad
    track_offset :: 40

    details := ui.add_frame(page,
        { name="details", flags={.hidden} },
        { point=.top_left, rel_point=.top_right, rel_frame=list, offset={80,0} },
        { point=.bottom_right, offset={-1.5*pad-track_offset,-2*pad} },
    )

    title := ui.add_frame(details,
        { name="title", flags={.terse,.terse_height}, text_format="<wrap,left,font=text_6l,color=primary>%s" },
        { point=.top_left },
        { point=.top_right },
    )

    line := ui.add_frame(details,
        { name="line", size={0,2}, text="primary_d4", draw=partials.draw_gradient_fade_right_rect },
        { point=.top_left, rel_point=.bottom_left, rel_frame=title, offset={0,10} },
        { point=.top_right, rel_point=.bottom_right, rel_frame=title, offset={0,10} },
    )

    content := ui.add_frame(details,
        { name="content", layout={dir=.down,scroll={step=10}}, flags={.scissor} },
        { point=.top_left, rel_point=.bottom_left, rel_frame=line, offset={0,10} },
        { point=.top_right, rel_point=.bottom_right, rel_frame=line, offset={0,10} },
        { point=.bottom, rel_point=.bottom },
    )

    _, track, _ := partials.add_text_and_scrollbar(content)

    track.anchors[0].offset = {track_offset,0}
    track.anchors[1].offset = {track_offset,0}

    return details
}
