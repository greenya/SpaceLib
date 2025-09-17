# userfs

A way to save and load small files in the web browser and a desktop environment. If you don't do a web build, you don't need this package. When building for desktop, the `userfs` uses `os.user_data_dir()` as base path, while on web, it uses `localStorage` of the web browser.

## Usage

- In Odin, import the package and call it's members, e.g. `userfs.init()`, `userfs.read()` etc.

- In JS, when build is done:
    + make sure `userfs.js` is copied to the web output (just like `odin.js`), something like this (assuming `SPACELIB_DIR` is path to the `src` dir of SpaceLib collection):
        ```cmd
        copy %SPACELIB_DIR%\userfs\userfs.js %OUT_DIR%
        ```
      __Note__: you don't need the collection, if you want only `userfs`, copy the package dir to your project and just make sure the `userfs.js` is placed in web output dir; you can do it once manually in case your web output fir never gets wiped.
    + make sure `index.html` includes `userfs.js`, sets memory and the imports, something like this:
        ```html
        <script src="userfs.js"></script>
        <!-- ... -->
        <script>
            // ...
            window.userfs.memory = odinMemory
            odinImports.userfs = window.userfs.imports
        </script>
        ```
    - `odinMemory` is an instance of odin.`WasmMemoryInterface`
    - `odinImports` is from `odin.setupDefaultImports(odinMemory)`
    - __Note__: this must be done before instantiating web assembly (`index.wasm`).

## window.userfs

Generally you don't need to use JS part to work with the storage, as you develop in Odin and debug a desktop build. Following functionality allows quick and easy check the status of the storage in the web browser console:

- `userfs.info()` to print current state of the storage, it shows app name and all keys in alphabetical order with actual size of data in bytes for that key.

    __Note__: the size is actual size in bytes in vacuum, e.g. it is not how much data stored in the browser, as it stores also key and extra meta data (presumable); think of it as "these 53 bytes must match file size when running desktop build"

- `userfs.keys()` to get all keys storage has
- `userfs.query_bytes()` to get array of bytes for a specific key; this should be exact you pass to `userfs.write()` in Odin as data of `[]byte`
- `userfs.query_text()` to get those bytes additionally decoded as text; if you write text (maybe json content), this should correctly decode the original text
- `userfs.imports.reset()` to reset the storage (delete all the keys).

    __Note__: this is not the same as localStorage.clear(), a way to clear all the localStorage for current web site

## Comments

Currently we use `localStorage`, it has limits:
- 5MB maximum per web site
- Simple `key=>value` storage where `key` and `value` are strings; even if you use `localStorage.setItem("a", {x:1,y:2})`, the `localStorage.getItem("a")` will return string `[object Object]`; this is why we don't emulate tree structure with objects, e.g. `localStorage.userfs.app_name.key`, as it will not work; instead we build each key like `userfs/app_name/key`
