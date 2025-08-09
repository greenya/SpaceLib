package data

import "core:encoding/json"
import "core:fmt"

Tutorial_Tip :: struct {
    id      : string,
    title   : string,
    image   : string,
    desc    : Text,
}

/* @private */ tutorial_tips: [] Tutorial_Tip

@private
create_tutorial_tips :: proc () {
    assert(tutorial_tips == nil)
    err := json.unmarshal_any(#load("tutorial_tips.json"), &tutorial_tips)
    fmt.ensuref(err == nil, "Failed to load tutorial_tips.json: %v", err)
    // fmt.printfln("%#v", tutorial_tips)
}

@private
destroy_tutorial_tips :: proc () {
    for t in tutorial_tips {
        delete(t.id)
        delete(t.title)
        delete(t.image)
        delete_text(t.desc)
    }
    delete(tutorial_tips)
    tutorial_tips = nil
}

get_tutorial_tip :: proc (id: string) -> Tutorial_Tip {
    for t in tutorial_tips do if t.id == id do return t
    fmt.panicf("Tutorial tip \"%s\" was not found", id)
}
