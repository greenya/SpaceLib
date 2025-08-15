package data

import "core:encoding/json"
import "core:fmt"

Item :: struct {
    id              : string,
    name            : string,
    desc            : Text,
    tag_list        : [] Item_Tag `fmt:"-"`,
    origin          : Item_Origin,
    tier            : int,
    volume          : f32,
    durability      : f32,
    stack           : int,
    liquid_container: Item_Liquid_Container,
    icon            : string,

    stats_belt          : Item_Stats_Belt           `fmt:"-"`,
    stats_compactor     : Item_Stats_Compactor      `fmt:"-"`,
    stats_cutteray      : Item_Stats_Cutteray       `fmt:"-"`,
    stats_garment       : Item_Stats_Garment        `fmt:"-"`,
    stats_healkit       : Item_Stats_Healkit        `fmt:"-"`,
    stats_power_pack    : Item_Stats_Power_Pack     `fmt:"-"`,
    stats_shield        : Item_Stats_Shield         `fmt:"-"`,
    stats_stilltent     : Item_Stats_Stilltent      `fmt:"-"`,
    stats_weapon_melee  : Item_Stats_Weapon_Melee   `fmt:"-"`,
    stats_weapon_ranged : Item_Stats_Weapon_Ranged  `fmt:"-"`,
    stats_welding_torch : Item_Stats_Welding_Torch  `fmt:"-"`,

    // these values get manual init after json loaded
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

item_tag_names := #partial [Item_Tag] string {
    .ammunition         = "Ammunition",
    .building_tools     = "Building Tools",
    .components         = "Components",
    .consumables        = "Consumables",
    .deployables        = "Deployables",
    .exploration        = "Exploration",
    .fuel               = "Fuel",
    .gathering_tools    = "Gathering Tools",
    .heavy_armor        = "Heavy Armor",
    .hydration_tools    = "Hydration Tools",
    .light_armor        = "Light Armor",
    .long_blades        = "Long Blades",
    .raw_resources      = "Raw Resources",
    .refined_resources  = "Refined Resources",
    .rifles             = "Rifles",
    .scatterguns        = "Scatterguns",
    .short_blades       = "Short Blades",
    .sidearms           = "Sidearms",
    .solaris            = "Solaris",
    .stillsuits         = "Stillsuits",
    .utility_tools      = "Utility Tools",
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

Item_Liquid_Container :: struct {
    type    : Item_Liquid_Container_Type,
    capacity: f32,
}

Item_Liquid_Container_Type :: enum {
    none,
    water,
    blood,
    fuel,
}

Item_Stats :: union {
    Item_Stats_Belt,
    Item_Stats_Compactor,
    Item_Stats_Cutteray,
    Item_Stats_Garment,
    Item_Stats_Healkit,
    Item_Stats_Power_Pack,
    Item_Stats_Shield,
    Item_Stats_Stilltent,
    Item_Stats_Weapon_Melee,
    Item_Stats_Weapon_Ranged,
    Item_Stats_Welding_Torch,
}

Item_Stats_Belt :: struct {
    worm_attraction_intensity   : Item_Stat_Type_Intensity,
    power_drain                 : f32,
}

Item_Stats_Compactor :: struct {
    gather_rate                 : Item_Stat_Type_Intensity,
    power_consumption           : f32,
    worm_attraction_intensity   : Item_Stat_Type_Intensity,
}

Item_Stats_Cutteray :: struct {
    power_consumption_per_second: f32,
}

Item_Stats_Garment :: struct {
    armor_value             : f32,

    dash_stamina_cost       : f32,
    climbing_stamina_cost   : f32,
    worm_threat             : f32,
    sun_stroke_rate         : f32,

    blade_mitigation        : f32,
    light_dart_mitigation   : f32,
    heavy_dart_mitigation   : f32,
    energy_mitigation       : f32,
    concussive_mitigation   : f32,
    fire_mitigation         : f32,
    poison_mitigation       : f32,
    radiation_mitigation    : f32,

    hydration_capture       : f32,
    heat_protection         : f32,
}

Item_Stats_Healkit :: struct {
    health_restoration_over_time: f32,
    instant_health_restoration  : f32,
}

Item_Stats_Power_Pack :: struct {
    regen_per_second: f32,
    power_pool      : f32,
}

Item_Stats_Shield :: struct {
    worm_attraction_intensity   : Item_Stat_Type_Intensity,
    shield_refresh_time         : f32,
    power_drain_percent         : f32,
}

Item_Stats_Stilltent :: struct {
    water_gather_rate: f32,
}

Item_Stats_Weapon_Melee :: struct {
    damage_type     : Item_Stat_Type_Damage,
    damage_per_hit  : f32,
    attack_speed    : f32,
}

Item_Stats_Weapon_Ranged :: struct {
    damage_type     : Item_Stat_Type_Damage,
    fire_mode       : Item_Stat_Type_Fire_Mode,
    damage_per_shot : f32,
    rate_of_fire    : int, // in RPM
    clip_size       : int,
    reload_speed    : f32, // in seconds
    effective_range : f32, // in meters
    accuracy        : f32,
    stability       : f32,
}

Item_Stats_Welding_Torch :: struct {
    range                       : Item_Stat_Type_Range,
    repair_quality              : f32,
    repair_speed                : f32,
    detach_speed                : f32,
    power_consumption_per_second: f32,
}

Item_Stat_Type_Intensity :: enum { low, medium, high, extreme }
item_stat_type_intensity_names := [Item_Stat_Type_Intensity] string {
    .low        = "Low",
    .medium     = "Medium",
    .high       = "High",
    .extreme    = "Extreme",
}

Item_Stat_Type_Range :: enum { short, medium, long }
item_stat_type_range_names := [Item_Stat_Type_Range] string {
    .short  = "Short",
    .medium = "Medium",
    .long   = "Long",
}

Item_Stat_Type_Damage :: enum { blade, light_dart, heavy_dart, energy }
item_stat_type_damage_names := [Item_Stat_Type_Damage] string {
    .blade      = "Blade",
    .light_dart = "Light Dart",
    .heavy_dart = "Heavy Dart",
    .energy     = "Energy",
}

Item_Stat_Type_Fire_Mode :: enum { semi_automatic, automatic }
item_stat_type_fire_mode_names := [Item_Stat_Type_Fire_Mode] string {
    .semi_automatic = "Semi-Automatic",
    .automatic      = "Automatic",
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
    case i.stats_compactor != {}        : i.stats = i.stats_compactor
    case i.stats_cutteray != {}         : i.stats = i.stats_cutteray
    case i.stats_garment != {}          : i.stats = i.stats_garment
    case i.stats_healkit != {}          : i.stats = i.stats_healkit
    case i.stats_power_pack != {}       : i.stats = i.stats_power_pack
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
    }
    delete(items)
    items = nil
}

get_item :: proc (id: string) -> ^Item {
    assert(id != "")
    for &i in items do if i.id == id do return &i
    fmt.panicf("Item \"%s\" was not found", id)
}

get_item_category :: proc (item: ^Item) -> (category, sub_category: string) {
    switch {
    case Item_Tag_Category_Weapons & item.tags != {}    : category = "Weapons"
    case Item_Tag_Category_Garment & item.tags != {}    : category = "Garment"
    case Item_Tag_Category_Utility & item.tags != {}    : category = "Utility"
    case Item_Tag_Category_Misc & item.tags != {}       : category = "Misc"
    }

    for tag in item.tags do if item_tag_names[tag] != "" {
        sub_category = item_tag_names[tag]
        break
    }

    fmt.assertf(category != "" && sub_category != "", "Failed to categorize \"%s\": tags=%v", item.id, item.tags)
    return
}
