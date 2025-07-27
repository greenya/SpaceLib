package data

credits_text        := string(#load("credits.txt"))
lorem_ipsum_text    := string(#load("lorem_ipsum.txt"))

create :: proc () {
    create_codex()
    create_dialogs()
    create_settings()
    create_tutorial_tips()
}

destroy :: proc () {
    destroy_codex()
    destroy_dialogs()
    destroy_settings()
    destroy_tutorial_tips()
}
