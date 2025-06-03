package demo8

import "core:fmt"
import "core:mem"
import "spacelib:core"

App_Data :: struct {
    traits  : map [string] App_Data_Trait,
    skills  : map [string] App_Data_Skill,
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

App_Data_Skill :: struct {
    name                : string,
    desc                : string,
    type                : App_Data_Skill_Type,
    icon                : string,
    using player_state  : struct {
        selected        : bool,
    },
}

App_Data_Skill_Type :: enum {
    none,
    hunter,
    alchemist,
}

App_Data_Item :: struct {
    name    : string,
    desc    : string,
    icon    : string,
    tags    : bit_set [App_Data_Item_Tag],
    count   : int,
    stats   : struct {
        armor,
        weight,
        res_bleed,
        res_fire,
        res_lightning,
        res_poison,
        res_blight: f32,
    },
}

App_Data_Item_Tag :: enum {
    consumable,
    curative,
    quest,
    material,
    gear,
    head_armor,
    body_armor,
    leg_armor,
    glove_armor,
    relic,
}

app_data_create :: proc () {
    app.data = new(App_Data)
    app_data_add_traits()
    app_data_add_skills()
    app_data_add_items()
}

app_data_destroy :: proc () {
    delete(app.data.traits)
    delete(app.data.skills)
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

app_data_add_skills :: proc () {
    s := &app.data.skills

    // hunter

    s["hunters_mark"] = { name="Hunter's Mark", icon="on-sight", type=.hunter, player_state={ true }, desc=
        "Increases the Hunter's spatial awareness by casting an Aura that automatically applies "+
        "<color=trait_hl>MARK</color> to all enemies within <color=bw_ff>35m</color>. While senses "+
        "are heightened, Hunter also gains <color=bw_ff>15%</color> increased Ranged and Melee damage. "+
        "Lasts <color=bw_ff>25.4s</color>.\n\n"+
        "Cooldown: <color=bw_ff>56s</color>.\n\n"+
        "<color=trait_hl>MARK</color>: Crit Chance against <color=trait_hl>MARKED</color> enemies is "+
        "increased by <color=bw_ff>10%</color> for all allies.",
    }

    s["hunters_focus"] = { name="Hunter's Focus", icon="bandit", type=.hunter, desc=
        "Continuously Aiming Down Sights uninterrupted and without shooting for <color=bw_ff>0.5s</color> "+
        "causes the Hunter to enter a <color=trait_hl>FOCUSED</color> state. Wears off after "+
        "<color=bw_ff>0.75s</color> of leaving Aim. Lasts <color=bw_ff>25.4s</color>.\n\n"+
        "<color=trait_hl>FOCUSED</color> reduces Weapon Spread, Recoil, and Sway by "+
        "<color=bw_ff>50%</color>, and grants <color=bw_ff>25%</color> Ranged & Ranged Weakspot Damage. "+
        "While <color=trait_hl>FOCUSED</color>, aiming at enemies will automatically apply "+
        "<color=trait_hl>MARK</color>.\n\n"+
        "Cooldown: <color=bw_ff>40s</color>.\n\n"+
        "<color=trait_hl>MARK</color>: Crit Chance against <color=trait_hl>MARKED</color> enemies "+
        "is increased by <color=bw_ff>10%</color> for all allies.",
    }

    s["hunters_shroud"] = { name="Hunter's Shroud", icon="shadow-follower", type=.hunter, desc=
        "Hunter becomes Shrouded, reducing enemy awareness and making them harder to hit while"+
        "moving. Attacking or activating a Mod or Skill will instantly exit Shroud.\n\n"+
        "Exiting Shroud applies <color=trait_hl>MARK</color> to all enemies within <color=bw_ff>15m</color> "+
        "and grants <color=trait_hl>AMBUSH</color> to the Hunter for <color=bw_ff>2s</color>.\n\n"+
        "<color=trait_hl>AMBUSH</color>: Increases Ranged and Melee Damage by <color=bw_ff>50%</color> "+
        "which diminishes over its duration. Ranged and Melee attacks apply <color=trait_hl>MARK</color>.\n\n"+
        "Hunter will automatically Shroud again after <color=bw_ff>1.15s</color> if no offensive actions "+
        "are performed.\n\n"+
        "Lasts: <color=bw_ff>15.2s</color>.\n\n"+
        "Cooldown: <color=bw_ff>72s</color>.\n\n"+
        "<color=trait_hl>MARK</color>: Crit Chance against <color=trait_hl>MARKED</color> enemies is "+
        "increased by <color=bw_ff>10%</color> for all allies",
    }

    // alchemist

    s["vial_stone_mist"] = { name="Vial: Stone Mist", icon="rock", type=.alchemist, desc=
        "Creates a mysterious vapor cloud which lasts <color=bw_ff>10.2s</color> and applies "+
        "<color=trait_hl>STONESKIN</color>.\n\n"+
        "<color=trait_hl>STONESKIN</color> reduces incoming damage by <color=bw_ff>25%</color>, "+
        "reduces Stagger by <color=bw_ff>1</color>, greatly increases Blight Buildup Decay Rate, "+
        "and makes the target immune to <color=trait_hl>STATUS</color> Effects. "+
        "Lasts <color=bw_ff>15.2s</color>.\n\n"+
        "<color=bw_ff>PRESS</color>: Slam Vial on the ground, creating the effect at the Alchemist's feet.\n\n"+
        "<color=bw_ff>HOLD & RELEASE</color>: Aim and throw the Vial causing the same effect where it lands.\n\n"+
        "Cooldown: <color=bw_ff>60s</color>.",
    }

    s["vial_frenzy_dust"] = { name="Vial: Frenzy Dust", icon="open-wound", type=.alchemist, player_state={ true }, desc=
        "Creates a mysterious vapor cloud which lasts <color=bw_ff>10.2s</color> and applies "+
        "<color=trait_hl>FRENZIED</color>.\n\n"+
        "<color=trait_hl>FRENZIED</color> increases Fire Rate, Reload Speed, and Melee Speed by "+
        "<color=bw_ff>20%</color>, and Movement Speed by <color=bw_ff>15%</color>. Lasts <color=bw_ff>15.2s</color>.\n\n"+
        "<color=bw_ff>PRESS</color>: Slam Vial on the ground, creating the effect at the Alchemist's feet.\n\n"+
        "<color=bw_ff>HOLD & RELEASE</color>: Aim and throw the Vial causing the same effect where it lands.\n\n"+
        "Cooldown: <color=bw_ff>60s</color>.",
    }

    s["vial_elixir_of_life"] = { name="Vial: Elixir Of Life", icon="standing-potion", type=.alchemist, desc=
        "Creates a mysterious vapor cloud that lasts <color=bw_ff>10.2s</color> and applies "+
        "<color=trait_hl>LIVING WILL</color>.\n\n"+
        "<color=trait_hl>LIVING WILL</color> grants <color=bw_ff>5</color> Health Regeneration per second, "+
        "and protects against fatal damage. Can revive downed players. Lasts <color=bw_ff>20.3s</color>.\n\n"+
        "Revived allies cannot be affected by Living Will for <color=bw_ff>180s</color>. Resets at "+
        "Worldstone or on death.\n\n"+
        "<color=bw_ff>PRESS</color>: Slam Vial on the ground, creating the effect at the Alchemist's feet.\n\n"+
        "<color=bw_ff>HOLD & RELEASE</color>: Aim and throw the Vial causing the same effect where it lands.\n\n"+
        "Cooldown: <color=bw_ff>72s</color>.",
    }
}

app_data_add_items :: proc () {
    i := &app.data.items

    // consumables

    i["bandage"] = { name="Bandage", icon="bandage-roll", tags={.consumable}, count=21,
        desc="Stops <color=res_bleed>BLEEDING</color> and restores all Grey Health." }
    i["ammo_box"] = { name="Ammo Box", icon="ammo-box", tags={.consumable}, count=6 }
    i["oilskin_balm"] = { name="Oilskin Balm", icon="potion-ball", tags={.consumable,.curative}, count=2,
        desc="Cures <color=blight_rot>ROOT ROT</color> Blight and increases Blight Resistance by <color=bw_ff>25</color>. Lasts <color=bw_ff>19m</color>." }
    i["liquid_escape"] = { name="Liquid Escape", icon="broken-skull", tags={.consumable}, count=1,
        desc="When consumed, the hero will be returned to the last activated checkpoint." }

    // quest items

    i["lighter"] = { name="Lighter", icon="lighter", tags={.quest}, count=1 }
    i["broken_tablet"] = { name="Broken Tablet", icon="broken-tablet", tags={.quest}, count=1 }
    i["crown_coin"] = { name="Crown Coin", icon="crown-coin", tags={.quest}, count=1 }
    i["corrupted_shard"] = { name="Corrupted Shard", icon="rock", tags={.quest}, count=1,
        desc="The crystal sizzles with unrefined power, sending, jolts of energy and aberrant whispers through every synapse of your being. Whatever essence once dwelled within this shard, it has long been separated from its source... and inhabited by something new." }
    i["cordyceps_gland"] = { name="Cordyceps Gland", icon="tumor", tags={.quest}, count=1,
        desc="Voices and whispers. You hear them every time you hold this wet viscera in your hand. Hundreds of them. Thousands. Dissonant and uncaring." }

    // materials

    i["faith_seed"] = { name="Faith Seed", icon="plant-seed", tags={.material}, count=1 }
    i["lost_crystal"] = { name="Lost Crystal", icon="floating-crystal", tags={.material}, count=7 }
    i["log"] = { name="Log", icon="log", tags={.material}, count=123 }
    i["crumbling_ball"] = { name="Crumbling Ball", icon="crumbling-ball", tags={.material}, count=1 }
    i["acid_tube"] = { name="Acid Tube", icon="corked-tube", tags={.material}, count=3 }
    i["cloth_scrap"] = { name="Cloth Scrap", icon="rolled-cloth", tags={.material}, count=10 }
    i["chared_berries"] = { name="Chared Berries", icon="elderberry", tags={.material}, count=1 }
    i["feather"] = { name="Feather", icon="feather", tags={.material}, count=4 }
    i["paper_sheet"] = { name="Paper Sheet", icon="papers", tags={.material}, count=24 }
    i["vanilla_flower"] = { name="Vanilla Flower", icon="vanilla-flower", tags={.material}, count=1 }
    i["salt"] = { name="Salt", icon="powder", tags={.material}, count=8 }

    // gear

    i["leto_mark_2_helmet"] = { name="Leto Mark II Helmet", icon="visored-helm", tags={.gear,.head_armor}, count=1,
        desc="While this ironclad helmet is somewhat difficult to breathe in, you feel secure knowing even the heaviest weapon would have little chance of cracking into your skull.",
        stats={ armor=21.8, weight=11.1, res_bleed=2, res_fire=3, res_lightning=1, res_poison=2, res_blight=1 },
    }
    i["academics_overcoat"] = { name="Academic's Overcoat", icon="shoulder-armor", tags={.gear,.body_armor}, count=1,
        desc="Donning this uniform makes you feel a touch smarter, and you can't help but straighten the necktie whenever it slips loose.",
        stats={ armor=49.2, weight=20.8, res_bleed=2, res_poison=6, res_blight=3 },
    }
    i["academics_trousers"] = { name="Academic's Trousers", icon="leg-armor", tags={.gear,.leg_armor}, count=1,
        desc="Expensive-looking shoes fit for a lecture hall ... that wouldn't last a week outside it.",
        stats={ armor=24.6, weight=10.4, res_bleed=2, res_poison=4, res_blight=1 },
    }
    i["academics_gloves"] = { name="Academic's Gloves", icon="gloves", tags={.gear,.glove_armor}, count=1,
        desc="The initials of the Dran who once owned these--and misplaced them often--are embroidered on the wool-lined inside.",
        stats={ armor=12.3, weight=5.2, res_poison=2, res_blight=1 },
    }

    // artifacts

    i["resonating_heart"] = { name="Resonating Heart", icon="dragon-orb", tags={.gear,.relic}, count=1,
        desc="On use, regenerates <color=bw_ff>50%</color> of Max Health over <color=bw_ff>5s</color>. "+
        "When heal ends, any overhealed Health to self is <color=bw_ff>Doubled</color> and awarded over "+
        "the next <color=bw_ff>20s</color>.",
    }
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
