package demo8

import "core:fmt"
import "core:mem"
import "spacelib:core"

App_Data :: struct {
    traits  : map [string] App_Data_Trait,
    items   : map [string] App_Data_Item,
}

max_trait_levels :: 10

App_Data_Trait :: struct {
    name                : string,
    desc                : App_Data_Trait_Desc_Proc,
    level_desc          : App_Data_Trait_Level_Desc_Proc,
    icon                : string,
    type                : App_Data_Trait_Type,
    using player_state  : struct {
        levels_granted  : int,
        levels_bought   : int,
        active          : bool,
    },
}

App_Data_Trait_Desc_Proc        :: proc (trait: App_Data_Trait, allocator: mem.Allocator) -> string
App_Data_Trait_Level_Desc_Proc  :: proc (trait: App_Data_Trait, level: int, allocator: mem.Allocator) -> string

App_Data_Trait_Type :: enum {
    none,
    core,
    hunter,
    alchemist,
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

    t["longshot"] = { name="Longshot", icon="silver-bullet", type=.hunter,
        desc = proc (trait: App_Data_Trait, allocator := context.allocator) -> string {
            value := .6 * f32(trait.levels_granted + trait.levels_bought)
            return fmt.aprintf(
                "Increases Weapon Ideal Range by <color=bw_ff>%vm</color>.\n\n"+
                "<color=trait_hl>HUNTER</color> Archetype Trait.",
                value, allocator=allocator,
            )
        },
        level_desc = proc (trait: App_Data_Trait, level: int, allocator := context.allocator) -> string {
            value := 60 * level
            return fmt.aprintf("Level %i: %+v Weapon Ideal Range (cm)", level, value, allocator=allocator)
        },
        player_state = { 10, 0, true },
    }

    t["potency"] = { name="Potency", icon="evil-book", type=.alchemist,
        desc = proc (trait: App_Data_Trait, allocator := context.allocator) -> string {
            value := 10 * (trait.levels_granted + trait.levels_bought)
            return fmt.aprintf(
                "Increases Consumable Duration by <color=bw_ff>%v%%</color>.\n\n"+
                "<color=trait_hl>ALCHEMIST</color> Archetype Trait.",
                value, allocator=allocator,
            )
        },
        level_desc = proc (trait: App_Data_Trait, level: int, allocator := context.allocator) -> string {
            value := 10 * level
            return fmt.aprintf("Level %i: %+v%% Consumable Duration", level, value, allocator=allocator)
        },
        player_state = { 9, 0, true },
    }

    t["vigor"] = { name="Vigor", icon="fist", type=.core,
        desc = proc (trait: App_Data_Trait, allocator := context.allocator) -> string {
            value := 3 * (trait.levels_granted + trait.levels_bought)
            return fmt.aprintf("Increases Max Health by <color=bw_ff>%v</color>.", value, allocator=allocator)
        },
        level_desc = proc (trait: App_Data_Trait, level: int, allocator := context.allocator) -> string {
            value := 3 * level
            return fmt.aprintf("Level %i: %+v Health", level, value, allocator=allocator)
        },
        player_state = { 1, 9, false },
    }

    t["endurance"] = { name="Endurance", icon="cracked-helm", type=.core,
        desc = proc (trait: App_Data_Trait, allocator := context.allocator) -> string {
            value := 3 * (trait.levels_granted + trait.levels_bought)
            return fmt.aprintf("Increases Max Stamina by <color=bw_ff>%v</color>.", value, allocator=allocator)
        },
        level_desc = proc (trait: App_Data_Trait, level: int, allocator := context.allocator) -> string {
            value := 3 * level
            return fmt.aprintf("Level %i: %+v Stamina", level, value, allocator=allocator)
        },
        player_state = { 2, 2, false },
    }

    t["spirit"] = { name="Spirit", icon="candlebright", type=.core,
        desc = proc (trait: App_Data_Trait, allocator := context.allocator) -> string {
            value := 2 * (trait.levels_granted + trait.levels_bought)
            return fmt.aprintf("Increases Mod Power Generation by <color=bw_ff>%v%%</color>.", value, allocator=allocator)
        },
        level_desc = proc (trait: App_Data_Trait, level: int, allocator := context.allocator) -> string {
            value := 2 * level
            return fmt.aprintf("Level %i: %+v%% Mod Power Generation", level, value, allocator=allocator)
        },
        player_state = { 0, 4, false },
    }

    t["expertise"] = { name="Expertise", icon="power-lightning", type=.core,
        desc = proc (trait: App_Data_Trait, allocator := context.allocator) -> string {
            value := 2 * (trait.levels_granted + trait.levels_bought)
            return fmt.aprintf("Reduces Skill Cooldowns by <color=bw_ff>%v%%</color>.", value, allocator=allocator)
        },
        level_desc = proc (trait: App_Data_Trait, level: int, allocator := context.allocator) -> string {
            value := 2 * level
            return fmt.aprintf("Level %i: %+v%% Skill Cooldown", level, value, allocator=allocator)
        },
        player_state = { 2, 8, false },
    }

    t["amplitude"] = { name="Amplitude", icon="ink-swirl",
        desc = proc (trait: App_Data_Trait, allocator := context.allocator) -> string {
            value := 5 * (trait.levels_granted + trait.levels_bought)
            return fmt.aprintf("Increases AOE and AURA Size by <color=bw_ff>%v%%</color>.", value, allocator=allocator)
        },
        level_desc = proc (trait: App_Data_Trait, level: int, allocator := context.allocator) -> string {
            value := 5 * level
            return fmt.aprintf("Level %i: %+v%% AOE and AURA Size", level, value, allocator=allocator)
        },
        player_state = { 0, 10, false },
    }

    t["blood_bond"] = { name="Blood Bond", icon="open-wound",
        desc = proc (trait: App_Data_Trait, allocator := context.allocator) -> string {
            value := 1 * (trait.levels_granted + trait.levels_bought)
            return fmt.aprintf("Skill Summons absorb <color=bw_ff>%v%%</color> of damage taken by the caster.", value, allocator=allocator)
        },
        level_desc = proc (trait: App_Data_Trait, level: int, allocator := context.allocator) -> string {
            value := 1 * level
            return fmt.aprintf("Level %i: %v%% Damage Absorbed", level, value, allocator=allocator)
        },
    }

    t["bloodstream"] = { name="Bloodstream", icon="gloop",
        desc = proc (trait: App_Data_Trait, allocator := context.allocator) -> string {
            value := .3 * f32(trait.levels_granted + trait.levels_bought)
            return fmt.aprintf("Increases Grey Health Regeneration by <color=bw_ff>%.1f/s</color>.", value, allocator=allocator)
        },
        level_desc = proc (trait: App_Data_Trait, level: int, allocator := context.allocator) -> string {
            value := .3 * f32(level)
            return fmt.aprintf("Level %i: %.1f/s Grey Health Regeneration", level, value, allocator=allocator)
        },
    }

    t["siphoner"] = { name="Siphoner", icon="tesla",
        desc = proc (trait: App_Data_Trait, allocator := context.allocator) -> string {
            value := .3 * f32(trait.levels_granted + trait.levels_bought)
            return fmt.aprintf("Grants <color=bw_ff>%.1f%%</color> base damage as Lifesteal.", value, allocator=allocator)
        },
        level_desc = proc (trait: App_Data_Trait, level: int, allocator := context.allocator) -> string {
            value := .3 * f32(level)
            return fmt.aprintf("Level %i: %+.1f%% Lifesteal", level, value, allocator=allocator)
        },
        player_state = { 0, 5, false },
    }
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

app_data_item_ids_filtered_by_tag :: proc (tag: App_Data_Item_Tag, allocator := context.allocator) -> [] string {
    result := make([dynamic] string, allocator)
    for id in core.map_keys_sorted(app.data.items, context.temp_allocator) {
        if tag in app.data.items[id].tags {
            append(&result, id)
        }
    }
    return result[:]
}
