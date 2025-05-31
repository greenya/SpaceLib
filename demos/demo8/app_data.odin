package demo8

App_Data :: struct {
    traits  : map [string] App_Data_Trait,
    items   : map [string] App_Data_Item,
}

App_Data_Trait :: struct {
    name            : string,
    icon            : string,
    points_granted  : int,
    points_spent    : int,
    active          : bool,
}

App_Data_Item :: struct {
    name    : string,
    icon    : string,
    tags    : bit_set [App_Data_Item_Tag],
    count   : int,
}

App_Data_Item_Tag :: enum {
    consumable,
    quest,
    material,
}

app_data_create :: proc () {
    app.data = new(App_Data)
    app_data_add_traits()
    app_data_add_items()
}

app_data_destroy :: proc () {
    delete(app.data.traits)
    delete(app.data.items)
    free(app.data)
    app.data = nil
}

app_data_add_traits :: proc () {
    t := &app.data.traits

    t["longshot"] = { name="Longshot", icon="silver-bullet", points_granted=10, active=true }
    t["potency"] = { name="Potency", icon="evil-book", points_granted=9, active=true }
    t["vigor"] = { name= "Vigor", icon="fist", points_granted=1, points_spent=9 }
    t["endurance"] = { name="Endurance", icon="cracked-helm", points_granted=2, points_spent=2 }
    t["spirit"] = { name="Spirit", icon="candlebright", points_spent=4 }
    t["expertise"] = { name="Expertise", icon="power-lightning", points_granted=2, points_spent=8 }
    t["amplitude"] = { name="Amplitude", icon="ink-swirl", points_spent=10 }
    t["blood_bond"] = { name="Blood Bond", icon="open-wound" }
    t["bloodstream"] = { name="Bloodstream", icon="gloop" }
    t["siphoner"] = { name="Siphoner", icon="tesla", points_spent=5 }
}

app_data_add_items :: proc () {
    i := &app.data.items

    // consumables
    i["bandage"] = { name="Bandage", icon="bandage-roll", tags={.consumable}, count=15 }
    i["ammo_box"] = { name="Ammo Box", icon="ammo-box", tags={.consumable}, count=2 }
    i["black_tar"] = { name="Black Tar", icon="potion-ball", tags={.consumable}, count=4 }
    i["liquid_escape"] = { name="Liquid Escape", icon="harry-potter-skull", tags={.consumable}, count=1 }

    // quest
    i["lighter"] = { name="Lighter", icon="lighter", tags={.quest}, count=1 }

    // material
    i["faith_seed"] = { name="Faith Seed", icon="plant-seed", tags={.material}, count=1 }
    i["lost_crystal"] = { name="Lost Crystal", icon="floating-crystal", tags={.material}, count=1 }
}
