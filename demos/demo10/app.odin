package demo10

import "core:fmt"

app_startup :: proc () {
    fmt.println(#procedure)
}

app_shutdown :: proc () {
    fmt.println(#procedure)
}

app_resized :: proc (w, h: i32) {
    fmt.println(#procedure, w, h)
}

app_running :: proc () -> bool {
    return false
}

app_tick :: proc () {
}

app_draw :: proc () {
}
