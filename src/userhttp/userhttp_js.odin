#+build js
#+private
package userhttp

import "core:encoding/json"
import "core:fmt"
// import "core:mem"
import "core:time"

foreign import "userhttp"

@(default_calling_convention="contextless")
foreign userhttp {
    userhttp_fetch  :: proc (req_id: i32, req: [] byte)     ---
    userhttp_state  :: proc (req_id: i32) -> i32            ---
    userhttp_get    :: proc (req_id: i32, res: [] byte)     ---
}

Network_Error :: enum {
    None,
    Error,
}

_Input :: struct {
    method          : string,
    url             : string,
    query_params    : [] [2] string,
    header_params   : [] [2] string,
    content_params  : [] [2] string,
    content_base64  : string,
}

_Output :: struct {
    error           : string,
    status          : int,
    header_params   : [] [2] string,
    content_base64  : string,
}

// TODO: make this tread safe?
_next_request_id := i32(12340001)

platform_init :: proc () -> Network_Error {
    // nothing
    return .None
}

platform_destroy :: proc () {
    // nothing
}

platform_send :: proc (req: ^Request) {
    context.allocator = context.temp_allocator

    state: i32
    req_id := _fetch(req)

    for _ in 0..<10 {
        state := userhttp_state(req_id)
        if state != 0 do break
        time.sleep(100*time.Millisecond)
    }

    if state <= 0 {
        req.error = .Error
        req.error_msg = fmt.aprint("xxxxx")
        return
    }

    buffer := make_([] byte, state)
    userhttp_get(req_id, buffer)

    fmt.println(#procedure, "buffer len", len(buffer))
    fmt.println(#procedure, "buffer (bytes)", buffer)
    fmt.println(#procedure, "buffer (string)", string(buffer))

    // TODO: handle the result -- req.error, req.error_msg, req.response (status, headers, content)

    // input, input_err := _request_to_input_tmp(req^)
    // if input_err != nil {
    //     req.error = input_err
    //     return
    // }

    // input_bytes, json_err := json.marshal(input)
    // if json_err != nil {
    //     req.error = .Error
    //     req.error_msg = fmt.aprintf("Failed to json.marshal: %v", json_err, allocator=req.allocator)
    //     return
    // }

    // req_id := _next_request_id
    // _next_request_id += 1

    // userhttp_send(req_id, input_bytes)

    // buffer := make_([] byte, 16*mem.Kilobyte)
    // buffer_used := userhttp_send(args_bytes, buffer)
    // fmt.println("buffer_used", buffer_used)

    // if buffer_used < 0 {
    //     // buffer too small, retry with exact needed size
    //     buffer_size_needed := abs(buffer_used)
    //     buffer = make_([] byte, buffer_size_needed)
    //     buffer_used = userhttp_send(args_bytes, buffer)
    // }

    // if buffer_used < 0 {
    //     req.error = .Error
    //     req.error_msg = fmt.aprint("Failed to satisfy response buffer size", allocator=req.allocator)
    //     return
    // }

    // ensure(int(buffer_used) < len(buffer))
    // fmt.println(#procedure, "buffer len", len(buffer))
    // fmt.println(#procedure, "buffer (bytes)", buffer)
    // fmt.println(#procedure, "buffer (string)", string(buffer))
}

_fetch :: proc (req: ^Request) -> (req_id: i32) {
    input, input_err := _request_to_input_tmp(req^)
    if input_err != nil {
        req.error = input_err
        return
    }

    input_bytes, json_err := json.marshal(input)
    if json_err != nil {
        req.error = .Error
        req.error_msg = fmt.aprintf("Failed to json.marshal: %v", json_err, allocator=req.allocator)
        return
    }

    req_id = _next_request_id
    _next_request_id += 1

    userhttp_fetch(req_id, input_bytes)

    return
}

_request_to_input_tmp :: proc (req: Request) -> (input: _Input, err: Allocator_Error) {
    context.allocator = context.temp_allocator

    input.method    = req.method
    input.url       = req.url

    req_content_params, _ := req.content.([]Param)

    for pp in ([?] struct {
        dst: ^[] [2] string,
        src: [] Param,
    } {
        { dst=&input.query_params, src=req.query },
        { dst=&input.header_params, src=req.headers },
        { dst=&input.content_params, src=req_content_params },
    }) {
        if pp.src == nil do continue
        pp.dst^ = make_([] [2] string, len(pp.src)) or_return
        for p, i in pp.src {
            n := p.name
            v := fmt.tprint(p.value)
            pp.dst[i][0] = n
            pp.dst[i][1] = v
        }
    }

    req_content_bytes: [] byte

    switch v in req.content {
    case [] Param   : // nothing
    case [] byte    : req_content_bytes = v
    case string     : req_content_bytes = transmute ([] byte) v
    }

    if req_content_bytes != nil {
        // TODO: set input.content_base64 as base64 of req_content_bytes
    }

    return
}
