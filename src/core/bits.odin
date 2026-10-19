package spacelib_core

import "core:math"
import "core:math/bits"

Bits_Iterator :: struct {
    stream  : [] byte,
    bit_i   : uint,
}

bits_iterate :: proc (stream: [] byte) -> Bits_Iterator {
    return { stream=stream }
}

bits_next :: proc (it: ^Bits_Iterator, step: uint) -> (value: uint, ok: bool) {
    assert(step <= 8 * size_of(value))
    (it.bit_i + step <= 8 * uint(len(it.stream))) or_return

    for i in 0..<step {
        byte_i, bit_i := math.divmod(it.bit_i + i, 8)
        bit := bits.bitfield_extract(uint(it.stream[byte_i]), 8-1-bit_i, 1)
        value = bits.bitfield_insert(value, 1, step-1-i, bit)
    }

    it.bit_i += step
    return value, true
}
