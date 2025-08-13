package data

credits_text        := string(#load("credits.txt"))
lorem_ipsum_text    := string(#load("lorem_ipsum.txt"))

create :: proc () {
    create_codex()
    create_conversations()
    create_instructions()
    create_items()
    create_settings()
    create_tutorial_tips()

    // we create player last, as it uses items to fill up player.backpack container;
    // technically it should use all stuff above, e.g. player should has list of unlocked ids
    // for codex and tutorial tips, and such;
    // note: the "player" technically is a player's character, and player can have multiple characters;
    // anyway, that is going to far away already from the idea of "just try to replicate ui mechanics" :D
    // note2: games probably have "account data", so player can unlock account wide achievement (for example),
    // and "character data" which is progress of one of player's characters
    create_player()
}

destroy :: proc () {
    destroy_codex()
    destroy_conversations()
    destroy_instructions()
    destroy_items()
    destroy_settings()
    destroy_tutorial_tips()

    destroy_player()
}
