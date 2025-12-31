package main

import "core:encoding/json"
import "core:fmt"
import "core:strings"
import "core:time"
import rl "vendor:raylib"
import "spacelib:terse"
import "spacelib:ui"
import "spacelib:userhttp"

GitHub_Page :: struct {
    ui_reload       : ^ui.Frame,
    ui_reload_state : ^ui.Frame,
    ui_commits      : ^ui.Frame,

    user_avatars: map [string] struct {
        req     : ^userhttp.Request,
        texture : rl.Texture,
    },
}

github_page: GitHub_Page

add_github_page :: proc () {
    _, page_content := app_add_tab("GitHub")

    ui.add_frame(page_content, {
        flags   = {.terse,.terse_height},
        text    = "<wrap,top,left,font=text_4r,color=white>" +
                "This example shows usage of GitHub Rest API. When Reload is clicked, latest " +
                "30 commits are loaded from Odin repository in a single request. Then we load " +
                "avatar of each user simultaneously. Loaded avatars are not reloaded onces loaded." +
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
        layout = ui.Flow { dir=.down, gap=30, align=.start, auto_size={.height} },
    })
}

destroy_github_page :: proc () {
    for user, avatar in github_page.user_avatars {
        delete(user)
        if avatar.texture.id != 0 {
            rl.UnloadTexture(avatar.texture)
        }
    }
    delete(github_page.user_avatars)
}

github_page_reload_click :: proc (f: ^ui.Frame) {
    assert(f == github_page.ui_reload)

    github_page.ui_reload.flags += { .disabled }
    ui.set_text(github_page.ui_reload_state, "Wait...")

    Result      :: [] Result_Row
    Result_Row  :: struct {
        sha     : string,
        commit  : struct { author: struct { date: string }, message: string },
        author  : struct { login: string, avatar_url: string },
    }

    userhttp.send_request({
        url         = "https://api.github.com/repos/odin-lang/Odin/commits",
        headers     = { {"user-agent","userhttp"} }, // GitHub API requires User-Agent header set
        timeout_ms  = 10_000,
        ready       = proc (req: ^userhttp.Request) {
            log_request(req)
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
                sha    , user            , avatar_url           , message           , date :=
                row.sha, row.author.login, row.author.avatar_url, row.commit.message, row.commit.author.date

                github_page_add_commit_card(sha=sha, user=user, message=message, date=date)
                github_page_load_user_avatar(user=user, avatar_url=avatar_url)
            }
        },
    })
}

github_page_add_commit_card :: proc (sha, user, message, date: string) {
    avatar_size :: 80

    card := ui.add_frame(github_page.ui_commits, {
        size_min    = {0,avatar_size},
        layout      = ui.Flow { dir=.down, pad={avatar_size+20,0,0,0}, gap=10, auto_size={.height} },
    })

    time_val, _     := time.iso8601_to_time_utc(date)
    time_dur        := time.duration_truncate(time.since(time_val), time.Second)
    message_escaped := terse.text_escaped(message, context.temp_allocator)

    ui.add_frame(card, {
        flags   = {.terse,.terse_height},
        text    = fmt.tprintf("<wrap,top,left,font=text_4r>" +
                "<color=amber,group=link_github_user_%s>%s</group,/color> " +
                "<color=turquoise>committed %v ago " +
                "<group=link_github_commit_%s>#%s</group>\n" +
                "<gap=.5,color=white>%s",
                user, user, time_dur, sha, sha[:7], message_escaped),
    })

    ui.add_frame(card, {
        name    = user,
        size    = avatar_size,
        draw    = draw_github_user_avatar,
        click   = proc (f: ^ui.Frame) {
            link := fmt.tprintf("link_github_user_%s", f.name)
            open_url(link)
        },
    },
        { point=.top_left },
    )
}

github_page_load_user_avatar :: proc (user, avatar_url: string) {
    if user in github_page.user_avatars do return

    req := userhttp.send_request({
        url         = avatar_url,
        timeout_ms  = 10_000,
        ready       = proc (req: ^userhttp.Request) {
            log_request(req)
            if req.error != nil do return

            format: struct {
                file_type   : cstring,
                use_filter  : bool,
            }

            content_type := userhttp.param_as_string(req.response.headers, "content-type", context.temp_allocator)
            content_type_lower := strings.to_lower(content_type, context.temp_allocator)
            switch content_type_lower {
            case "image/png"    : format = { file_type=".png" }
            case "image/jpeg"   : format = { file_type=".jpeg", use_filter=true }
            case                : logf("Unexpected content type: %s", content_type); return
            }

            image := rl.LoadImageFromMemory(format.file_type, raw_data(req.response.content), i32(len(req.response.content)))
            texture := rl.LoadTextureFromImage(image)
            rl.UnloadImage(image)

            if format.use_filter {
                rl.GenTextureMipmaps(&texture)
                rl.SetTextureFilter(texture, .BILINEAR)
            }

            for _, &avatar in github_page.user_avatars {
                if avatar.req == req {
                    assert(avatar.texture == {})
                    avatar = { texture=texture }
                    break
                }
            }
        },
    })

    user_cloned := strings.clone(user)
    github_page.user_avatars[user_cloned] = { req=req }
}
