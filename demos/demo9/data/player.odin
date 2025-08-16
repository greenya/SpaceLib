package data

Player :: struct {
    account_name    : string,
    character_name  : string,

    intel_points_avail: int,
    skill_points_avail: int,

    equipment   : ^Container,
    loadout     : ^Container,
    backpack    : ^Container,
    deposit     : ^Container,
}

Player_Equipment_Slot_Idx :: enum {
    head,
    chest,
    legs,
    hands,
    feet,
    shield,
    belt,
    light,
    power,
}

player_equipment_slot_spec := [Player_Equipment_Slot_Idx] Item_Tag {
    .head   = .slot_head,
    .chest  = .slot_chest,
    .legs   = .slot_legs,
    .hands  = .slot_hands,
    .feet   = .slot_feet,
    .shield = .slot_shield,
    .belt   = .slot_belt,
    .light  = .slot_light,
    .power  = .slot_power,
}

player: Player

create_player :: proc () {
    player = Player {
        account_name    = "spacemad#12345",
        character_name  = "Skywalker",

        intel_points_avail = 123,
        skill_points_avail = 1,
    }

    css :: container_set_slot
    pes :: Player_Equipment_Slot_Idx

    // equipment container

    player.equipment = create_container(slot_count=len(Player_Equipment_Slot_Idx), max_volume=100)
    for s, i in player_equipment_slot_spec do player.equipment.slots[i].spec = s

    css(player.equipment, { item=get_item("the_jackals_blindfold"), durability={value=77} }, slot_idx=int(pes.head))
    css(player.equipment, { item=get_item("batigh_stillsuit_garment"), durability={value=66}, liquid_amount=500 }, slot_idx=int(pes.chest))
    css(player.equipment, { item=get_item("slaver_heavy_pants"), durability={value=55} }, slot_idx=int(pes.legs))
    css(player.equipment, { item=get_item("mercenary_stillsuit_gloves"), durability={value=44} }, slot_idx=int(pes.hands))
    css(player.equipment, { item=get_item("talab_softstep_boots"), durability={value=66,unrepairable=34} }, slot_idx=int(pes.feet))

    // loadout container

    player.loadout = create_container(slot_count=8, max_volume=100)
    for &s in player.loadout.slots do s.spec = .slot_loadout

    css(player.loadout, { item=get_item("spark_sword"), durability={value=35,unrepairable=10} })
    css(player.loadout, { item=get_item("long_shot"), durability={value=65,unrepairable=18} })
    css(player.loadout, { item=get_item("healkit"), count=20 })
    css(player.loadout, { item=get_item("industrial_cutteray_mk4"), durability={value=100} })
    css(player.loadout, { item=get_item("binoculars") })

    // backpack container

    player.backpack = create_container(slot_count=35, max_volume=175)

    css(player.backpack, { item=get_item("solari"), count=23508 })
    css(player.backpack, { item=get_item("heavy_darts"), count=218 })
    css(player.backpack, { item=get_item("welding_wire"), count=227 })
    css(player.backpack, { item=get_item("hajra_literjon_mk1"), durability={value=44,unrepairable=33}, liquid_amount=1077 })
    css(player.backpack, { item=get_item("large_blood_sack"), durability={value=77}, liquid_amount=2345 })
    css(player.backpack, { item=get_item("medium_sized_vehicle_fuel_cell"), liquid_amount=777 })
    css(player.backpack, { item=get_item("double_sealed_stilltent"), durability={value=100} })
    css(player.backpack, { item=get_item("plant_fiber"), count=299 })
    css(player.backpack, { item=get_item("salvaged_metal"), count=488 })

    css(player.backpack, { item=get_item("compact_compactor_mk5"), durability={value=100} }, slot_idx=16)
    css(player.backpack, { item=get_item("young_sparky_mk5"), durability={value=100} }, slot_idx=17)
    css(player.backpack, { item=get_item("welding_torch_mk5"), durability={value=30,unrepairable=55} }, slot_idx=18)

    // deposit container

    player.deposit = create_container(slot_count=30, max_volume=800)

    css(player.deposit, { item=get_item("salvaged_metal"), count=500 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=400 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=300 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=200 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=100 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=50 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=20 })
    css(player.deposit, { item=get_item("salvaged_metal"), count=10 })
}

destroy_player :: proc () {
    destroy_container(player.equipment)
    destroy_container(player.loadout)
    destroy_container(player.backpack)
    destroy_container(player.deposit)
}
