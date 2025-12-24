package userhttp

import "core:slice"
import "core:strings"

Content :: union {
    [] Param,
    [] byte,
    string,
}

@private
clone_content :: proc (content: Content) -> (result: Content, err: Allocator_Error) {
    switch v in content {
    case [] Param   : result = clone_params(v) or_return
    case [] byte    : result = slice.clone(v) or_return
    case string     : result = strings.clone(v) or_return
    }
    return
}

@private
delete_content :: proc (content: Content) -> (err: Allocator_Error) {
    switch v in content {
    case [] Param   : delete_params(v) or_return
    case [] byte    : delete_(v) or_return
    case string     : delete_(v) or_return
    }
    return
}
