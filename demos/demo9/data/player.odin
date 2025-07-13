package data

Player :: struct {
    account_name        : string,
    character_name      : string,
    intel_points_avail  : int,
    skill_points_avail  : int,
}

player := Player {
    account_name        = "spacemad#12345",
    character_name      = "Skywalker",
    intel_points_avail  = 123,
    skill_points_avail  = 1,
}
