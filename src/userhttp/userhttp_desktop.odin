#+build !js
#+private
package userhttp

import "vendor:curl"

Network_Error :: curl.code

platform_init :: proc () -> Network_Error {
    return curl.global_init(curl.GLOBAL_DEFAULT)
}

platform_destroy :: proc () {
    curl.global_cleanup()
}
