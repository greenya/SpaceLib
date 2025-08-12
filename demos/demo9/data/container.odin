package data

import "core:fmt"

Container :: struct {
    slots       : [dynamic] Container_Slot,
    max_volume  : f32,
}

Container_Slot :: struct {
    item            : ^Item,
    durability      : struct { value, unrepairable: f32 },
    liquid_amount   : f32,
    count           : int,
}

Container_Swap_Slots_Result :: enum {
    success,
    error_bad_slot_idx,
    error_src_slot_is_empty,
    error_not_enough_volume,
}

create_container :: proc (slot_count: int, max_volume: f32) -> ^Container {
    con := new (Container)
    con.max_volume = max_volume

    for _ in 0..<slot_count do append(&con.slots, Container_Slot {})
    shrink(&con.slots)

    return con
}

destroy_container :: proc (con: ^Container) {
    delete(con.slots)
    free(con)
}

container_set_slot :: proc (con: ^Container, slot: Container_Slot, slot_idx := -1) {
    ensure(slot.item != nil)

    // if slot.count is 0, we set it to 1 so it can be omitted (passed default/zero value);
    // and we want consistent slot.count, as if in future we want to add "split" and "stack" procs,
    // they don't need to think about extra friction with treating 0 as 1 when doing math;
    // note: maybe we should just ensure(slot.count>0) and require explicitness
    slot := slot
    if slot.count == 0 do slot.count = 1

    occupied_slots, max_slots, occupied_volume, max_volume := container_capacity(con^)
    ensure(occupied_slots < max_slots, "Container has no empty slots")

    fmt.ensuref(slot.count <= slot.item.stack,
        "Item stack size overflow. Item \"%s\" has stack size %i, and slot.count requested is %i",
        slot.item.id, slot.item.stack, slot.count,
    )

    if slot.item.durability > 0 {
        ensure(slot.durability.value + slot.durability.unrepairable <= slot.item.durability, "Item durability overflow")
    } else {
        ensure(slot.durability == {}, "Item is indestructible")
    }

    if slot.item.liquid_container.type != .none {
        ensure(slot.item.stack == 1, "Liquid amount can only be set for non-stackable items")
        ensure(slot.liquid_amount <= slot.item.liquid_container.capacity, "Item liquid container capacity overflow")
    } else {
        ensure(slot.liquid_amount == 0, "Item is not a liquid container")
    }

    slot_volume := container_slot_volume(slot)
    ensure(max_volume >= occupied_volume + slot_volume, "Container has no free volume")

    slot_idx := slot_idx
    ensure(slot_idx >= -1 && slot_idx < max_slots)
    if slot_idx == -1 {
        slot_idx = container_first_empty_slot_idx(con^)
    } else {
        ensure(con.slots[slot_idx].item == nil)
    }

    con.slots[slot_idx] = slot
}

container_capacity :: proc (con: Container) -> (occupied_slots, max_slots: int, occupied_volume, max_volume: f32) {
    max_slots = len(con.slots)
    max_volume = con.max_volume

    for s in con.slots do if s.item != nil {
        occupied_volume += container_slot_volume(s)
        occupied_slots += 1
    }

    return
}

container_first_empty_slot_idx :: proc (con: Container) -> int {
    for s, i in con.slots do if s.item == nil do return i
    panic("Container has no empty slots")
}

container_slot_volume :: proc (slot: Container_Slot) -> f32 {
    assert(slot.item == nil || (slot.item != nil && slot.count > 0))
    return slot.item != nil ? slot.item.volume * f32(slot.count) : 0
}

container_item_count :: proc (con: Container, item_id: string) -> (total: int) {
    for s in con.slots do if s.item != nil && s.item.id == item_id do total += s.count
    return
}

container_swap_slots :: proc (src_con: ^Container, src_slot_idx: int, dst_con: ^Container, dst_slot_idx: int) -> Container_Swap_Slots_Result {
    if src_slot_idx < 0 || src_slot_idx >= len(src_con.slots) do return .error_bad_slot_idx
    if dst_slot_idx < 0 || dst_slot_idx >= len(dst_con.slots) do return .error_bad_slot_idx

    src_slot := src_con.slots[src_slot_idx]
    dst_slot := dst_con.slots[dst_slot_idx]

    if src_slot.item == nil do return .error_src_slot_is_empty

    if src_con != dst_con {
        src_slot_volume := container_slot_volume(src_slot)
        dst_slot_volume := container_slot_volume(dst_slot)

        {
            _, _, now, max := container_capacity(src_con^)
            if now - src_slot_volume + dst_slot_volume > max do return .error_not_enough_volume
        }

        {
            _, _, now, max := container_capacity(dst_con^)
            if now - dst_slot_volume + src_slot_volume > max do return .error_not_enough_volume
        }
    }

    // all seems ok, do the swap
    dst_con.slots[dst_slot_idx] = src_slot
    src_con.slots[src_slot_idx] = dst_slot

    return .success
}
