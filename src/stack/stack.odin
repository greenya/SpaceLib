package spacelib_stack

Stack :: struct ($T: typeid, $N: int) {
    size    : int,
    items   : [N] T,
}

push :: #force_inline proc(stack: ^Stack($T,$N), value: T) {
    assert(stack.size < len(stack.items))
    stack.items[stack.size] = value
    stack.size += 1
}

pop :: #force_inline proc(stack: ^Stack($T,$N)) -> T {
    assert(stack.size > 0)
    stack.size -= 1
    return stack[stack.size+1]
}

pop_discard :: #force_inline proc(stack: ^Stack($T,$N)) {
    assert(stack.size > 0)
    stack.size -= 1
}

clear :: #force_inline proc(stack: ^Stack($T,$N)) -> T {
    stack.size = 0
}

top :: #force_inline proc(stack: Stack($T,$N)) -> T {
    assert(stack.size > 0)
    return stack.items[stack.size-1]
}

is_empty :: #force_inline proc(stack: Stack($T,$N)) -> bool {
    return stack.size == 0
}

is_full :: #force_inline proc(stack: Stack($T,$N)) -> bool {
    return stack.size == len(stack.items)
}

size :: #force_inline proc(stack: Stack($T,$N)) -> int {
    return stack.size
}

size_max :: #force_inline proc(stack: Stack($T,$N)) -> int {
    return len(stack.items)
}
