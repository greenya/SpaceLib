package main

import "core:encoding/json"
import "core:fmt"
import "core:time"
import "spacelib:terse"
import "spacelib:ui"
import "spacelib:userhttp"

GitHub_Page :: struct {
    ui_reload       : ^ui.Frame,
    ui_reload_state : ^ui.Frame,
    ui_commits      : ^ui.Frame,
}

github_page: GitHub_Page

github_page_add :: proc () {
    _, page_content := app_add_tab("GitHub")

    ui.add_frame(page_content, {
        flags   = {.terse,.terse_height},
        text    = "<wrap,top,left,font=text_4r,color=white>" +
                "This example shows usage of GitHub Rest API. When Reload is clicked, latest " +
                "30 commits are loaded from Odin repository." +
                "\n\n" +
                "Please note, this example uses unauthenticated (public) access and the primary " +
                "rate limit for unauthenticated requests is 60 requests per hour. So if you're " +
                "getting errors, please try again later." +
                "\n\n" +
                "More at <group=link_github_limits>Rate limits for the REST API</group>.",
    })

    github_page.ui_reload_state = ui.add_frame(page_content, {
        flags       = {.terse,.terse_height},
        text_format = "<pad=0:20,wrap,top,left,font=text_4r,color=peach><tab=220>%s",
    })

    ui.set_text(github_page.ui_reload_state, "Press the button")

    github_page.ui_reload = ui.add_frame(github_page.ui_reload_state, {
        flags   = {.terse,.terse_height,.capture},
        size    = {200,0},
        text    = "<pad=10,font=text_4r>Reload commits",
        draw    = draw_button,
        click   = github_page_reload_click,
    },
        { point=.right, rel_point=.left, offset={200,0} },
    )

    github_page.ui_commits = ui.add_frame(page_content, {
        layout = ui.Flow { dir=.down, gap=20, align=.start, auto_size={.height} },
    })
}

github_page_reload_click :: proc (f: ^ui.Frame) {
    assert(f == github_page.ui_reload)

    github_page.ui_reload.flags += { .disabled }
    ui.set_text(github_page.ui_reload_state, "Wait...")

    Result      :: [] Result_Row
    Result_Row  :: struct {
        sha     : string,
        commit  : struct { author: struct { date: string }, message: string },
        author  : struct { login: string },
    }

    userhttp.send_request({
        url         = "https://api.github.com/repos/odin-lang/Odin/commits",
        headers     = { {"user-agent","userhttp"} }, // GitHub API requires User-Agent header set
        timeout_ms  = 10_000,
        ready       = proc (req: ^userhttp.Request) {
            userhttp.print_request(req)
            github_page.ui_reload.flags -= { .disabled }

            ui.set_text(github_page.ui_reload_state, userhttp.request_state_text(req, context.temp_allocator))
            if req.error != nil do return

            result: Result
            json_err := json.unmarshal(req.response.content, &result, allocator=context.temp_allocator)
            if json_err != nil {
                fmt.println(json_err)
                return
            }

            ui.destroy_frame_children(github_page.ui_commits)
            for row, _ in result {
                // fmt.println(i, row)
                github_page_add_commit_card(row.sha, row.author.login, row.commit.message, row.commit.author.date)
            }
        },
    })
}

github_page_add_commit_card :: proc (sha, user, message, time_utc: string) {
    card := ui.add_frame(github_page.ui_commits, {
        layout = ui.Flow { dir=.down, auto_size={.height} },
    })

    time_val, _ := time.iso8601_to_time_utc(time_utc)
    time_dur    := time.duration_truncate(time.since(time_val), time.Second)

    ui.add_frame(card, {
        flags   = {.terse,.terse_height},
        text    = fmt.tprintf("<wrap,top,left,font=text_4r>" +
                "<color=amber,group=link_github_user_%s>%s</group,/color> " +
                "<color=turquoise>committed %v ago " +
                "<group=link_github_commit_%s>#%s</group>", user, user, time_dur, sha, sha[:7]),
    })

    message_escaped := terse.text_escaped(message, context.temp_allocator)
    ui.add_frame(card, {
        flags   = {.terse,.terse_height},
        text    = fmt.tprintf("<wrap,top,left,font=text_4r,color=white>%s", message_escaped),
    })
}
