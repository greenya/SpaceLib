package main

import "core:fmt"
// import "core:time"
import "spacelib:userhttp"

http_init :: proc () {
    userhttp.init()
}

http_destroy :: proc () {
    userhttp.destroy()
}

http_send_request :: proc () {
    fmt.println(#procedure)

    req := userhttp.make({
        url="https://api.github.com/repos/odin-lang/Odin",
        headers={{"user-agent","userhttp"}}, // GitHub API requires User-Agent header set
    })
    userhttp.send(&req)
    userhttp.print_report(req)
    userhttp.delete(req)

    // res, ok := userhttp.send({ url="https://www.google.com/test/for/404" })
    // defer userhttp.delete_response(res)

    // fmt.println("res", res)
    // fmt.println("ok", ok)

    // req := userhttp.make({
    //     // url="https://www.google.com/test/for/404",
    //     url="https://httpbin.org/post",
    //     query={{"a",1},{"b","+!%"}},
    //     headers={{"c","d"}/*,{"content-type",userhttp.Content_Type_Binary}*/},
    //     // content=[] userhttp.Param {{"e",7},{"f","g+"}},
    //     // content=[] byte {1,2,3,4,5,6,7,8,9,10},
    //     // content="This is some plain text.",
    //     content="{\"f\":3.1415,\"s\":\"STRING\"}",
    //     timeout=5*time.Second,
    // })

    // userhttp.send(&req)
    // userhttp.print_report(req)
    // userhttp.delete(req)
}
