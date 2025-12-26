"use strict";

(function() {

function log(...args) { console.log("[userhttp]", ...args) }
function err(...args) { console.error("[userhttp]", ...args) }

const fetch         = window.fetch
const JSON          = window.JSON
const Uint8Array    = window.Uint8Array

if (!fetch || !Uint8Array) {
    err("Fetch API, JSON API and Uint8Array must be supported")
    return
}

if (window.userhttp !== undefined) {
    err("window.userhttp must be undefined; currently script executes multiple times or \"userhttp\" is defined by other script")
    return
}

const userhttp = {
    memory  : null,
    imports : {
        userhttp_send,
    },
}

async function userhttp_send(req_ptr, req_len, res_ptr, res_len) {
    log("send", arguments)

    const req_json = userhttp.memory.loadString(req_ptr, req_len)
    const req = JSON.parse(req_json)
    log("req", req)

    const req_url = make_url(req.url, req.query_params)
    log("req_url", req_url)

    const req_headers = make_headers(req.header_params)
    log("req_headers", req_headers)

    const req_body = make_body(req.content_params, req.content_base64)
    log("req_body", req_body)

    const res = {}
    try {
        const response = await fetch(req_url, {
            method  : req.method,
            headers : req_headers,
            body    : req_body,
        })

        res.status = response.status

        res.header_params = []
        for (const [ name, value ] of response.headers.entries()) {
            res.header_params.push([ name, value ])
        }

        const res_content_bytes = await response.bytes()
        const res_content_string = String.fromCodePoint(...res_content_bytes)
        res.content_base64 = btoa(res_content_string)
    } catch (e) {
        res.error = e.toString()
    }

    const res_json = JSON.stringify(res)

    if (res_json.length <= res_len) {
        userhttp.memory.storeString(res_ptr, res_json)
        log("#### buffer ok")
        return res_json.length
    } else {
        // TODO: store res_json somewhere, and quickly return it when called again with large enough buffer;
        // a single value will not be enough (e.g. "last_response"), as multiple requests might be in progress
        // at the same time... maybe we need some request_id
        log("#### buffer too small")
        return -res_json.length
    }
}

function make_url(url, query_params) {
    const result = new URL(url)
    for (const p of query_params || []) {
        result.searchParams.append(p[0], p[1])
    }
    return result
}

function make_headers(header_params) {
    const result = {}
    for (const p of header_params || []) {
        result[p[0]] = p[1]
    }
    return result
}

function make_body(content_params, content_base64) {
    if (content_params && Array.isArray(content_params) && content_params.length > 0) {
        const result = new URLSearchParams()
        for (const p of content_params) {
            result.append(p[0], p[1])
        }
        return new TextEncoder().encode(result.toString())
    } else if (content_base64 && typeof content_base64 == "string" && content_base64.length > 0) {
        return atob(content_base64)
    } else {
        return null
    }
}

window.userhttp = userhttp

})();
