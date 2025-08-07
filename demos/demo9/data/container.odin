package data

import "core:fmt"

Container :: struct {
    slots       : [dynamic] Container_Slot,
    max_volume  : f32,
}

Container_Slot :: struct {
    item_id     : string,
    count       : int,
    liquid_level: f32,
    durability  : struct { current, maximum, unrepairable: f32 },
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

container_add_item :: proc (con: ^Container, slot: Container_Slot, slot_idx := -1) {
    // if slot.count is 0, we set it to 1 so it can be omitted (passed default/zero value);
    // and we want consistent slot.count, as if in future we want to add "split" and "stack" procs,
    // they don't need to think about extra friction with treating 0 as 1 when doing math;
    // note: maybe we should just assert(slot.count > 0) and require explicitness
    slot := slot
    if slot.count == 0 do slot.count = 1

    occupied_slots, max_slots, occupied_volume, max_volume := container_capacity(con^)
    assert(occupied_slots < max_slots, "Container has no empty slots")

    item := get_item(slot.item_id)

    fmt.assertf(slot.count <= item.stack,
        "Item stack size overflow. Item \"%s\" has stack size %i, and slot count requested is %i",
        item.id, item.stack, slot.count,
    )

    slot_volume := item.volume * f32(slot.count)
    assert(max_volume >= occupied_volume + slot_volume, "Container has no free volume")

    slot_idx := slot_idx
    assert(slot_idx >= -1 && slot_idx < max_slots)
    if slot_idx == -1 {
        slot_idx = container_first_empty_slot_idx(con^)
    } else {
        assert(container_slot_is_empty(con^, slot_idx))
    }

    con.slots[slot_idx] = slot
}

container_capacity :: proc (con: Container) -> (occupied_slots, max_slots: int, occupied_volume, max_volume: f32) {
    max_slots = len(con.slots)
    max_volume = con.max_volume

    for s in con.slots do if s.item_id != "" {
        assert(s.count > 0)
        item := get_item(s.item_id)
        slot_volume := item.volume * f32(s.count)
        occupied_volume += slot_volume
        occupied_slots += 1
    }

    return
}

container_first_empty_slot_idx :: proc (con: Container) -> int {
    for s, i in con.slots do if s.item_id == "" do return i
    panic("Container has no empty slots")
}

container_slot_is_empty :: proc (con: Container, slot_idx: int) -> bool {
    assert(slot_idx >= 0 && slot_idx < len(con.slots))
    return con.slots[slot_idx].item_id == ""
}

container_item_count :: proc (con: Container, item_id: string) -> (total: int) {
    for s in con.slots do if s.item_id == item_id do total += s.count
    return
}
