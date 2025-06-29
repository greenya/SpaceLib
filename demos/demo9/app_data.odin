package demo9

App_Data :: struct {
    player: struct {
        research_points_avail   : int,
        skill_points_avail      : int,
    },
}

app_data_create :: proc () {
    app.data = new(App_Data)
    app.data.player = {
        research_points_avail   = 123,
        skill_points_avail      = 1,
    }
}

app_data_destroy :: proc () {
    free(app.data)
    app.data = nil
}
