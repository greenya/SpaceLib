package userhttp

import "core:fmt"
import "core:slice"
import "core:strings"

Report_Option :: enum {
    req_content,    // Include request content
    res_content,    // Include response content
}

print_report :: proc (req: Request, options: bit_set [Report_Option] = ~{}) {
    rep := report(req, options, context.temp_allocator)
    fmt.println(rep)
}

report :: proc (req: Request, options: bit_set [Report_Option] = ~{}, allocator := context.allocator) -> (result: string, err: Allocator_Error) #optional_allocator_error {
    sb := strings.builder_make(allocator) or_return

    {
        req_ct_str := param_as_string(req.headers, "content-type", context.temp_allocator) or_return
        req_timeout_str := req.timeout > 0 ? fmt.tprint(req.timeout) : "-"

        fmt.sbprintln       (&sb, "--------------------------------------------------[request]")
        fmt.sbprintfln      (&sb, "-----------[method] %s", req.method)
        fmt.sbprintfln      (&sb, "--------------[url] %s", req.url)
        sbprint_params      (&sb, "------------[query]", req.query) or_return
        sbprint_params      (&sb, "----------[headers]", req.headers) or_return
        sbprint_req_content (&sb, "----------[content]", req.content, req_ct_str, .req_content in options) or_return
        fmt.sbprintfln      (&sb, "----------[timeout] %s", req_timeout_str)
    }

    if req.error != nil {
        fmt.sbprintln       (&sb, "----------------------------------------------------[error]")
        fmt.sbprintfln      (&sb, "%17s | %i | %v", error_type_name(req.error), req.error, req.error)
        if req.error_msg != "" {
            fmt.sbprintfln  (&sb, "%17s | %s", "Message", req.error_msg)
        }
    }

    if req.response.status != .None {
        res_ct_str := param_as_string(req.response.headers, "content-type", context.temp_allocator) or_return

        fmt.sbprintln       (&sb, "-------------------------------------------------[response]")
        fmt.sbprintfln      (&sb, "-------------[time] %v", req.response.time)
        fmt.sbprintfln      (&sb, "-----------[status] %i %v", int(req.response.status), req.response.status)
        sbprint_params      (&sb, "----------[headers]", req.response.headers) or_return
        sbprint_res_content (&sb, "----------[content]", req.response.content, res_ct_str, .res_content in options)
    }

    fmt.sbprint(&sb, "-----------------------------------------------------------")

    result = strings.to_string(sb)
    return
}

@private
sbprint_params :: proc (sb: ^strings.Builder, prefix: string, params: [] Param) -> (err: Allocator_Error) {
    result := "-"

    if params != nil {
        context.allocator = context.temp_allocator
        list := slice.mapper(params, proc (param: Param) -> string {
            return fmt.tprintf("%s=%v", param.name, param.value)
        }) or_return
        result = strings.join(list[:], " | ") or_return
    }

    fmt.sbprintfln(sb, "%s %s", prefix, result)
    return
}

@private
sbprint_req_content :: proc (sb: ^strings.Builder, prefix: string, content: Content, content_type: string, should_dump: bool) -> (err: Allocator_Error) {
    switch v in content {
    case [] Param:
        sbprint_params(sb, prefix, v) or_return

    case [] byte:
        content_bytes := v
        sbprint_res_content(sb, prefix, content_bytes, content_type, should_dump)

    case string:
        content_bytes := transmute ([] byte) v
        sbprint_res_content(sb, prefix, content_bytes, content_type, should_dump)
    }
    return
}

@private
sbprint_res_content :: proc (sb: ^strings.Builder, prefix: string, content: [] byte, content_type: string, should_dump: bool) {
    content_size := len(content)
    if content_size > 0 {
        content_type_text := content_type != "" ? content_type : "[content type not set]"
        fmt.sbprintfln(sb, "%s %M | %s", prefix, content_size, content_type_text)
        if should_dump {
            dump: union { [] byte, string } = guess_content_type_is_textual(content_type)\
                ? string(content)\
                : content
            fmt.sbprintfln(sb, "%v", dump)
        }
    } else {
        fmt.sbprintfln(sb, "%s %M", prefix, 0)
    }
    return
}
