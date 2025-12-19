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

function userhttp_send(req_ptr, req_len, res_ptr, res_len) {
    log("send", arguments)

    const req_json = userhttp.memory.loadString(req_ptr, req_len)
    const req = JSON.parse(req_json)
    log("req", req)

    // TODO: do the fetch() call, wait for the response, return the result
    // TODO: return amount of bytes used in the res_ptr
    // TODO: return -1 if buffer too small (?)

    return 0
}

window.userhttp = userhttp

})();
