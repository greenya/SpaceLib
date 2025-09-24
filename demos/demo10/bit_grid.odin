package demo10

import "core:mem"
import "spacelib:userfs"

Bit_Grid :: struct {
    board: u64, // 8x8 grid of bits
}

bit_grid_default := Bit_Grid {
    board = 0x4e4a4a4a4a6e00, // drawing of "01"
}

bit_grid_file :: "bit_grid.bin"

bit_grid: Bit_Grid

bit_grid_load :: proc () {
    bit_grid = bit_grid_default
    bytes := userfs.read(bit_grid_file, context.temp_allocator)
    if bytes != nil && len(bytes) == size_of(Bit_Grid) {
        ptr := cast (^Bit_Grid) &bytes[0]
        bit_grid = ptr^
    }
}

bit_grid_save :: proc () {
    userfs.write(bit_grid_file, mem.ptr_to_bytes(&bit_grid))
}

bit_grid_set_bit :: proc (index: int, one: bool, save := true) {
    mask := u64(1) << u8(index)
    if one  do bit_grid.board |= mask
    else    do bit_grid.board &= ~mask
    if save do bit_grid_save()
}
