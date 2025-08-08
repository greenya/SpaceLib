package data

import "core:encoding/json"
import "core:fmt"

Item :: struct {
    id          : string,
    name        : string,
    desc        : Text,
    tag_list    : [] Item_Tag `fmt:"-"`,
    origin      : Item_Origin,
    tier        : int,
    volume      : f32,
    stack       : int,
    icon        : string,
    image       : string,

    stats_belt          : Item_Stats_Belt           `fmt:"-"`,
    stats_blood_sack    : Item_Stats_Blood_Sack     `fmt:"-"`,
    stats_compactor     : Item_Stats_Compactor      `fmt:"-"`,
    stats_cutteray      : Item_Stats_Cutteray       `fmt:"-"`,
    stats_fuel_cell     : Item_Stats_Fuel_Cell      `fmt:"-"`,
    stats_garment       : Item_Stats_Garment        `fmt:"-"`,
    stats_healkit       : Item_Stats_Healkit        `fmt:"-"`,
    stats_literjon      : Item_Stats_Literjon       `fmt:"-"`,
    stats_power         : Item_Stats_Power          `fmt:"-"`,
    stats_shield        : Item_Stats_Shield         `fmt:"-"`,
    stats_stilltent     : Item_Stats_Stilltent      `fmt:"-"`,
    stats_weapon_melee  : Item_Stats_Weapon_Melee   `fmt:"-"`,
    stats_weapon_ranged : Item_Stats_Weapon_Ranged  `fmt:"-"`,
    stats_welding_torch : Item_Stats_Welding_Torch  `fmt:"-"`,

    // these values get manual init after json loaded, see below
    tags    : bit_set [Item_Tag],
    stats   : Item_Stats,
}

Item_Tag :: enum {
    ammunition,
    building_tools,
    components,
    consumables,
    deployables,
    exploration,
    fuel,
    gathering_tools,
    heavy_armor,
    hydration_tools,
    light_armor,
    long_blades,
    raw_resources,
    refined_resources,
    rifles,
    scatterguns,
    short_blades,
    sidearms,
    slot_belt,
    slot_body,
    slot_feet,
    slot_hands,
    slot_head,
    slot_light,
    slot_power,
    slot_shield,
    slot_weapon,
    solaris,
    stillsuits,
    utility_tools,
}

Item_Tag_Category_Weapons :: bit_set [Item_Tag] {
    .ammunition,
    .long_blades,
    .rifles,
    .scatterguns,
    .short_blades,
    .sidearms,
}

Item_Tag_Category_Garment :: bit_set [Item_Tag] {
    .heavy_armor,
    .light_armor,
    .stillsuits,
}

Item_Tag_Category_Utility :: bit_set [Item_Tag] {
    .building_tools,
    .consumables,
    .deployables,
    .exploration,
    .gathering_tools,
    .hydration_tools,
    .utility_tools,
}

Item_Tag_Category_Misc :: bit_set [Item_Tag] {
    .components,
    .fuel,
    .raw_resources,
    .refined_resources,
    .solaris,
}

// check if we accidentally included same tag to separate categories
#assert(Item_Tag_Category_Weapons & Item_Tag_Category_Garment == {})
#assert(Item_Tag_Category_Weapons & Item_Tag_Category_Utility == {})
#assert(Item_Tag_Category_Weapons & Item_Tag_Category_Misc == {})
#assert(Item_Tag_Category_Garment & Item_Tag_Category_Utility == {})
#assert(Item_Tag_Category_Garment & Item_Tag_Category_Misc == {})
#assert(Item_Tag_Category_Utility & Item_Tag_Category_Misc == {})

Item_Origin :: enum {
    none,
    imperial,
    house,
    fremen,
    unique,
    special,
}

Item_Stats :: union {
    Item_Stats_Belt,
    Item_Stats_Blood_Sack,
    Item_Stats_Compactor,
    Item_Stats_Cutteray,
    Item_Stats_Fuel_Cell,
    Item_Stats_Garment,
    Item_Stats_Healkit,
    Item_Stats_Literjon,
    Item_Stats_Power,
    Item_Stats_Shield,
    Item_Stats_Stilltent,
    Item_Stats_Weapon_Melee,
    Item_Stats_Weapon_Ranged,
    Item_Stats_Welding_Torch,
}

Item_Stats_Belt :: struct {
    worm_attraction_intensity   : enum { extreme },
    power_drain                 : f32,
}

Item_Stats_Blood_Sack :: struct {
    container_capacity: f32,
}

Item_Stats_Compactor :: struct {
    gather_rate                 : enum { high },
    power_consumption           : f32,
    worm_attraction_intensity   : enum { medium },
}

Item_Stats_Cutteray :: struct {
    power_consumption_per_second: f32,
}

Item_Stats_Fuel_Cell :: struct {
    container_capacity: f32,
}

Item_Stats_Garment :: struct {
    armor_value             : f32,
    dash_stamina_cost       : f32,
    worm_threat             : f32,
    sun_stroke_rate         : f32,
    hydration_capture       : f32,
    light_dart_mitigation   : f32,
    heavy_dart_mitigation   : f32,
    energy_mitigation       : f32,
    blade_mitigation        : f32,
    concussive_mitigation   : f32,
    poison_mitigation       : f32,
    heat_protection         : f32,
    catchpocket_size        : f32,
}

Item_Stats_Healkit :: struct {
    health_restoration_over_time: f32,
    instant_health_restoration  : f32,
}

Item_Stats_Literjon :: struct {
    container_capacity: f32,
}

Item_Stats_Power :: struct {
    regen_per_second: f32,
    power_pool      : f32,
}

Item_Stats_Shield :: struct {
    worm_attraction_intensity   : enum { extreme },
    shield_refresh_time         : f32,
    power_drain_percent         : f32,
}

Item_Stats_Stilltent :: struct {
    water_gather_rate: f32,
}

Item_Stats_Weapon_Melee :: struct {
    damage_type     : enum { blade },
    damage_per_hit  : f32,
    attack_speed    : f32,
}

Item_Stats_Weapon_Ranged :: struct {
    damage_type     : enum { light_dart, heavy_dart },
    fire_mode       : enum { semi_automatic, automatic },
    damage_per_shot : f32,
    rate_of_fire    : int, // in RPM
    clip_size       : int,
    reload_speed    : f32, // in seconds
    effective_range : f32, // in meters
    accuracy        : f32,
    stability       : f32,
}

Item_Stats_Welding_Torch :: struct {
    range                       : enum { long },
    repair_quality              : f32,
    repair_speed                : f32,
    detach_speed                : f32,
    power_consumption_per_second: f32,
}

@private items: [] Item

@private
create_items :: proc () {
    assert(items == nil)
    err := json.unmarshal_any(#load("items.json"), &items)
    fmt.ensuref(err == nil, "Failed to load items.json: %v", err)

    // set "stack" to be 1 in case it is unset
    for &i in items do if i.stack == 0 do i.stack = 1

    // init "tags" bit set
    for &i in items do for &t in i.tag_list do i.tags += { t }

    // init "stats" union
    for &i in items do switch {
    case i.stats_belt != {}             : i.stats = i.stats_belt
    case i.stats_blood_sack != {}       : i.stats = i.stats_blood_sack
    case i.stats_compactor != {}        : i.stats = i.stats_compactor
    case i.stats_cutteray != {}         : i.stats = i.stats_cutteray
    case i.stats_fuel_cell != {}        : i.stats = i.stats_fuel_cell
    case i.stats_garment != {}          : i.stats = i.stats_garment
    case i.stats_healkit != {}          : i.stats = i.stats_healkit
    case i.stats_literjon != {}         : i.stats = i.stats_literjon
    case i.stats_shield != {}           : i.stats = i.stats_shield
    case i.stats_stilltent != {}        : i.stats = i.stats_stilltent
    case i.stats_weapon_melee != {}     : i.stats = i.stats_weapon_melee
    case i.stats_weapon_ranged != {}    : i.stats = i.stats_weapon_ranged
    case i.stats_welding_torch != {}    : i.stats = i.stats_welding_torch
    }

    // fmt.printfln("%#v", items)
}

@private
destroy_items :: proc () {
    for i in items {
        delete(i.id)
        delete(i.name)
        delete_text(i.desc)
        delete(i.tag_list)
        delete(i.icon)
        delete(i.image)
    }
    delete(items)
    items = nil
}

get_item :: proc (id: string) -> ^Item {
    assert(id != "")
    for &i in items do if i.id == id do return &i
    fmt.panicf("Item \"%s\" was not found", id)
}

item_water_capacity :: proc (item: Item) -> f32 {
    #partial switch s in item.stats {
    case Item_Stats_Garment : return s.catchpocket_size
    case Item_Stats_Literjon: return s.container_capacity
    }
    return 0
}

item_blood_capacity :: proc (item: Item) -> f32 {
    #partial switch s in item.stats {
    case Item_Stats_Blood_Sack: return s.container_capacity
    }
    return 0
}

item_fuel_capacity :: proc (item: Item) -> f32 {
    #partial switch s in item.stats {
    case Item_Stats_Fuel_Cell: return s.container_capacity
    }
    return 0
}
