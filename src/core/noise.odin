package spacelib_core

noise_1d :: #force_inline proc (seed: u32, pos: i32) -> u32 {
    bit_noise1 :: 0xb5297a4d
    bit_noise2 :: 0x68e31da4
    bit_noise3 :: 0x1b56c4e9

    m := u32(pos)
    m *= bit_noise1
    m += seed
    m ~= m >> 8
    m += bit_noise2
    m ~= m << 8
    m *= bit_noise3
    m ~= m >> 8

    return m
}

noise_1d_zero_to_one :: #force_inline proc (seed: u32, pos: i32) -> f32 {
    return f32(noise_1d(seed, pos)) / f32(max(u32))
}

noise_1d_neg_one_to_one :: #force_inline proc (seed: u32, pos: i32) -> f32 {
    return -1 + 2 * f32(noise_1d(seed, pos)) / f32(max(u32))
}

noise_2d :: #force_inline proc (seed: u32, pos_x, pos_y: i32) -> u32 {
    return noise_1d(seed, pos_x + pos_y * 198_491_317)
}

noise_3d :: #force_inline proc (seed: u32, pos_x, pos_y, pos_z: i32) -> u32 {
    return noise_1d(seed, pos_x + pos_y * 198_491_317 + pos_z * 6_542_989)
}
