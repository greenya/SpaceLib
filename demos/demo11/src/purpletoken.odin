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

// ------------------------- config -------------------------

PT_API_URL      :: "https://purpletoken.com/update/v3"
PT_API_SECRET   :: "A secret pass phrase goes here"
PT_GAME_KEY     :: "65ca329ff0f6dc94e3391cab956c02607d5b2271"

// ------------------------- core -------------------------

Pt_Error :: union {
    mem.Allocator_Error,
    userhttp.Error,
    json.Unmarshal_Error,
    Pt_Api_Error,
    Pt_Parse_Error,
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

Pt_Parse_Error :: enum {
    Content_Is_Empty,       // successful response with empty content
    Content_Is_Unsupported, // successful response with non-json and non-parsable error code
}

pt_params :: proc (args: string, allocator := context.allocator) -> (payload, sig: string, err: mem.Allocator_Error) {
    context.allocator = context.temp_allocator

    params := fmt.tprintf("gamekey=%s&%s", PT_GAME_KEY, args)
    payload = base64.encode(transmute ([]byte) params, allocator=allocator) or_return

    sig_digest := hash.hash_string(.SHA256, fmt.tprintf("%s%s", payload, PT_API_SECRET))
    sig_sb := strings.builder_make(allocator=allocator) or_return
    for b in sig_digest do fmt.sbprintf(&sig_sb, "%2x", b)
    sig = strings.to_string(sig_sb)

    return
}

pt_parse_content :: proc (content: [] byte, ptr: ^$T, allocator := context.allocator) -> (err: Pt_Error) {
    if content == nil do return .Content_Is_Empty

    assert(len(content) > 0)
    if content[0] != '{' {
        // not a JSON, must be an error code (an integer)
        code, code_ok := strconv.parse_int(string(content))
        if code_ok {
            return Pt_Api_Error(code)
        } else {
            fmt.println("[content]", content)
            return .Content_Is_Unsupported
        }
    }

    json.unmarshal(content, ptr, allocator=allocator) or_return

    return
}

// ------------------------- get scores -------------------------

Pt_Get_Scores_Result :: struct {
    scores: [] struct {
        player  : string,
        score   : int,
        date    : string,
    },
}

// `limit`: Number of scores to return.
pt_get_scores :: proc (limit: int, allocator := context.allocator) -> (result: Pt_Get_Scores_Result, err: Pt_Error) {
    context.allocator = context.temp_allocator

    params := fmt.tprintf("format=json&dates=yes&limit=%i", limit)
    payload, sig := pt_params(params) or_return

    req := userhttp.make({
        url     = PT_API_URL + "/get",
        content = [] userhttp.Param { {"payload",payload}, {"sig",sig} },
        timeout = 10 * time.Second,
    }) or_return

    content := userhttp.send(&req) or_return
    pt_parse_content(content, &result, allocator=allocator) or_return

    return
}

// ------------------------- submit score -------------------------

// TODO: impl
