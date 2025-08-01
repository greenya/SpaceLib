package demo8

import "spacelib:ui"

// Set of shortcuts to execute some command by path from the ui root.
// This is removed from the UI so to keep this demo working, we just impl it here.
// This is ok for small ui, but for larger, you want to have pointers to key
//      screens/pages/sections etc, otherwise those paths grow long quickly.
// If you like the method, it can be used, those shortcuts can be added easy,
//      and they can be used when initializing ui structure, as its no need
//      to be fast, but readable.

ui_get :: proc (path: string) -> ^ui.Frame {
    return ui.get(app.ui.root, path)
}

ui_click :: proc (path: string) {
    ui.click(ui.get(app.ui.root, path))
}

ui_set_text :: proc (path: string, values: ..any) {
    ui.set_text(ui.get(app.ui.root, path), ..values)
}
