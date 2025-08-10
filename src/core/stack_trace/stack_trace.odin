package spacelib_stack_trace

import "base:runtime"
import "core:debug/trace"

trace_ctx: trace.Context

// Common usage:
//
//      import "spacelib:core/stack_trace"
//      main :: proc () {
//          context.assertion_failure_proc = stack_trace.init()
//          defer stack_trace.destroy()
//          ...
//      }

init :: proc () -> runtime.Assertion_Failure_Proc {
    trace.init(&trace_ctx)
    return assertion_failure_proc
}

destroy :: proc () {
    trace.destroy(&trace_ctx)
    trace_ctx = {}
}

print :: proc (loc := #caller_location) {
    when ODIN_DEBUG {
        print_stack_trace(loc=loc)
    } else {
        runtime.print_string("[stack trace requires debug build]")
    }
}

@(private)
assertion_failure_proc :: proc(prefix, message: string, loc := #caller_location) -> ! {
    runtime.print_string("[!]--------[")
    runtime.print_string(prefix)
    runtime.print_string("]--------\n")

    runtime.print_string(" | ")
    runtime.print_caller_location(loc)
    runtime.print_byte('\n')

    runtime.print_string(" +--[")
    runtime.print_string(loc.procedure)
    runtime.print_string("]")
    if message != "" {
        runtime.print_byte(' ')
        runtime.print_string(message)
    }
    runtime.print_byte('\n')

    print_stack_trace(loc=loc)

    runtime.trap()
}

@(private)
print_stack_trace :: proc (loc := #caller_location) {
    when ODIN_DEBUG {
        ctx := &trace_ctx
        if !trace.in_resolve(ctx) {
            runtime.print_string("------------ Stack Trace ------------\n")

            buf: [64] trace.Frame
            frames := trace.frames(ctx, skip=0, frames_buffer=buf[:])
            loc_stack_start_frame_idx := -1

            for f, i in frames {
                fl := trace.resolve(ctx, f, context.temp_allocator)
                if fl.loc.file_path == "" && fl.loc.line == 0 do continue

                if loc_stack_start_frame_idx == -1 {
                    if is_same_loc(loc, fl.loc) do loc_stack_start_frame_idx = i
                    else                        do continue
                }

                runtime.print_byte('[')
                runtime.print_int(i - loc_stack_start_frame_idx)
                runtime.print_string("] ")
                runtime.print_caller_location(fl.loc)
                runtime.print_byte('\n')
            }

            runtime.print_string("-------------------------------------\n")
        }
    }
}

// checks if `loc1` and `loc2` seems to be the same location.
// - compares `file_path` and `line` number only
// - when comparing `file_path`, treat any slash as same (`/` == `\`)
//
// note: we do it only because simple `loc1.file_path==loc2.file_path` will not work,
// as `trace.resolve()` returns location where path slashes seems to be platform specific,
// and the location from `#caller_location` seems always uses forward slash (`/`).
@(private)
is_same_loc :: proc (loc1, loc2: runtime.Source_Code_Location) -> bool {
    if loc1.line != loc2.line do return false
    if len(loc1.file_path) != len(loc2.file_path) do return false

    for i in 0..<len(loc1.file_path) {
        c1 := loc1.file_path[i]
        c2 := loc2.file_path[i]
        if (c1 == '/' || c1 == '\\') && (c2 == '/' || c2 == '\\') do continue
        if c1 != c2 do return false
    }

    return true
}
