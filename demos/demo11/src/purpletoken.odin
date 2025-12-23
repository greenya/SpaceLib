package main

// PurpleToken API: https://purpletoken.com/api.php

import "core:encoding/base64"
import "core:encoding/json"
import "core:crypto/hash"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:time"
import "spacelib:userhttp"

PT_API_URL      :: "https://purpletoken.com/update/v3"
PT_API_SECRET   :: "A secret pass phrase goes here"
PT_GAME_KEY     :: "65ca329ff0f6dc94e3391cab956c02607d5b2271"

PT_Error :: enum {
    ERROR_UNKNOWN               = -1,
    ERROR_SUCCESS               = 1,
    ERROR_NAME_LENGTH           = 2,
    ERROR_GAMEKEY_NOT_FOUND     = 3,
    ERROR_LOW_SCORE             = 4,
    ERROR_MISSING_REQ           = 5,
    ERROR_INSUFFICIENT_RIGHTS   = 6,
    ERROR_INTEGRITY_CHECK_FAIL  = 7,
}

@rodata
PT_Error_Hint := #sparse [PT_Error] string {
    .ERROR_UNKNOWN              = "???",
    .ERROR_SUCCESS              = "Score was added successfully",
    .ERROR_NAME_LENGTH          = "Name length exceeded 32 characters",
    .ERROR_GAMEKEY_NOT_FOUND    = "Invalid gamekey was given",
    .ERROR_LOW_SCORE            = "Score too low for top 20",
    .ERROR_MISSING_REQ          = "Missing requirement",
    .ERROR_INSUFFICIENT_RIGHTS  = "Trying to delete a score when key hasn't been granted delete permission",
    .ERROR_INTEGRITY_CHECK_FAIL = "Signature did not much up with payload",
}

pt_params :: proc (args: string, allocator := context.allocator) -> (payload, sig: string) {
    context.allocator = context.temp_allocator

    params := fmt.tprintf("gamekey=%s&%s", PT_GAME_KEY, args)
    payload = base64.encode(transmute ([]byte) params, allocator=allocator)

    sig_digest := hash.hash_string(.SHA256, fmt.tprintf("%s%s", payload, PT_API_SECRET))
    sig_sb := strings.builder_make(allocator=allocator)
    for b in sig_digest do fmt.sbprintf(&sig_sb, "%2x", b)
    sig = strings.to_string(sig_sb)

    return
}

pt_print_error :: proc (content: string) {
    err, ok := strconv.parse_int(string(content))
    pt_err := PT_Error(err)
    pt_err_hint := PT_Error_Hint[pt_err]
    if ok   do fmt.println("PT API Error:", pt_err, pt_err_hint)
    else    do fmt.println("PT API Error (raw):", string(content))
}

// ------------------------- GET SCORES -------------------------

Pt_Get_Scores_Result :: struct {
    scores: [] struct {
        player  : string,
        score   : int,
        date    : string,
    },
}

pt_get_scores :: proc (allocator := context.allocator) -> (result: Pt_Get_Scores_Result, ok: bool) {
    fmt.println(#procedure)
    context.allocator = context.temp_allocator

    payload, sig := pt_params("format=json&dates=yes&limit=20")

    req := userhttp.make({
        url     = PT_API_URL + "/get",
        content = [] userhttp.Param { {"payload",payload}, {"sig",sig} },
        timeout = 10 * time.Second,
    })

    defer userhttp.delete(req)

    content := userhttp.send(&req)

    if content != nil {
        if len(content) > 0 {
            if content[0] == '{' {
                err := json.unmarshal(content, &result, allocator=allocator)
                if err == nil {
                    ok = true
                } else {
                    fmt.println("Failed to json.unmarshal():", err)
                }
            } else {
                pt_print_error(string(content))
            }
        } else {
            fmt.println("Failed to receive content")
        }
    } else {
        fmt.println("Failed to userhttp.send():", req.error, req.error_msg)
        if req.response.status != .None {
            fmt.println("HTTP Response Status:", req.response.status)
        }
    }

    return
}

// ------------------------- SUBMIT SCORE -------------------------

// TODO: impl
