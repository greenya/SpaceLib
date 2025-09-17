"use strict";

(function() {

function log(...args) { console.log("[userfs]", ...args) }
function err(...args) { console.error("[userfs]", ...args) }
function tbl(...args) { console.table(...args) }

const localStorage  = window.localStorage
const Uint8Array    = window.Uint8Array

if (!localStorage || !Uint8Array || !Uint8Array.fromBase64) {
    err("localStorage and Uint8Array with fromBase64() must be supported")
    return
}

if (window.userfs !== undefined) {
    err("window.userfs must be undefined; currently script executes multiple times or \"userfs\" is defined by other script")
    return
}

const userfs = {
    app_name    : null,
    memory      : null,

    imports: {
        userfs_init,
        userfs_read,
        userfs_write,
        userfs_delete,
        userfs_reset,
    },

    keys: () => {
        const result = []
        const key_prefix = `${abs_key("")}/`
        for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i)
            if (key.startsWith(key_prefix) && key.length > key_prefix.length) {
                result.push(key.substring(key_prefix.length))
            }
        }
        return result
    },

    info: () => {
        const keys = userfs.keys()
        keys.sort()

        const rows = {}
        let size_total = 0
        for (let k of keys) {
            const size = userfs.query_bytes(k).length
            rows[k] = { size }
            size_total += size
        }

        log(`App: "${userfs.app_name}"`)
        log(`Total keys: ${Number(keys.length).toLocaleString()}`)
        log(`Total bytes: ${Number(size_total).toLocaleString()}`)

        tbl(rows)
    },

    query_bytes: (key) => {
        const data_base64 = localStorage.getItem(abs_key(key))
        if (data_base64)    return Uint8Array.fromBase64(data_base64)
        else                err(`Key "${key}" was not found`)
    },

    query_text: (key) => new TextDecoder().decode(userfs.query_bytes(key)),
}

function userfs_init(app_name_ptr, app_name_len) {
    // log("init", arguments)
    userfs.app_name = userfs.memory.loadString(app_name_ptr, app_name_len)
}

function userfs_read(key_ptr, key_len, buffer_ptr, buffer_len) {
    // log("[read]", arguments)
    const key = userfs.memory.loadString(key_ptr, key_len)

    const data_base64 = localStorage.getItem(abs_key(key))
    if (!data_base64) {
        return 0
    }

    const data_u8arr = Uint8Array.fromBase64(data_base64)
    if (data_u8arr.length <= buffer_len) {
        userfs_memory_storeBytes(buffer_ptr, data_u8arr)
        return data_u8arr.length
    } else {
        return -data_u8arr.length
    }
}

function userfs_write(key_ptr, key_len, data_ptr, data_len) {
    // log("[write]", arguments)
    const key = userfs.memory.loadString(key_ptr, key_len)
    const data_u8arr = userfs.memory.loadBytes(data_ptr, data_len)
    const data_base64 = data_u8arr.toBase64()
    localStorage.setItem(abs_key(key), data_base64)
}

function userfs_delete(key_ptr, key_len) {
    // log("[delete]", arguments)
    const key = userfs.memory.loadString(key_ptr, key_len)
    localStorage.removeItem(abs_key(key))
}

function userfs_reset() {
    // log("[reset]", arguments)
    for (let k of userfs.keys()) {
        localStorage.removeItem(abs_key(k))
    }
}

function abs_key(key) {
    return key
        ? `userfs/${userfs.app_name}/${key}`
        : `userfs/${userfs.app_name}`
}

// WasmMemoryInterface in odin.js does not implement storeBytes(), so we do this
function userfs_memory_storeBytes(addr, value) {
    const dst = new Uint8Array(userfs.memory.memory.buffer, addr, value.length)
    dst.set(value)
}

window.userfs = userfs

})();
