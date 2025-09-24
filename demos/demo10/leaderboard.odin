package demo10

import "core:encoding/json"
import "core:fmt"
import "core:math/rand"
import "core:slice"
import "core:strings"
import "spacelib:userfs"

Leaderboard :: struct {
    rows: [dynamic] Leaderboard_Row,
}

Leaderboard_Row :: struct {
    name    : string,
    score   : int,
}

leaderboard_file_name :: "leaderboard.json"

leaderboard: Leaderboard

leaderboard_load :: proc () {
    bytes := userfs.read(leaderboard_file_name, context.temp_allocator)
    if bytes != nil {
        err := json.unmarshal(bytes, &leaderboard)
        fmt.ensuref(err == nil, "Failed to json.unmarshal(): %v", err)
    }
}

leaderboard_save :: proc () {
    bytes, err := json.marshal(leaderboard, allocator=context.temp_allocator)
    fmt.ensuref(err == nil, "Failed to json.marshal(): %v", err)
    userfs.write(leaderboard_file_name, bytes)
}

leaderboard_destroy :: proc () {
    leaderboard_clear_rows(save=false)
    delete(leaderboard.rows)
}

leaderboard_clear_rows :: proc (save := true) {
    for row in leaderboard.rows do delete(row.name)
    clear(&leaderboard.rows)
    if save do leaderboard_save()
}

leaderboard_gen_new_rows :: proc (count: int, save := true) {
    for _ in 0..<count do append(&leaderboard.rows, Leaderboard_Row {
        name    = leaderboard_gen_random_name(),
        score   = rand.int_max(1_000_000),
    })
    slice.sort_by(leaderboard.rows[:], less=proc (a, b: Leaderboard_Row) -> bool {
        return a.score > b.score
    })
    if save do leaderboard_save()
}

leaderboard_gen_random_name :: proc (allocator := context.allocator) -> string {
    return strings.clone(rand.choice([] string {
        "Alice", "Amelia", "Asher", "Ava", "Axel", "Barbara", "Bill", "Bob", "Britney",
        "Caleb", "Charles", "Charlotte", "Clara", "Daniel", "Daisy", "Denis", "Dylan",
        "Eden", "Eli", "Elijah", "Emma", "Ester", "Evelyn", "Frank", "George", "Henry",
        "Iris", "Isaac", "Isabella", "Ivy", "Jack", "Jade", "Jay", "Joe", "John", "Joseph",
        "Kate", "Kay", "Leo", "Liam", "Lily", "Logan", "Lucia", "Luke", "Luna", "Maria",
        "Mary", "Max", "Mia", "Michael", "Naomi", "Nick", "Noah", "Nolan", "Nova", "Oliver",
        "Olivia", "Owen", "Paris", "Patrick", "Rick", "Robert", "Roy", "Ruby", "Sally",
        "Sarah", "Scarlett", "Simon", "Sophia", "Theodore", "Tim", "Todd", "Victoria",
        "Violet", "William", "Zoe",
    }))
}
