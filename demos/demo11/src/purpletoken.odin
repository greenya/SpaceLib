package main

// docs: https://purpletoken.com/api.php

import "core:encoding/base64"
import "core:encoding/json"
import "core:crypto/hash"
import "core:fmt"
import "core:mem"
import "core:strconv"
import "core:strings"
import "spacelib:userhttp"

// -------------------------- core api --------------------------

PT_API_URL :: "https://purpletoken.com/update/v3"

Pt_Error :: union #shared_nil {
    mem.Allocator_Error,
    userhttp.Error,
    json.Unmarshal_Error,
    Pt_Api_Error,
    Pt_Content_Error,
}

Pt_Api_Error :: enum {
    ERROR_UNKNOWN               = -1,
    ERROR_SUCCESS               = 1,
    ERROR_NAME_LENGTH           = 2,
    ERROR_GAMEKEY_NOT_FOUND     = 3,
    ERROR_LOW_SCORE             = 4,
    ERROR_MISSING_REQ           = 5,
    ERROR_INSUFFICIENT_RIGHTS   = 6,
    ERROR_INTEGRITY_CHECK_FAIL  = 7,
}

Pt_Content_Error :: enum {
    Content_Is_Empty,       // successful response with empty content
    Content_Is_Unsupported, // successful response with non-json and non-parsable error code
}

pt_init :: proc (api_secret, game_key: string, allocator := context.allocator) {
    assert(pt_api_secret=="" && pt_game_key=="" && pt_requests==nil)

    pt_api_secret   = strings.clone(api_secret, allocator)
    pt_game_key     = strings.clone(game_key, allocator)
    pt_requests     = make(map [rawptr] rawptr, allocator)
}

pt_destroy :: proc () {
    delete(pt_api_secret)   ; pt_api_secret = ""
    delete(pt_game_key)     ; pt_game_key = ""
    delete(pt_requests)     ; pt_requests = nil
}

@(private="file") pt_api_secret : string
@(private="file") pt_game_key   : string
@(private="file") pt_requests   : map [rawptr] rawptr

@(private="file")
pt_requests_push :: proc (req: ^userhttp.Request, ready: $T) {
    ensure(req not_in pt_requests)
    pt_requests[req] = rawptr(ready)
}

@(private="file")
pt_requests_pop :: proc (req: ^userhttp.Request, $T: typeid) -> T {
    ensure(req in pt_requests)
    value := cast (T) pt_requests[req]
    delete_key(&pt_requests, req)
    return value
}

@(private="file")
pt_send :: proc (action: string, args: string, ready: userhttp.Ready_Proc) -> (req: ^userhttp.Request, err: mem.Allocator_Error) {
    payload, sig := pt_params(args, context.temp_allocator) or_return
    return userhttp.send_request({
        url         = fmt.tprintf("%s%s", PT_API_URL, action),
        content     = [] userhttp.Param { {"payload",payload}, {"sig",sig} },
        timeout_ms  = 10_000,
        ready       = ready,
    })
}

@(private="file")
pt_params :: proc (args: string, allocator := context.allocator) -> (payload, sig: string, err: mem.Allocator_Error) {
    payload_body := fmt.tprintf("gamekey=%s&%s", pt_game_key, args)
    payload = base64.encode(transmute ([]byte) payload_body, allocator=allocator) or_return

    sig_body := fmt.tprintf("%s%s", payload, pt_api_secret)
    sig_digest := hash.hash_string(.SHA256, sig_body, context.temp_allocator)
    sig_sb := strings.builder_make(allocator=allocator) or_return
    for b in sig_digest do fmt.sbprintf(&sig_sb, "%2x", b)
    sig = strings.to_string(sig_sb)

    return
}

@(private="file")
pt_content_json_unmarshal :: proc (content: [] byte, result: ^$T, allocator := context.allocator) -> (err: Pt_Error) {
    if content == nil do return .Content_Is_Empty

    assert(len(content) > 0)
    if content[0] != '{' {
        return pt_content_parse_error(content)
    }

    json.unmarshal(content, result, allocator=allocator) or_return

    return
}

@(private="file")
pt_content_parse_error :: proc (content: [] byte) -> (err: Pt_Error) {
    code, code_ok := strconv.parse_int(string(content))
    if code_ok {
        return Pt_Api_Error(code)
    } else {
        fmt.println("[content]", content)
        return .Content_Is_Unsupported
    }
}

// -------------------------- get scores --------------------------

Pt_Get_Scores_Result :: struct {
    scores: [] struct {
        player  : string,
        score   : int,
        date    : string,
    },
}

Pt_Get_Scores_Ready_Proc :: proc (result: Pt_Get_Scores_Result, err: Pt_Error)

// IMPORTANT: the `result` is allocated using `context.temp_allocator`.
pt_get_scores :: proc (limit: int, ready: Pt_Get_Scores_Ready_Proc) -> (err: Pt_Error) {
    args := fmt.tprintf("format=json&dates=yes&limit=%i", limit)

    req := pt_send("/get", args, ready=proc (req: ^userhttp.Request) {
        ready := pt_requests_pop(req, Pt_Get_Scores_Ready_Proc)
        result: Pt_Get_Scores_Result

        err: Pt_Error = req.error
        if err == nil {
            err = pt_content_json_unmarshal(req.response.content, &result, context.temp_allocator)
        }

        ready(result=result, err=err)
    }) or_return

    pt_requests_push(req, ready)
    return
}

// -------------------------- submit score --------------------------

Pt_Submit_Score_Ready_Proc :: proc (err: Pt_Error)

pt_submit_score :: proc (player: string, score: int, ready: Pt_Submit_Score_Ready_Proc) -> (err: Pt_Error) {
    args := fmt.tprintf("player=%s&score=%i", player, score)

    req := pt_send("/submit", args, ready=proc (req: ^userhttp.Request) {
        ready := pt_requests_pop(req, Pt_Submit_Score_Ready_Proc)

        err: Pt_Error = req.error
        if err == nil {
            err = pt_content_parse_error(req.response.content)
            if err==.ERROR_SUCCESS || err==.ERROR_LOW_SCORE {
                err = nil
            }
        }

        ready(err=err)
    }) or_return

    pt_requests_push(req, ready)
    return
}
