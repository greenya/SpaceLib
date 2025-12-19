app_name		= demo11

arg_spacelib	= -collection:spacelib=../../src
arg_raylib		= -define:RAYLIB_SHARED=true
arg_style		= -strict-style -vet -vet-cast -vet-style -vet-semicolon -warnings-as-errors
arg_all			= ${arg_spacelib} ${arg_raylib} ${arg_style}

debug_args		= ${arg_all} -keep-executable -o:none -debug
release_args	= ${arg_all} -keep-executable -o:speed

.PHONY: run build_windows build_linux build_mac build_web

run:
	@odin run src/platform/desktop -out:build/${app_name}_Debug.exe ${debug_args}

build_windows:
	@odin build src/platform/desktop -out:build/${app_name}_Windows.exe ${release_args}

build_linux:
	@odin build src/platform/desktop -out:build/${app_name}_Linux ${release_args}

build_mac:
	@odin build src/platform/desktop -out:build/${app_name}_Mac ${release_args}

build_web:
	@cd src\platform && build_web.bat

run_web: build_web
	@cd src\platform && run_web_server.bat

# Target for Linux and Mac for testing web build if it compiles at all (as I have Emscripten only on Windows)
build_wasm32:
	@odin build src/platform/web ${arg_all} -out:build/${app_name}.wasm32.o -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o
