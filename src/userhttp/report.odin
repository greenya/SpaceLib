package userhttp

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strings"

Report_Option :: enum {
    // request_headers,    // Include request headers
    req_content,    // Include request content
    // res_headers,   // Include response headers
    res_content,   // Include response content
}

print_report :: proc (req: Request, options: bit_set [Report_Option] = ~{}) {
    rep := report(req, options, context.temp_allocator)
    fmt.println(rep)
}

report :: proc (req: Request, options: bit_set [Report_Option] = ~{}, allocator := context.allocator) -> (result: string, err: mem.Allocator_Error) #optional_allocator_error {
    sb := strings.builder_make(allocator) or_return

    sbprint_request(&sb, req, options) or_return

    fmt.sbprint(&sb, "-----------------------------------------------------------")

    result = strings.to_string(sb)
    return
}

@private
sbprint_request :: proc (sb: ^strings.Builder, req: Request, options: bit_set [Report_Option]) -> (err: mem.Allocator_Error) {
    fmt.sbprintln(sb, "--------------------------------------------------[request]")

    fmt.sbprintfln      (sb, "-----------[method] %v", req.method == "" ? "GET" : req.method)
    fmt.sbprintfln      (sb, "--------------[url] %v", req.url)
    sbprint_params      (sb, "------------[query]", req.query) or_return
    sbprint_params      (sb, "----------[headers]", req.headers) or_return
    sbprint_req_content (sb, "----------[content]", req.content, should_dump=.req_content in options) or_return

    // headers_str := header_map_to_string(req.headers, context.temp_allocator) or_return
    // fmt.sbprintfln(sb, "-----------[header] %M", len(headers_str))
    // if .req_header in options do fmt.sbprint(sb, headers_str)

    // sbprint_params(sb, "---[content_params]", req.content_params) or_return
    // content_type := header_map_value(req.headers, .content_type, allocator=context.temp_allocator) or_return
    // sbprint_content(sb, req.content, content_type, should_dump=.req_content in options)

    return
}

@private
sbprint_params :: proc (sb: ^strings.Builder, prefix: string, params: [] Param) -> (err: mem.Allocator_Error) {
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
sbprint_req_content :: proc (sb: ^strings.Builder, prefix: string, content: Content, should_dump: bool) -> (err: mem.Allocator_Error) {
    switch v in content {
    case [] Param:
        sbprint_params(sb, prefix, v) or_return
    case [] byte:
    case string:
        fmt.sbprintfln(sb, "%s %M", prefix, len(v))
        if should_dump do fmt.sbprintfln(sb, "%v", v)
    case nil:
        fmt.sbprintfln(sb, "%s -", prefix)
    }
    return
}

// @private
// sbprint_content :: proc (sb: ^strings.Builder, prefix: string, content: [] u8, content_type: string, should_dump: bool) {
//     content_size := len(content)
//     if content_size > 0 {
//         content_type_text := content_type != "" ? content_type : "[content type not set]"
//         fmt.sbprintfln(sb, "----------[content] %M | %s", content_size, content_type_text)
//         if should_dump {
//             dump: union { [] u8, string } = content_type_is_textual(content_type)\
//                 ? string(content)\
//                 : content
//             fmt.sbprintfln(sb, "%v", dump)
//         }
//     } else {
//         fmt.sbprintfln(sb, "----------[content] %M", 0)
//     }
// }
