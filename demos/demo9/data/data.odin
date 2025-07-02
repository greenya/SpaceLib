package demo9_data

Player :: struct {
    account_name            : string,
    character_name          : string,
    research_points_avail   : int,
    skill_points_avail      : int,
}

player: ^Player

create :: proc () {
    player = new(Player)
    player^ = {
        account_name            = "spacemad#12345",
        character_name          = "Skywalker",
        research_points_avail   = 123,
        skill_points_avail      = 1,
    }
}

destroy :: proc () {
    free(player)
}
