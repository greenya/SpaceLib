package userhttp

import "core:fmt"
import "core:slice"
import "core:strings"

Print_Option :: enum {
    req_content,    // Include request content
    res_content,    // Include response content
}

print_request :: proc (req: ^Request, options: bit_set [Print_Option] = ~{}) {
    context.allocator = context.temp_allocator
    {
        req_ct_str := param_as_string(req.headers, "content-type")

        fmt.println         ("--------------------------------------------------[request]")
        fmt.printfln        ("-----------[method] %s", req.method)
        fmt.printfln        ("--------------[url] %s", req.url)
        print_params        ("------------[query]", req.query)
        print_params        ("----------[headers]", req.headers)
        print_req_content   ("----------[content]", req.content, req_ct_str, .req_content in options)
        fmt.printfln        ("-------[timeout_ms] %i", req.timeout_ms)
    }

    if req.error != nil {
        fmt.println         ("----------------------------------------------------[error]")
        fmt.printfln        ("%17s | %i | %v", error_type_name(req.error), req.error, req.error)
        if req.error_msg != "" {
            fmt.printfln    ("%17s | %s", "Message", req.error_msg)
        }
    }

    if req.response.status != .None {
        res_ct_str := param_as_string(req.response.headers, "content-type")

        fmt.println         ("-------------------------------------------------[response]")
        fmt.printfln        ("-----------[status] %i %v", int(req.response.status), req.response.status)
        print_params        ("----------[headers]", req.response.headers)
        print_res_content   ("----------[content]", req.response.content, res_ct_str, .res_content in options)
    }

    fmt.println("-----------------------------------------------------------")
}

@private
print_params :: proc (prefix: string, params: [] Param) {
    result := "-"

    if params != nil {
        list := slice.mapper(params, proc (param: Param) -> string {
            return fmt.tprintf("%s=%v", param.name, param.value)
        })
        result = strings.join(list[:], " | ")
    }

    fmt.printfln("%s %s", prefix, result)
}

@private
print_req_content :: proc (prefix: string, content: Content, content_type: string, should_dump: bool) {
    switch v in content {
    case [] Param:
        print_params(prefix, v)

    case [] byte:
        content_bytes := v
        print_res_content(prefix, content_bytes, content_type, should_dump)

    case string:
        content_bytes := transmute ([] byte) v
        print_res_content(prefix, content_bytes, content_type, should_dump)
    }
}

@private
print_res_content :: proc (prefix: string, content: [] byte, content_type: string, should_dump: bool) {
    content_size := len(content)
    if content_size > 0 {
        content_type_text := content_type != "" ? content_type : "[content type not set]"
        fmt.printfln("%s %M | %s", prefix, content_size, content_type_text)
        if should_dump {
            MAX_LEN :: 300
            is_textual := guess_content_type_is_textual(content_type)
            if len(content) > MAX_LEN {
                fmt.printfln(is_textual ? "%s%s" : "%v%s", content[:MAX_LEN], "...[truncated]")
            } else {
                fmt.printfln(is_textual ? "%s" : "%v", content)
            }
        }
    } else {
        fmt.printfln("%s %M", prefix, 0)
    }
}
