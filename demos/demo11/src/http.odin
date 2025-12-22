package main

import "core:fmt"
import "spacelib:userhttp"

http_init :: proc () {
    userhttp.init()
}

http_destroy :: proc () {
    userhttp.destroy()
}

http_send_request :: proc () {
    fmt.println(#procedure)

    // res, ok := userhttp.send({ url="https://www.google.com/test/for/404" })
    // defer userhttp.delete_response(res)

    // fmt.println("res", res)
    // fmt.println("ok", ok)

    req := userhttp.make({
        url="https://www.google.com/test/for/404",
        query={{"id",555},{"action","test"}},
        headers={{"head-ONE","Val1"},{"head-TWO",1234567890}},
        content=[] userhttp.Param {{"zzz",123}},
    })

    userhttp.send(&req)
    userhttp.print_report(req)
    userhttp.delete(req)
}
