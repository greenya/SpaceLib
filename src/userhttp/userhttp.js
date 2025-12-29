"use strict";

(function() {

function log(...args) { console.log("[userhttp]", ...args) }
function err(...args) { console.error("[userhttp]", ...args) }

const fetch             = window.fetch
const JSON              = window.JSON
const Uint8Array        = window.Uint8Array
const AbortController   = window.AbortController

if (!fetch || !JSON || !Uint8Array || !AbortController) {
    err("Fetch API, JSON API, Uint8Array and AbortController must be supported")
    return
}

if (window.userhttp !== undefined) {
    err("window.userhttp must be undefined; currently script executes multiple times or \"userhttp\" is defined by other script")
    return
}

const userhttp = {
    memory  : null,
    imports : {
        userhttp_fetch,
        userhttp_size,
        userhttp_pop,
    },
}

const requests = new Map()

function userhttp_fetch(fetch_id, req_ptr, req_len) {
    // log("fetch", arguments)

    const req_json = userhttp.memory.loadString(req_ptr, req_len)
    const req = JSON.parse(req_json)
    // log("req", req)

    const req_url = make_url(req.url, req.query_params)
    // log("req_url", req_url)

    const req_headers = make_headers(req.header_params)
    // log("req_headers", req_headers)

    const req_body = make_body(req.content_params, req.content_base64)
    // log("req_body (bytes)", req_body ? req_body.length : 0)

    const abort_controller = new AbortController()
    const abort_timeout_id = req.timeout_ms > 0
        ? setTimeout(() => abort_controller.abort(), req.timeout_ms)
        : 0

    requests.set(fetch_id, { pending: true })

    try {
        fetch(req_url, {
            method  : req.method,
            headers : req_headers,
            body    : req_body,
            signal  : abort_controller.signal,
        })
        .then(r => handle_response(fetch_id, r))
        .catch(e => handle_error(fetch_id, e))
        .finally(() => {
            if (abort_timeout_id) { clearTimeout(abort_timeout_id) }
        })
    } catch (e) {
        handle_error(fetch_id, e)
        if (abort_timeout_id) { clearTimeout(abort_timeout_id) }
    }
}

function userhttp_size(fetch_id) {
    // log("size", arguments)

    const data = requests.get(fetch_id)
    return data.json_len ? data.json_len : 0
}

function userhttp_pop(fetch_id, res_ptr, res_len) {
    // log("pop", arguments)

    const data = requests.get(fetch_id)
    requests.delete(fetch_id)

    if (res_len == data.json_len) {
        userhttp.memory.storeString(res_ptr, data.json)
    } else {
        err(`res_len ${res_len} != json_len ${data.json_len}`)
    }
}

async function handle_response(fetch_id, response) {
    const status = response.status

    const header_params = []
    for (const [ name, value ] of response.headers.entries()) {
        header_params.push([ name, value ])
    }

    let content_base64 = null
    try {
        const content_bytes = await response.bytes()
        content_base64 = content_bytes.toBase64()
    } catch (e) {
        handle_error(fetch_id, e)
        return
    }

    request_ready(fetch_id, { status, header_params, content_base64 })
}

function handle_error(fetch_id, data) {
    const error = String(data)
    request_ready(fetch_id, { error })
}

function request_ready(fetch_id, data) {
    const json = JSON.stringify(data)
    const json_len = json.length
    requests.set(fetch_id, { json, json_len })
    userhttp.memory.exports.userhttp_ready(fetch_id, json_len)
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
        return new TextEncoder().encode(atob(content_base64))
    } else {
        return null
    }
}

window.userhttp = userhttp

})();
