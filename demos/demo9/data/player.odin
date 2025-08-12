package data

Player :: struct {
    account_name    : string,
    character_name  : string,

    intel_points_avail: int,
    skill_points_avail: int,

    backpack: ^Container,
    // loadout: ^Container,
    deposit: ^Container,
}

player: Player

create_player :: proc () {
    player = Player {
        account_name    = "spacemad#12345",
        character_name  = "Skywalker",

        intel_points_avail = 123,
        skill_points_avail = 1,

        backpack    = create_container(slot_count=35, max_volume=175),
        deposit     = create_container(slot_count=30, max_volume=800),
    }

    css :: container_set_slot
    css(player.backpack, { item=get_item("solari"), count=23508 })
    css(player.backpack, { item=get_item("heavy_darts"), count=218 })
    css(player.backpack, { item=get_item("welding_wire"), count=227 })
    css(player.backpack, { item=get_item("hajra_literjon_mk1"), durability={ value=44, unrepairable=33 }, liquid_amount=1077 })
    css(player.backpack, { item=get_item("small_blood_sack"), durability={ value=77 }, liquid_amount=1333 })
    css(player.backpack, { item=get_item("medium_sized_vehicle_fuel_cell"), liquid_amount=777 })
    css(player.backpack, { item=get_item("double_sealed_stilltent"), durability={ value=100 } })
    css(player.backpack, { item=get_item("plant_fiber"), count=299 })
    css(player.backpack, { item=get_item("salvaged_metal"), count=488 })

    css(player.deposit, { item=get_item("salvaged_metal"), count=500 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=400 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=300 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=200 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=100 })
}

destroy_player :: proc () {
    destroy_container(player.backpack)
    destroy_container(player.deposit)
}
