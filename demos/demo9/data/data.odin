package demo9_data

Player :: struct {
    research_points_avail   : int,
    skill_points_avail      : int,
}

player: ^Player

create :: proc () {
    player = new(Player)
    player^ = {
        research_points_avail   = 123,
        skill_points_avail      = 1,
    }
}

destroy :: proc () {
    free(player)
}
