package data

Player :: struct {
    account_name    : string,
    character_name  : string,

    intel_points_avail: int,
    skill_points_avail: int,

    backpack: ^Container,
    // loadout: ^Container,
}

player: Player

create_player :: proc () {
    player = Player {
        account_name    = "spacemad#12345",
        character_name  = "Skywalker",

        intel_points_avail = 123,
        skill_points_avail = 1,

        backpack = create_container(slot_count=35, max_volume=175),
    }

    container_add_item(player.backpack, { item=get_item("solari"), count=23508 })
    container_add_item(player.backpack, { item=get_item("heavy_darts"), count=218 })
    container_add_item(player.backpack, { item=get_item("welding_wire"), count=227 })
    container_add_item(player.backpack, { item=get_item("hajra_literjon_mk1"), water=1077 })
    container_add_item(player.backpack, { item=get_item("small_blood_sack"), blood=1333 })
    container_add_item(player.backpack, { item=get_item("medium_sized_vehicle_fuel_cell"), fuel=777 })
    container_add_item(player.backpack, { item=get_item("double_sealed_stilltent") })
}

destroy_player :: proc () {
    destroy_container(player.backpack)
}
