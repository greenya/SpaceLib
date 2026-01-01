package main

import "core:fmt"
import "core:math/rand"
import "core:strings"
import "core:time"
import "spacelib:core"
import "spacelib:ui"
import pt "purpletoken"

PurpleToken_Page :: struct {
    ui_get_scores   : ^ui.Frame,
    ui_submit_score : ^ui.Frame,
    ui_scores       : ^ui.Frame,

    rolled_name     : string,
    rolled_score    : int,
}

purpletoken_page: PurpleToken_Page

add_purpletoken_page :: proc () {
    _, page_content := app_add_tab("PurpleToken")

    ui.add_frame(page_content, {
        flags   = {.terse,.terse_height},
        text    = "<wrap,top,left,font=text_4r,color=white>" +
                "This example demonstrates usage of the <group=link_pt>PurpleToken</group> " +
                "REST API. Clicking Get Scores reloads the list of the top 20 highest scores. " +
                "You can also submit a result yourself: generate username and a score, then click " +
                "Submit Score. If the submitted score is high enough to enter the top 20, it will " +
                "appear the next time you click Get Scores." +
                "\n\n" +
                "Scores are stored on the PurpleToken server, so reloading the app or using " +
                "a different tab, browser, or device will display the same leaderboard.",
    })

    grid := ui.add_frame(page_content, {
        layout  = ui.Grid { dir=.right_down, size={200,80}, gap=16, auto_size={.height} },
    })

    purpletoken_page.ui_get_scores = ui.add_frame(grid, {
        flags   = {.terse,.capture},
        text    = "<pad=10,font=text_4r,color=white>Get Scores",
        draw    = draw_button,
        click   = purpletoken_page_get_scores_click,
    })

    purpletoken_page.ui_submit_score = ui.add_frame(grid, {
        flags   = {.terse,.capture},
        text    = "<pad=10,font=text_4r,color=white>Submit Score",
        draw    = draw_button,
        click   = purpletoken_page_submit_score_click,
    })

    player_name_btn := ui.add_frame(grid, {
        flags       = {.terse,.capture},
        text_format = "<pad=10,font=text_4r,color=white>Player\n<color=amber>%s</>",
        draw        = draw_button,
        click       = proc (f: ^ui.Frame) {
            purpletoken_page.rolled_name = purpletoken_page_gen_random_player_name()
            ui.set_text(f, purpletoken_page.rolled_name)
        },
    })

    player_score_btn := ui.add_frame(grid, {
        flags       = {.terse,.capture},
        text_format = "<pad=10,font=text_4r,color=white>Score\n<color=amber>%s</>",
        draw        = draw_button,
        click       = proc (f: ^ui.Frame) {
            purpletoken_page.rolled_score = rand.int_max(1_000_000)
            score_text := core.format_int_tmp(purpletoken_page.rolled_score)
            ui.set_text(f, score_text)
        },
    })

    purpletoken_page.ui_scores = ui.add_frame(page_content, {
        flags       = {.terse,.terse_height},
        text_format = "<wrap,top,left,font=text_4r,color=white>%s",
        text        = "Press <color=amber>Get Scores</> button",
    })

    ui.click(player_name_btn)
    ui.click(player_score_btn)
}

purpletoken_page_get_scores_click :: proc (f: ^ui.Frame) {
    assert(f == purpletoken_page.ui_get_scores)

    purpletoken_page.ui_get_scores.flags += { .disabled }

    pt.get_scores(limit=20, ready=proc (result: pt.Get_Scores_Result, err: pt.Error) {
        purpletoken_page.ui_get_scores.flags -= { .disabled }

        sb := strings.builder_make(context.temp_allocator)

        if err != nil {
            logf("Getting scores failed: (%i) %v", err, err)
            fmt.sbprintf(&sb, "<color=peach>[ERROR] (%i) %v", err, err)
        } else {
            for row, i in result.scores {
                if strings.builder_len(sb) > 0 do strings.write_string(&sb, "\n")

                pos         := i+1
                score_text  := core.format_int_tmp(row.score)
                time_ago    := time.duration_truncate(time.since(row.date_as_time), time.Second)

                color: string
                switch pos {
                case 1  : color = "rose"
                case 2  : color = "peach"
                case 3  : color = "amber"
                case    : color = "white"
                }

                fmt.sbprintf(&sb,
                    "<color=%s>%i.<tab=60>%s<tab=200>%s<tab=350>%v ago</>",
                    color, pos, score_text, row.player, time_ago,
                )
            }
        }

        ui.set_text(purpletoken_page.ui_scores, strings.to_string(sb))
    })
}

purpletoken_page_submit_score_click :: proc (f: ^ui.Frame) {
    assert(f == purpletoken_page.ui_submit_score)

    purpletoken_page.ui_submit_score.flags += { .disabled }

    pt.submit_score(purpletoken_page.rolled_name, purpletoken_page.rolled_score, ready=proc (err: pt.Error) {
        purpletoken_page.ui_submit_score.flags -= { .disabled }

        if err != nil   do logf("Score submission failed: (%i) %v", err, err)
        else            do log("Score submitted successfully")
    })
}

purpletoken_page_gen_random_player_name :: proc () -> string {
    return rand.choice([] string {
        "Alice", "Amelia", "Asher", "Ava", "Axel", "Barbara", "Bill", "Bob", "Britney",
        "Caleb", "Charles", "Charlotte", "Clara", "Daniel", "Daisy", "Denis", "Dylan",
        "Eden", "Eli", "Elijah", "Emma", "Ester", "Evelyn", "Frank", "George", "Henry",
        "Iris", "Isaac", "Isabella", "Ivy", "Jack", "Jade", "Jay", "Joe", "John", "Joseph",
        "Kate", "Kay", "Leo", "Liam", "Lily", "Logan", "Lucia", "Luke", "Luna", "Maria",
        "Mary", "Max", "Mia", "Michael", "Naomi", "Nick", "Noah", "Nolan", "Nova", "Oliver",
        "Olivia", "Owen", "Paris", "Patrick", "Rick", "Robert", "Roy", "Ruby", "Sally",
        "Sarah", "Scarlett", "Simon", "Sophia", "Theodore", "Tim", "Todd", "Victoria",
        "Violet", "William", "Zoe",
    })
}
