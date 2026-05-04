package spacelib_core

// TODO: Maybe remove Stack? Because Odin now has statically allocated dynamic arrays, e.g. [dynamic; N] T

Stack :: struct ($T: typeid, $N: int) {
    size    : int,
    items   : [N] T,
}

stack_push :: proc(stack: ^Stack($T, $N), value: T) {
    assert(stack.size < len(stack.items))
    stack.items[stack.size] = value
    stack.size += 1
}

stack_pop :: proc(stack: ^Stack($T, $N)) -> T {
    assert(stack.size > 0)
    stack.size -= 1
    return stack.items[stack.size]
}

stack_drop :: proc(stack: ^Stack($T, $N)) {
    assert(stack.size > 0)
    stack.size -= 1
}

stack_top :: proc(stack: Stack($T, $N)) -> T {
    assert(stack.size > 0)
    return stack.items[stack.size-1]
}

stack_items :: proc(stack: ^Stack($T, $N)) -> [] T {
    return stack.items[:stack.size]
}

stack_clear :: proc(stack: ^Stack($T, $N)) -> T {
    stack.size = 0
}

stack_is_empty :: proc(stack: Stack($T, $N)) -> bool {
    return stack.size == 0
}

stack_is_full :: proc(stack: Stack($T, $N)) -> bool {
    return stack.size == len(stack.items)
}

stack_size :: proc(stack: Stack($T, $N)) -> int {
    return stack.size
}

stack_size_max :: proc(stack: Stack($T, $N)) -> int {
    return len(stack.items)
}
