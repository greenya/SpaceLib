#+build js
#+private
package userhttp

import "base:runtime"
import "core:encoding/json"
import "core:fmt"
// import "core:mem"
import "core:strings"
// import "core:time"

foreign import "userhttp"

@(default_calling_convention="contextless")
foreign userhttp {
    userhttp_fetch  :: proc (fetch_id: i32, input: [] byte)   ---
    userhttp_size   :: proc (fetch_id: i32) -> i32            ---
    userhttp_pop    :: proc (fetch_id: i32, output: [] byte)  ---
}

Platform_Error :: enum {
    None,
    Error,
}

Platform_Handle :: struct {
    fetch_id: i32,
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

_next_fetch_id := i32(70001)

platform_init :: proc () -> Platform_Error {
    // nothing
    return .None
}

platform_destroy :: proc () {
    // nothing
}

platform_send :: proc (req: ^Request) {
    context.allocator = context.temp_allocator

    input, input_err := _request_to_input_tmp(req^)
    if input_err != nil {
        req.error = input_err
        return
    }

    input_bytes, json_err := json.marshal(input)
    if json_err != nil {
        req.error = .Error
        req.error_msg = fmt.aprintf("Failed to json.marshal: %v", json_err, allocator=requests.allocator)
        return
    }

    fetch_id := _next_fetch_id
    _next_fetch_id += 1

    req.handle = { fetch_id=fetch_id }
    userhttp_fetch(fetch_id, input_bytes)
}

@export
userhttp_ready :: proc "c" (fetch_id: i32, size: i32) {
    context = runtime.default_context()
    fmt.println(#procedure, fetch_id, size)

    ensure(size > 0)
    output_bytes := make([] byte, size, context.temp_allocator)
    userhttp_pop(fetch_id, output_bytes)

    req, _ := find_request_by_handle({ fetch_id=fetch_id })
    ensure(req != nil)

    output: _Output
    json_err := json.unmarshal(output_bytes, &output, allocator=context.temp_allocator)
    if json_err != nil {
        req.error = .Error
        req.error_msg = fmt.aprintf("Failed to json.unmarshal: %v", json_err, allocator=requests.allocator)
        return
    }

    if output.error != "" {
        req.error = .Error
        req.error_msg = strings.clone(output.error, requests.allocator)
    } else {
        req.response.status = Status_Code(output.status)
        req.response.headers, _ = create_params_from_pairs(output.header_params, requests.allocator) // ignore allocator error
        // TODO set from output.content_base64
        // req.response.content = ...
    }
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
        pp.dst^ = make([] [2] string, len(pp.src)) or_return
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
