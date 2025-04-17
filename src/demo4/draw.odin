package demo4

import "core:fmt"
import rl "vendor:raylib"
import sl "../spacelib"
import sl_rl "../spacelib/raylib"

draw_rect :: proc (rect: sl.Rect, tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleRec(rect_rl, tint)
}

draw_rect_lines :: proc (rect: sl.Rect, thick := f32(1.0), tint := rl.WHITE) {
    rect_rl := transmute (rl.Rectangle) rect
    rl.DrawRectangleLinesEx(rect_rl, thick, tint)
}

// todo: add text token, split frame update and draw

// todo: implement Measured_HyperText maybe (?)

aaa := "|TOPLEFT,f_normal,c_normal|You deal |i_fire| 17 damage |c_dim|(target dies)"

bbb := "|a:topleft|f:normal|c:normal|You deal {fire} 17 damage |c:dim|(target dies)|r|"

// <a:topleft><f:default><c:default> ---- defaults
ccc1 := "You deal <i:fire> 17 damage to The Monster Name <c:dim>(target dies)</c> and you heal for <i:health> 14"
ccc2 := "0 <i:gold> 44 <i:silver> 33 <i:copper>"
ccc3 := "0 {gold} 44 {silver} 33 {copper}"
ccc4 := "0 {c:gold} 44 {c:silver} 33 {c:copper}"

// |va=top;ha=left;f=default;c=default|...|cr|...|br|

// -- FORMATTING --
// -- per text --
// <valign:top> -- set valign
// -- per line --
// <align:left> -- push align
// </align>     -- pop align
// -- per word --
// <font:name>  -- push font
// </font>      -- pop font
// <color:name> -- push color
// </color>     -- pop color
// -- EXTRA --
// <br>         -- new line (treat \n as space, treat multiple spaces as single space)
// <icon:name>  -- insert icon (Measured_HyperIcon, Measured_HyperLine.items: [dynamic] union { Measured_HyperText, Measured_HyperIcon }
// <group:name> -- start group (Measured_HyperText.groups, element should contain "name" and "words", a list of ^Measured_HyperWord)
// </group>    -- end group (each word in the group should also group name, e.g. Measured_HyperWord.group)

sss := "<font:normal><color:normal>You deal <icon:fire> 17 damage <color:dim>(target dies)</color>"

ddd := `
## All roads lead to Nexus
Build roads from any existing node. Roads cannot be destroyed.
Build mines, turrets, and plants on empty nodes. The Nexus node
is given at the start of the game; if destroyed, the game ends.

## Growing world
The world expands every 3 minutes. Newly revealed areas contain
enemy units that will attack your units and nodes. Maximize gold
mining, and build turrets and plants for unit production.
`

// // "|top+left,f1,c7|All roads lead to |c5|Nexus"

// update_measured_text :: proc (f: ^sl.Frame, font_id: Font_ID, align: sl.Text_Alignment) {
//     font := &font_assets[font_id]
//     f.measured_text = sl.measure_text_rect(f.text, f.rect, &font.font_sl, align, context.temp_allocator)
//     f.size.y = f.measured_text.rect.h
// }

// draw_measured_text :: proc (f: ^sl.Frame, tint := rl.WHITE) {
//     if game.debug_drawing do draw_rect_lines(f.rect, tint={255,0,255,120})
//     if game.debug_drawing do draw_rect(f.measured_text.rect, {255,0,0,40})

//     for line in f.measured_text.lines {
//         for word in line.words {
//             if game.debug_drawing do draw_rect(word.rect, {0,255,255,80})
//             sl_rl.draw_text(word.text, {word.rect.x,word.rect.y}, font.font_rl, font.height, font.letter_spacing, tint)
//         }
//     }
// }

// sl.add_frame(content, {
//     text="All roads lead to Nexus",
//     update=proc (f: ^sl.Frame) {
//         update_measured_text(f, .anaheim_bold_32, {.top,.left})
//     },
//     draw=proc (f: ^sl.Frame) {
//         draw_measured_text(f, .anaheim_bold_32, colors.seven)
//     },
// })

draw_text :: proc (text: string, rect: sl.Rect, font_id: Font_ID, align: sl.Text_Alignment, tint := rl.WHITE) -> sl.Rect {
    font := &font_assets[font_id]

    measured_text := sl.measure_text_rect(text, rect, &font.font_sl, align, context.temp_allocator)

    if game.debug_drawing do draw_rect_lines(rect, tint={255,0,255,120})
    if game.debug_drawing do draw_rect(measured_text.rect, {255,0,0,40})

    for line in measured_text.lines {
        for word in line.words {
            if game.debug_drawing do draw_rect(word.rect, {0,255,255,80})
            sl_rl.draw_text(word.text, {word.rect.x,word.rect.y}, font.font_rl, font.height, font.letter_spacing, tint)
        }
    }

    return measured_text.rect
}

draw_sprite :: proc (id: Sprite_ID, rect: sl.Rect, tint := rl.WHITE) {
    sprite := &sprite_assets[id]
    texture := &texture_assets[sprite.texture_id]
    rect_rl := transmute (rl.Rectangle) rect

    switch info in sprite.info {
    case rl.Rectangle:  rl.DrawTexturePro(texture.texture, info, rect_rl, {}, 0, tint)
    case rl.NPatchInfo: rl.DrawTextureNPatch(texture.texture, info, rect_rl, {}, 0, tint)
    }
}

draw_ui_dim_rect :: proc (f: ^sl.Frame) {
    draw_rect(f.rect, {0,0,0,200})
}

draw_ui_border :: proc (f: ^sl.Frame) {
    draw_sprite(.border_17, f.rect, colors.three)
}

draw_ui_panel :: proc (f: ^sl.Frame) {
    draw_sprite(.panel_0, f.rect, colors.two)
}

draw_ui_button :: proc (f: ^sl.Frame) {
    if sl.disabled(f) {
        draw_sprite(.panel_9, f.rect, colors.three)
        draw_text(f.text, sl.rect_moved(f.rect, {+1,+1}), .anaheim_bold_32, {.center,.center}, colors.two)
        draw_text(f.text, sl.rect_moved(f.rect, {-1,-1}), .anaheim_bold_32, {.center,.center}, colors.four)
        return
    }

    if f.selected {
        draw_sprite(.panel_4, f.rect, colors.five)
    } else {
        draw_sprite(.panel_9, f.rect, f.hovered ? colors.four : colors.three)
    }

    text_color := f.hovered ? colors.seven : colors.six

    if f.captured {
        draw_text(f.text, f.rect, .anaheim_bold_32, {.center,.center}, text_color)
    } else {
        draw_text(f.text, sl.rect_moved(f.rect, {+1,+1}), .anaheim_bold_32, {.center,.center}, colors.two)
        draw_text(f.text, sl.rect_moved(f.rect, {-1,-1}), .anaheim_bold_32, {.center,.center}, text_color)
    }
}

draw_ui_checkbox :: proc (f: ^sl.Frame) {
    text := fmt.tprintf("%s: [ %s ]", f.text, f.selected ? "Yes" : "No")
    text_rect := draw_text(text, f.rect, .anaheim_bold_32, {.center,.center}, f.hovered ? colors.eight : colors.six)
    f.size.y = text_rect.h
}

draw_ui_link :: proc (f: ^sl.Frame) {
    text_rect := draw_text(f.text, f.rect, .anaheim_bold_32, {.center,.center}, f.hovered ? colors.eight : colors.six)

    line := text_rect
    line.y += line.h - 2
    line.h = 2
    draw_rect(line, colors.four)

    if f.hovered {
        icon_l := text_rect
        icon_l.x -= icon_l.w
        draw_text("~> ", icon_l, .anaheim_bold_32, {.center,.right}, colors.four)
        icon_r := text_rect
        icon_r.x += icon_r.w
        draw_text(" <~", icon_r, .anaheim_bold_32, {.center,.left}, colors.four)
    }

    f.size.y = text_rect.h
}

draw_ui_button_sprite :: proc (f: ^sl.Frame, sprite_id: Sprite_ID) {
    if f.hovered do draw_sprite(.panel_15, f.rect, colors.three)
    draw_sprite(sprite_id, f.rect, f.hovered ? colors.six : colors.five)
}

draw_ui_button_sprite_icon_up :: proc (f: ^sl.Frame) { draw_ui_button_sprite(f, .icon_up) }
draw_ui_button_sprite_icon_down :: proc (f: ^sl.Frame) { draw_ui_button_sprite(f, .icon_down) }
draw_ui_button_sprite_icon_stop :: proc (f: ^sl.Frame) { draw_ui_button_sprite(f, .icon_stop) }
