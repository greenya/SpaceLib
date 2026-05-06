package userhttp

import "core:slice"
import "core:strings"

Content :: union {
    [] Param,
    [] byte,
    string,
}

@private
clone_content :: proc (content: Content, allocator := context.allocator) -> (result: Content, err: Allocator_Error) {
    switch v in content {
    case [] Param   : result = clone_params(v, allocator=allocator) or_return
    case [] byte    : result = slice.clone(v, allocator) or_return
    case string     : result = strings.clone(v, allocator) or_return
    }
    return
}
