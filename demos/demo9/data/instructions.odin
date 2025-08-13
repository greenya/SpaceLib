package data

import "core:encoding/json"
import "core:fmt"

Instruction :: struct {
    id      : string,
    pages   : [] Instruction_Page,
}

Instruction_Page :: struct {
    title   : string,
    text    : Text,
}

@private instructions: [] Instruction

@private
create_instructions :: proc () {
    assert(instructions == nil)

    err := json.unmarshal_any(#load("instructions.json"), &instructions)
    fmt.ensuref(err == nil, "Failed to load instructions.json: %v", err)
    // fmt.printfln("%#v", instructions)
}

@private
destroy_instructions :: proc () {
    for i in instructions {
        delete(i.id)
        for p in i.pages {
            delete(p.title)
            delete_text(p.text)
        }
        delete(i.pages)
    }
    delete(instructions)
    instructions = nil
}

get_instruction :: proc (id: string) -> Instruction {
    for i in instructions do if i.id == id do return i
    fmt.panicf("Instruction \"%s\" was not found", id)
}

get_instruction_page :: proc (id: string, page_idx: int, allocator := context.allocator) -> (title, text: string) #bounds_check {
    i := get_instruction(id)
    title = i.pages[page_idx].title
    text = text_to_string(i.pages[page_idx].text, allocator)
    return
}
