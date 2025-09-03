package spacelib_core

Stack :: struct ($T: typeid, $N: int) {
    size    : int,
    items   : [N] T,
}

stack_push :: #force_inline proc(stack: ^Stack($T, $N), value: T) {
    assert(stack.size < len(stack.items))
    stack.items[stack.size] = value
    stack.size += 1
}

stack_pop :: #force_inline proc(stack: ^Stack($T, $N)) -> T {
    assert(stack.size > 0)
    stack.size -= 1
    return stack[stack.size+1]
}

stack_drop :: #force_inline proc(stack: ^Stack($T, $N)) {
    assert(stack.size > 0)
    stack.size -= 1
}

stack_clear :: #force_inline proc(stack: ^Stack($T, $N)) -> T {
    stack.size = 0
}

stack_top :: #force_inline proc(stack: Stack($T, $N)) -> T {
    assert(stack.size > 0)
    return stack.items[stack.size-1]
}

stack_is_empty :: #force_inline proc(stack: Stack($T, $N)) -> bool {
    return stack.size == 0
}

stack_is_full :: #force_inline proc(stack: Stack($T, $N)) -> bool {
    return stack.size == len(stack.items)
}

stack_size :: #force_inline proc(stack: Stack($T, $N)) -> int {
    return stack.size
}

stack_size_max :: #force_inline proc(stack: Stack($T, $N)) -> int {
    return len(stack.items)
}
