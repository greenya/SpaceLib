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
        headers={{"color","green"}/*,{"content-type",userhttp.Content_Type_Binary}*/},
        // content=[] userhttp.Param {{"aaa",123},{"bbb",456}},
        // content=[] byte {1,2,3,4,5,6,7,8,9,10},
        content="This is some plain text.",
    })

    userhttp.send(&req)
    userhttp.print_report(req)
    userhttp.delete(req)
}
