package main

import "core:os"

import "../../core"
import k2 "../../../../karl2d"

@rodata
Perm_Bits := [?] os.Permission_Flag {
    .Read_User  , .Write_User   , .Execute_User,
    .Read_Group , .Write_Group  , .Execute_Group,
    .Read_Other , .Write_Other  , .Execute_Other,
}

_perm_bits_width_scale :: proc () -> f32 {
    bit_count :: len(Perm_Bits)
    gap_count :: 2
    return bit_count*bit_width + gap_count*gap_width
}

_perm_bits_draw :: proc (mode: os.Permissions, rect: k2.Rect) {
    for b, i in Perm_Bits {
        r := core.Rect {
            rect.x + f32(i)*bit_width*rect.h + f32(i/3)*gap_width*rect.h,
            rect.y,
            rect.h*bit_width,
            rect.h,
        }
        core.rect_inflate(&r, -1)
        if b in mode do k2.draw_rect(k2.Rect(r), core.gray8)
        else         do k2.draw_rect_outline(k2.Rect(r), 1, core.gray6)
    }
}

// Scaled values of line height
@(private="file") bit_width :: .8
@(private="file") gap_width :: .4
