package data

import "core:fmt"
import "core:strings"

@private
Text :: union { string, [] string }

text_to_string :: proc (text: Text, allocator := context.allocator) -> string {
    b := strings.builder_make(allocator)
    switch v in text {
    case string     : strings.write_string(&b, v)
    case [] string  : for s in v do fmt.sbprintf(&b, "%s%s", strings.builder_len(b) > 0 ? "\n" : "", s)
    }
    return strings.to_string(b)
}

@private
delete_text :: proc (text: Text) {
    switch v in text {
    case string     : delete(v)
    case [] string  : for s in v do delete(s); delete(v)
    }
}
