#+build js
#+private
package userhttp

import "core:encoding/json"
import "core:fmt"
import "core:mem"

foreign import "userhttp"

@(default_calling_convention="contextless")
foreign userhttp {
    userhttp_send :: proc (req: [] byte, res: [] byte) -> i32 ---
}

Network_Error :: enum {
    None,
    Error,
}

platform_init :: proc () -> Network_Error {
    // nothing
    return .None
}

platform_destroy :: proc () {
    // nothing
}

platform_send :: proc (req: ^Request) {
    context.allocator = context.temp_allocator

    args, args_err := _request_to_send_args_tmp(req^)
    if args_err != nil {
        req.error = args_err
        return
    }

    args_bytes, json_err := json.marshal(args)
    if json_err != nil {
        req.error = .Error
        req.error_msg = fmt.aprintf("Failed to json.marshal: %v", json_err, allocator=req.allocator)
        return
    }

    buffer := make_([] byte, 16*mem.Kilobyte)
    buffer_used := userhttp_send(args_bytes, buffer)

    if buffer_used < 0 {
        // buffer too small, retry with exact needed size
        buffer_size_needed := abs(buffer_used)
        buffer = make_([] byte, buffer_size_needed)
        buffer_used = userhttp_send(args_bytes, buffer)
    }

    if buffer_used < 0 {
        req.error = .Error
        req.error_msg = fmt.aprint("Failed to satisfy response buffer size", allocator=req.allocator)
        return
    }

    ensure(int(buffer_used) < len(buffer))
    fmt.println(#procedure, "buffer len", len(buffer))
    fmt.println(#procedure, "buffer (bytes)", buffer)
    fmt.println(#procedure, "buffer (string)", string(buffer))

    // TODO: handle the result -- req.error, req.error_msg, req.response (status, headers, content)
}

_Send_Args :: struct {
    method          : string,
    url             : string,
    query_params    : [] [2] string,
    header_params   : [] [2] string,
    content_params  : [] [2] string,
    content_base64  : string,
}

_Send_Result :: struct {
    error           : string,
    status          : int,
    header_params   : [] [2] string,
    content_base64  : string,
}

_request_to_send_args_tmp :: proc (req: Request) -> (args: _Send_Args, err: Allocator_Error) {
    context.allocator = context.temp_allocator

    args.method = req.method
    args.url    = req.url

    req_content_params, _ := req.content.([]Param)

    for pp in ([?] struct {
        dst: ^[] [2] string,
        src: [] Param,
    } {
        { dst=&args.query_params, src=req.query },
        { dst=&args.header_params, src=req.headers },
        { dst=&args.content_params, src=req_content_params },
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
        // TODO: set args.content_base64 as base64 of req_content_bytes
    }

    return
}
