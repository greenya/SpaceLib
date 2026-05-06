package main

import hi ".."

// `icon` is not used for now
add_icon_button :: proc (name, icon: string) {
    hi.add_view({ name=name, size={20,20} })
}

// `text` is not used for now
add_text_button :: proc (name, text: string) {
    hi.add_view({ name=name, size={60,20} })
}
