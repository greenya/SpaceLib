package userhttp

requests: [dynamic] ^Request

// Common usage:
//
//      import "spacelib:userhttp"
//      main :: proc () {
//          userhttp.init()
//          for ...game loop is running ... {
//              userhttp.tick()
//              if ...should send request... {
//                  userhttp.send_request({
//                      url     = "https://some/url/goes/here",
//                      ready   = proc (req: ^userhttp.Request) {
//                          if req.error == nil { all good, use req.response }
//                          you also can print all the request details using userhttp.print_request(req)
//                      },
//                  })
//              }
//          }
//          userhttp.destroy()
//      }

init :: proc (allocator := context.allocator) -> (err: Error) {
    requests = make([dynamic] ^Request, allocator) or_return
    platform_init(allocator) or_return
    return
}

destroy :: proc () -> (err: Allocator_Error) {
    platform_destroy()
    for req in requests do destroy_request(req) or_return
    delete(requests) or_return
    return
}

// Checks request status and calls `Request.ready()` callback.
tick :: proc () -> (err: Error) {
    platform_tick() or_return

    // doing double-loop, as user can send_request() inside ready() callback,
    // which modifies requests array

    for req in requests {
        if req.error != nil || req.response.status != .None {
            if req.ready != nil {
                req.ready(req)
            }
        }
    }

    #reverse for req, idx in requests {
        if req.error != nil || req.response.status != .None {
            unordered_remove(&requests, idx)
            destroy_request(req) or_return
        }
    }

    return
}

// Sends the request.
//
// If `method` is empty, it will be auto-set to:
// - "GET" if `content == nil`
// - "POST" if `content != nil`
//
// If `content != nil` and no "Content-Type" `header` is set, it will be auto-added with value:
// - `Content_Type_Params` for `content` of type `[] Param`
// - `Content_Type_Binary` for `content` of type `[] byte`
// - `Content_Type_JSON` for `content` of type `string` starts with `{` character
// - `Content_Type_XML` for `content` of type `string` starts with `<` character
// - `Content_Type_Text` for `content` of type `string` otherwise
//
// The request will be allocated and sent; the `tick()` call will update its progress, once
// it is resolved (succeeded or failed), `req.ready()` callback will be called from `tick()`.
//
// IMPORTANT: The request will be deallocated by `tick()` right after `req.ready()` returns.
send_request :: proc (init: Request_Init) -> (req: ^Request, err: Allocator_Error) {
    req = create_request(init, requests.allocator) or_return
    append(&requests, req) or_return
    platform_send(req)
    return
}

@private
find_request_by_handle :: proc (handle: Platform_Handle) -> (req: ^Request, idx: int) {
    for r, i in requests do if r.handle == handle do return r, i
    return nil, -1
}
