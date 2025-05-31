package demo8

App_Data :: struct {
    traits: map [string] App_Data_Trait,
}

App_Data_Trait :: struct {
    name            : string,
    icon            : string,
    points_granted  : int,
    points_spent    : int,
    active          : bool,
}

app_data_create :: proc () {
    app.data = new(App_Data)

    app.data.traits["longshot"] = {
        name            = "Longshot",
        icon            = "silver-bullet",
        points_granted  = 10,
        active          = true,
    }
    app.data.traits["potency"] = {
        name            = "Potency",
        icon            = "evil-book",
        points_granted  = 9,
        active          = true,
    }
    app.data.traits["vigor"] = {
        name            = "Vigor",
        icon            = "fist",
        points_granted  = 1,
        points_spent    = 9,
    }
    app.data.traits["endurance"] = {
        name            = "Endurance",
        icon            = "cracked-helm",
        points_granted  = 2,
        points_spent    = 2,
    }
    app.data.traits["spirit"] = {
        name            = "Spirit",
        icon            = "candlebright",
        points_spent    = 4,
    }
    app.data.traits["expertise"] = {
        name            = "Expertise",
        icon            = "power-lightning",
        points_granted  = 2,
        points_spent    = 8,
    }
    app.data.traits["amplitude"] = {
        name            = "Amplitude",
        icon            = "ink-swirl",
        points_spent    = 10,
    }
    app.data.traits["blood_bond"] = {
        name            = "Blood Bond",
        icon            = "open-wound",
    }
    app.data.traits["bloodstream"] = {
        name            = "Bloodstream",
        icon            = "gloop",
    }
    app.data.traits["siphoner"] = {
        name            = "Siphoner",
        icon            = "tesla",
        points_spent    = 5,
    }
}

app_data_destroy :: proc () {
    delete(app.data.traits)
    free(app.data)
    app.data = nil
}
