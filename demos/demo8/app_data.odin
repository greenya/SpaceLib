package demo8

import "spacelib:core"

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
    i["bandage"] = { name="Bandage", icon="bandage-roll", tags={.consumable}, count=21 }
    i["ammo_box"] = { name="Ammo Box", icon="ammo-box", tags={.consumable}, count=6 }
    i["black_tar"] = { name="Black Tar", icon="potion-ball", tags={.consumable}, count=2 }
    i["liquid_escape"] = { name="Liquid Escape", icon="broken-skull", tags={.consumable}, count=1 }

    // quest
    i["lighter"] = { name="Lighter", icon="lighter", tags={.quest}, count=1 }
    i["broken_tablet"] = { name="Broken Tablet", icon="broken-tablet", tags={.quest}, count=1 }
    i["crown_coin"] = { name="Crown Coin", icon="crown-coin", tags={.quest}, count=1 }

    // material
    i["faith_seed"] = { name="Faith Seed", icon="plant-seed", tags={.material}, count=1 }
    i["lost_crystal"] = { name="Lost Crystal", icon="floating-crystal", tags={.material}, count=7 }
    i["log"] = { name="Log", icon="log", tags={.material}, count=123 }
    i["rock"] = { name="Rock", icon="rock", tags={.material}, count=50 }
    i["crumbling_ball"] = { name="Crumbling Ball", icon="crumbling-ball", tags={.material}, count=1 }
    i["acid_tube"] = { name="Acid Tube", icon="corked-tube", tags={.material}, count=3 }
    i["cloth_scrap"] = { name="Cloth Scrap", icon="rolled-cloth", tags={.material}, count=10 }
    i["chared_berries"] = { name="Chared Berries", icon="elderberry", tags={.material}, count=1 }
    i["feather"] = { name="Feather", icon="feather", tags={.material}, count=4 }
    i["paper_sheet"] = { name="Paper Sheet", icon="papers", tags={.material}, count=24 }
    i["vanilla_flower"] = { name="Vanilla Flower", icon="vanilla-flower", tags={.material}, count=1 }
    i["black_ore"] = { name="Black Ore", icon="tumor", tags={.material}, count=2 }
    i["salt"] = { name="Salt", icon="powder", tags={.material}, count=8 }
}

app_data_item_ids_filter_by_tag :: proc (tag: App_Data_Item_Tag, allocator := context.allocator) -> [] string {
    result := make([dynamic] string, allocator)
    for id in core.map_keys_sorted(app.data.items, context.temp_allocator) {
        if tag in app.data.items[id].tags {
            append(&result, id)
        }
    }
    return result[:]
}
