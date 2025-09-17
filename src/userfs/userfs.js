"use strict";

// Usage
// -----
// - In Odin, just import the package and call it's members, e.g. userfs.init(), userfs.read() etc
// - In JS, when build is done:
//   | + make sure userfs.js (this file) is copied to the web output (just like odin.js),
//   |   something like this (assuming "SPACELIB_DIR" is path to the source of SpaceLib collection):
//   |   copy %SPACELIB_DIR%\userfs\userfs.js %OUT_DIR%
//   |   note: you don't need the collection, if you want only userfs, copy the package dir to
//   |         your project and just make sure the userfs.js is placed in web output dir
//   | + make sure index.html includes userfs.js, sets memory and the imports, something like this:
//   |   ------------ index.html ------------
//   |   <script src="userfs.js"></script>
//   |   ...
//   |   window.userfs.memory = odinMemory
//   |   odinImports.userfs = window.userfs.imports
//   |   ------------------------------------
//   |   - odinMemory is an instance of odin.WasmMemoryInterface
//   |   - odinImports is from odin.setupDefaultImports(odinMemory)
//   |   note: this must be done before instantiating web assembly (index.wasm)

// window.userfs
// -------------
// Generally you don't need to use JS part to work with the storage, as you develop in Odin and debug
// in a desktop build; and following functionality was added only for easier checking the state of
// the storage in a web browser console:
// - userfs.info() to print current state of the storage, it shows app name and all keys in
//   alphabetical order with actual size of data in bytes for that key
//   note: the size is actual size in bytes in vacuum, e.g. it is not how much data stored in the browser,
//         as it stores also key and extra meta data (presumable); think of it as "these 53 bytes must
//         match file size when running desktop build"
// - userfs.keys() to get all keys storage has
// - userfs.query_bytes() to get array of bytes for a specific key; this should be exact you pass
//   to userfs.write() in Odin as data of []byte
// - userfs.query_text() to get those bytes additionally decoded as text; if you write text (maybe
//   json content), this should correctly decode the original text
// - userfs.imports.reset() to reset the storage (delete all the keys)
//   note: this is not the same as localStorage.clear(), a way to clear all the localStorage for
//         current web site

// Notes
// -----
// Currently we use localStorage, it has limits:
// - 5MB maximum per web site
// - simple key=>value storage where "key" and "value" are strings; even if you use
//   localStorage.setItem("a", {x:1,y:2}), the localStorage.getItem("a") will return string
//   "[object Object]"; this is why we don't emulate tree structure with objects, e.g.
//   localStorage.userfs.app_name.key, as it will not work; instead we build each key like
//   "userfs/app_name/key" (see abs_key())

// TODO: replace localStorage with indexedDB

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
