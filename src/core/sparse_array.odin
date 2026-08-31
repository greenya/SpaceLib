package spacelib_core

import "core:fmt"
import "core:math/bits"

_ :: fmt
_ :: bits

Sparse_Array :: struct ($T: typeid, $N: int) where N > 0 {
    items       : [N] T,
    slot_chunks : [ (N+63) / 64 ] u64, // Ensure slot_chunks bits are always multiple of 64
    free_list   : [dynamic; N] i32,
}

Sparse_Array_Iterator :: struct ($T: typeid, $N: int) {
    sa          : ^Sparse_Array(T, N),
    chunk_idx   : int,
    remaining   : u64,
}

sparse_array_init :: proc (sa: ^Sparse_Array($T, $N)) {
    // Check `size_of(T) > 0` here instead of in `where` because it currently
    // causes the Odin compiler to crash. The issue has not yet been minimized;
    // it is currently reproduced through `spacelib:hi.Context`.
    // Last reproduced: 2026-08.
    #assert(size_of(T) > 0, "Sparse array element type must have a non-zero size")
    sparse_array_clear(sa)
}

sparse_array_clear :: proc (sa: ^Sparse_Array($T, $N)) #no_bounds_check {
    sa.slot_chunks = {}
    clear(&sa.free_list)
    for i := i32(N-1); i >= 0; i -= 1 {
        append(&sa.free_list, i)
    }
}

sparse_array_add :: proc (sa: ^Sparse_Array($T, $N), value: T) -> (idx: int, ref: ^T) #no_bounds_check {
    if len(sa.free_list) == 0 do fmt.panicf("Sparse array overflow in %v", typeid_of(type_of(sa)))
    idx = int(pop(&sa.free_list))
    sa.slot_chunks[idx >> 6] |= (u64(1) << u64(idx & 63))
    sa.items[idx] = value
    ref = &sa.items[idx]
    return
}

sparse_array_remove_by_idx :: proc (sa: ^Sparse_Array($T, $N), idx: int) #no_bounds_check {
    assert(idx >= 0 && idx < N)
    fmt.assertf((sa.slot_chunks[idx >> 6] & (u64(1) << u64(idx & 63))) != 0, "Sparse array slot #%d already free in %v", idx, typeid_of(type_of(sa)))
    sa.slot_chunks[idx >> 6] &= ~(u64(1) << u64(idx & 63))
    append(&sa.free_list, i32(idx))
}

sparse_array_remove_by_ref :: proc (sa: ^Sparse_Array($T, $N), ref: ^T) #no_bounds_check {
    assert(ref != nil)

    base := uintptr(&sa.items[0])
    address := uintptr(ref)
    end := base + uintptr(size_of(T) * N)
    fmt.assertf(address >= base && address < end, "Sparse array reference is outside %v", typeid_of(type_of(sa)))

    offset := address - base
    fmt.assertf(offset % uintptr(size_of(T)) == 0, "Sparse array reference is not aligned to an item in %v", typeid_of(type_of(sa)))

    idx := int(offset / uintptr(size_of(T)))
    sparse_array_remove_by_idx(sa, idx)
}

sparse_array_remove :: proc {
    sparse_array_remove_by_idx,
    sparse_array_remove_by_ref,
}

sparse_array_len :: proc (sa: Sparse_Array($T, $N)) -> int {
    return N - len(sa.free_list)
}

sparse_array_cap :: proc (sa: Sparse_Array($T, $N)) -> int {
    return N
}

sparse_array_iterate :: proc (sa: ^Sparse_Array($T, $N)) -> (iter: Sparse_Array_Iterator(T, N)) {
    return {
        sa = sa,
        chunk_idx = 0,
        remaining = len(sa.slot_chunks) > 0 ? sa.slot_chunks[0] : 0,
    }
}

sparse_array_next :: proc (it: ^Sparse_Array_Iterator($T, $N)) -> (val: ^T, idx: int, ok: bool) #no_bounds_check {
    for it.remaining == 0 {
        it.chunk_idx += 1
        if it.chunk_idx >= len(it.sa.slot_chunks) do return nil, 0, false
        it.remaining = it.sa.slot_chunks[it.chunk_idx]
    }

    bit_idx := int(bits.count_trailing_zeros(it.remaining))
    idx = (it.chunk_idx << 6) + bit_idx
    val = &it.sa.items[idx]
    ok = true

    it.remaining &= (it.remaining - 1)
    return
}
