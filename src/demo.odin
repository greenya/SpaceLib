package demo

import "demo1"
import "demo2"

main :: proc () {
    demo1.main()
    demo2.main()
}
