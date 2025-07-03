package demo9_data

Info :: struct {
    welcome         : struct { title: string, content: string },
    notification    : struct { title: string, content: string },
}

Player :: struct {
    account_name        : string,
    character_name      : string,
    intel_points_avail  : int,
    skill_points_avail  : int,
}

info: ^Info
player: ^Player

create :: proc () {
    info = new(Info)
    info^ = {
        welcome = {
            title   = "WELCOME TO ARRAKIS",
            content = "A beginning is the time for taking the most delicate care that the balances are correct.",
        },
        notification = {
            title   = "ITEM LOSS ON TRAVEL",
            content = "" +
                "We have received reports that some players have lost items from their inventory while " +
                "traveling to the Deep Desert or Hagga Basin via the World Map after the recent patch." +
                "\n\nWe are investigating the issue and will provide an update as soon as possible."+
                "\n\nThank you.",
        },
    }

    player = new(Player)
    player^ = {
        account_name        = "spacemad#12345",
        character_name      = "Skywalker",
        intel_points_avail  = 123,
        skill_points_avail  = 1,
    }
}

destroy :: proc () {
    free(info)
    free(player)
}
