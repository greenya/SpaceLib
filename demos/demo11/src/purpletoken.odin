package main

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

PT_API_URL      :: "https://purpletoken.com/update/v3"
PT_API_SECRET   :: "A secret pass phrase goes here"
PT_GAME_KEY     :: "65ca329ff0f6dc94e3391cab956c02607d5b2271"

Pt_Error :: union {
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

Pt_Get_Scores_Result :: struct {
    scores: [] struct {
        player  : string,
        score   : int,
        date    : string,
    },
}

pt_send :: proc (action: string, args: string, allocator := context.allocator) -> (content: [] byte, err: Pt_Error) {
    // payload, sig := pt_params(args, context.temp_allocator) or_return

    // req := userhttp.make({
    //     url     = fmt.tprintf("%s%s", PT_API_URL, action),
    //     content = [] userhttp.Param { {"payload",payload}, {"sig",sig} },
    //     timeout = 30 * time.Second,
    // }, allocator) or_return

    // content = userhttp.send(&req) or_return

    return
}

pt_params :: proc (args: string, allocator := context.allocator) -> (payload, sig: string, err: mem.Allocator_Error) {
    payload_body := fmt.tprintf("gamekey=%s&%s", PT_GAME_KEY, args)
    payload = base64.encode(transmute ([]byte) payload_body, allocator=allocator) or_return

    sig_body := fmt.tprintf("%s%s", payload, PT_API_SECRET)
    sig_digest := hash.hash_string(.SHA256, sig_body, context.temp_allocator)
    sig_sb := strings.builder_make(allocator=allocator) or_return
    for b in sig_digest do fmt.sbprintf(&sig_sb, "%2x", b)
    sig = strings.to_string(sig_sb)

    return
}

pt_content_json_unmarshal :: proc (content: [] byte, result: ^$T, allocator := context.allocator) -> (err: Pt_Error) {
    if content == nil do return .Content_Is_Empty

    assert(len(content) > 0)
    if content[0] != '{' {
        return pt_content_parse_error(content)
    }

    json.unmarshal(content, result, allocator=allocator) or_return

    return
}

pt_content_parse_error :: proc (content: [] byte) -> (err: Pt_Error) {
    code, code_ok := strconv.parse_int(string(content))
    if code_ok {
        return Pt_Api_Error(code)
    } else {
        fmt.println("[content]", content)
        return .Content_Is_Unsupported
    }
}

pt_get_scores :: proc (limit: int, allocator := context.allocator) -> (result: Pt_Get_Scores_Result, err: Pt_Error) {
    args := fmt.tprintf("format=json&dates=yes&limit=%i", limit)
    content := pt_send("/get", args, context.temp_allocator) or_return
    pt_content_json_unmarshal(content, &result, allocator) or_return
    return
}

pt_submit_score :: proc (player: string, score: int) -> (err: Pt_Error) {
    args := fmt.tprintf("player=%s&score=%i", player, score)
    content := pt_send("/submit", args, context.temp_allocator) or_return
    err = pt_content_parse_error(content)
    if err==.ERROR_SUCCESS || err==.ERROR_LOW_SCORE do err = nil
    return
}
