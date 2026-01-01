package purpletoken

// docs: https://purpletoken.com/api.php

import "core:encoding/base64"
import "core:encoding/json"
import "core:crypto/hash"
import "core:fmt"
import "core:mem"
import "core:strconv"
import "core:strings"
import "core:time"
import "spacelib:userhttp"

// -------------------------- core --------------------------

API_URL :: "https://purpletoken.com/update/v3"

Error :: union #shared_nil {
    mem.Allocator_Error,
    userhttp.Error,
    json.Unmarshal_Error,
    Api_Error,
    Content_Error,
}

Api_Error :: enum {
    ERROR_UNKNOWN               = -1,
    ERROR_SUCCESS               = 1,
    ERROR_NAME_LENGTH           = 2,
    ERROR_GAMEKEY_NOT_FOUND     = 3,
    ERROR_LOW_SCORE             = 4,
    ERROR_MISSING_REQ           = 5,
    ERROR_INSUFFICIENT_RIGHTS   = 6,
    ERROR_INTEGRITY_CHECK_FAIL  = 7,
}

Content_Error :: enum {
    Content_Is_Empty,       // successful response with empty content
    Content_Is_Unsupported, // successful response with non-json and non-parsable error code
}

Init :: struct {
    // The `API Secret Pass Phrase` from [Profile Settings](https://purpletoken.com/profile.php)
    api_secret: string,

    // The `Game Key` from [My Games](https://purpletoken.com/manage.php)
    game_key: string,

    // Optional global `Request.ready` notify callback
    request_ready_proc: userhttp.Ready_Proc,
}

init :: proc (init: Init, allocator := context.allocator) {
    ensure(init.api_secret != "" && init.game_key != "",
        "Failed to init PurpleToken: `init.api_secret` and `init.game_key` cannot be empty.\n" +
        "- The `API Secret Pass Phrase` from https://purpletoken.com/profile.php\n" +
        "- The `Game Key` from https://purpletoken.com/manage.php\n",
    )

    assert(api_secret=="" && game_key=="" && request_ready_proc==nil && requests==nil)

    api_secret          = strings.clone(init.api_secret, allocator)
    game_key            = strings.clone(init.game_key, allocator)
    request_ready_proc  = init.request_ready_proc
    requests            = make(map [rawptr] rawptr, allocator)
}

destroy :: proc () {
    delete(api_secret)
    delete(game_key)
    delete(requests)

    api_secret          = ""
    game_key            = ""
    request_ready_proc  = nil
    requests            = nil
}

@(private) api_secret           : string
@(private) game_key             : string
@(private) request_ready_proc   : userhttp.Ready_Proc
@(private) requests             : map [rawptr] rawptr

@(private)
requests_push :: proc (req: ^userhttp.Request, ready: $T) {
    ensure(req not_in requests)
    requests[req] = rawptr(ready)
}

@(private)
requests_pop :: proc (req: ^userhttp.Request, $T: typeid) -> T {
    ensure(req in requests)
    value := cast (T) requests[req]
    delete_key(&requests, req)
    if request_ready_proc != nil do request_ready_proc(req)
    return value
}

@(private)
send :: proc (action: string, args: string, ready: userhttp.Ready_Proc) -> (req: ^userhttp.Request, err: mem.Allocator_Error) {
    payload, sig := params(args, context.temp_allocator) or_return
    return userhttp.send_request({
        url         = fmt.tprintf("%s%s", API_URL, action),
        content     = [] userhttp.Param { {"payload",payload}, {"sig",sig} },
        timeout_ms  = 10_000,
        ready       = ready,
    })
}

@(private)
params :: proc (args: string, allocator := context.allocator) -> (payload, sig: string, err: mem.Allocator_Error) {
    payload_body := fmt.tprintf("gamekey=%s&%s", game_key, args)
    payload = base64.encode(transmute ([]byte) payload_body, allocator=allocator) or_return

    sig_body := fmt.tprintf("%s%s", payload, api_secret)
    sig_digest := hash.hash_string(.SHA256, sig_body, context.temp_allocator)
    sig_sb := strings.builder_make(allocator=allocator) or_return
    for b in sig_digest do fmt.sbprintf(&sig_sb, "%2x", b)
    sig = strings.to_string(sig_sb)

    return
}

@(private)
content_json_unmarshal :: proc (content: [] byte, result: ^$T, allocator := context.allocator) -> (err: Error) {
    if content == nil do return .Content_Is_Empty

    assert(len(content) > 0)
    if content[0] != '{' {
        return content_parse_error(content)
    }

    json.unmarshal(content, result, allocator=allocator) or_return

    return
}

@(private)
content_parse_error :: proc (content: [] byte) -> (err: Error) {
    code, code_ok := strconv.parse_int(string(content))
    if code_ok {
        return Api_Error(code)
    } else {
        fmt.println("[content]", content)
        return .Content_Is_Unsupported
    }
}

// -------------------------- get scores --------------------------

Get_Scores_Result :: struct {
    scores: [] struct {
        player          : string,
        score           : int,
        date            : string,

        // This date is parsed `date` and converted to `time.Time`.
        //
        // Note: the raw `date` is not valid ISO 8601 date, it looks like this:
        // `2025-12-29 19:14:17`, while valid would be `2025-12-29T19:14:17Z`;
        // we parse it, and set `date_as_time` to the returned value of
        // `time.iso8601_to_time_utc()`.
        date_as_time: time.Time,
    },
}

Get_Scores_Ready_Proc :: proc (result: Get_Scores_Result, err: Error)

// IMPORTANT: the `result` is allocated using `context.temp_allocator`.
get_scores :: proc (limit: int, ready: Get_Scores_Ready_Proc) -> (err: Error) {
    args := fmt.tprintf("format=json&dates=yes&limit=%i", limit)

    req := send("/get", args, ready=proc (req: ^userhttp.Request) {
        ready := requests_pop(req, Get_Scores_Ready_Proc)
        result: Get_Scores_Result

        err: Error = req.error
        if err == nil {
            err = content_json_unmarshal(req.response.content, &result, context.temp_allocator)
        }

        if err == nil do for &row in result.scores {
            // check if `date` has expected length, and set `date_as_time`:
            // "2025-12-29 19:14:17" => "2025-12-29T19:14:17Z" => time.Time
            // [0123456789012345678]

            if len(row.date) != 19 do continue
            date_iso8601 := fmt.tprintf("%sT%sZ", row.date[:10], row.date[11:])
            row.date_as_time, _ = time.iso8601_to_time_utc(date_iso8601)
        }

        if ready != nil do ready(result=result, err=err)
    }) or_return

    requests_push(req, ready)
    return
}

// -------------------------- submit score --------------------------

Submit_Score_Ready_Proc :: proc (err: Error)

submit_score :: proc (player: string, score: int, ready: Submit_Score_Ready_Proc = nil) -> (err: Error) {
    args := fmt.tprintf("player=%s&score=%i", player, score)

    req := send("/submit", args, ready=proc (req: ^userhttp.Request) {
        ready := requests_pop(req, Submit_Score_Ready_Proc)

        err: Error = req.error
        if err == nil {
            err = content_parse_error(req.response.content)
            if err==.ERROR_SUCCESS || err==.ERROR_LOW_SCORE {
                err = nil
            }
        }

        if ready != nil do ready(err=err)
    }) or_return

    requests_push(req, ready)
    return
}
