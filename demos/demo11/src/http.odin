package main

import "core:fmt"
import "spacelib:userhttp"

http_send_request :: proc () {
    fmt.println(#procedure)

    res, ok := userhttp.send({ url="https://www.google.com/test/for/404" })

    fmt.println("res", res)
    fmt.println("ok", ok)
}
