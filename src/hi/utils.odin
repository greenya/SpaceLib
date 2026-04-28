#+private
package hi

import "core:fmt"

log :: proc (args: ..any) {
    fmt.print("[hi] ", flush=false)
    fmt.print(..args, flush=false)
    fmt.println()
}

logf :: proc (format: string, args: ..any) {
    fmt.print("[hi] ", flush=false)
    fmt.printf(format, ..args, flush=false)
    fmt.println()
}
