package data

Info :: struct {
    welcome         : struct { title, content: string },
    notification    : struct { title, content: string },
}

info := Info {
    welcome = {
        title   = "WELCOME TO ARRAKIS",
        content = "A beginning is the time for taking the most delicate care that the balances are correct.",
    },
    notification = {
        title   = "ITEM LOSS ON TRAVEL",
        content = "We have received reports that some players have lost items from their inventory while" +
            " traveling to the Deep Desert or Hagga Basin via the World Map after the recent patch." +
            "\n\nWe are investigating the issue and will provide an update as soon as possible." +
            "\n\nThank you.",
    },
}

credits_text := #load("credits.txt")

create :: proc () {
    create_settings()
    create_dialogs()
}

destroy :: proc () {
    destroy_settings()
    destroy_dialogs()
}
