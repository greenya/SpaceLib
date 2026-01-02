# userhttp

A way to send HTTP requests both in a web browser and in a desktop environment. On desktop, it uses `cURL`, while on the web it relies on the browser's `Fetch API`.

Check **SpaceLib Demo 11** to see it [in action](https://spacemad.itch.io/spacelib-demo-11) and [it's source](https://github.com/greenya/SpaceLib/tree/main/demos/demo11).

## Usage

- In Odin, import the package and call it's members:

    + `userhttp.init()` once at the start of the app
    + `userhttp.destroy()` once at the end of the app
    + `userhttp.tick()` periodically inside update loop of the app
    + `userhttp.send_request()` to send a request

    A common usage might look like this:
    ```odin
    import "spacelib:userhttp"

    main :: proc () {
        userhttp.init({ default_timeout_ms=10_000 })

        for /*...game loop is running ...*/ {
            userhttp.tick()

            if /*...should send request...*/ {
                userhttp.send_request({
                    url     = "https://some/url/goes/here",
                    ready   = proc (req: ^userhttp.Request) {
                        if req.error == nil { /* all good, use req.response */ }
                        // you also can print all the request details any time regardless of its state using userhttp.print_request(req)
                    },
                })
            }
        }

        userhttp.destroy()
    }
    ```

- In JS, when build is done:

    + make sure `userhttp.js` is copied to the web output (just like `odin.js`), something like this (assuming `SPACELIB_DIR` is path to the `src` dir of SpaceLib collection):
        ```cmd
        copy %SPACELIB_DIR%\userhttp\userhttp.js %OUT_DIR%
        ```
        __Note__: you don't need the collection, if you want only `userhttp`, copy the package dir to your project and just make sure the `userhttp.js` is placed in web output dir; you can do it once manually in case your web output dir will not be wiped.

    + make sure `index.html` includes `userhttp.js`, sets memory and the imports, something like this:
        ```html
        <script src="userhttp.js"></script>
        <!-- ... -->
        <script>
            // ...
            window.userhttp.memory = odinMemory
            odinImports.userhttp = window.userhttp.imports
        </script>
        ```
        - `odinMemory` is an instance of `odin.WasmMemoryInterface`
        - `odinImports` is from `odin.setupDefaultImports(odinMemory)`
        - __Note__: this must be done before instantiating web assembly (`index.wasm`).
