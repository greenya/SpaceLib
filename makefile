ifeq ($(OS),Windows_NT)
	os				= Windows
	os_ext			= .exe
	os_mkdir_build	= @if not exist build mkdir build
else
	os				= $(shell uname)
	os_ext			= .bin
	os_mkdir_build	= @mkdir -p build
endif

collection_args	= -collection:spacelib=src
checker_args 	= -strict-style -vet -vet-cast -vet-style -vet-semicolon

debug_args 		= ${collection_args} ${checker_args} -keep-executable -o:none -debug
release_args 	= ${collection_args} ${checker_args} -keep-executable -o:speed
fastest_args 	= ${collection_args} ${checker_args} -keep-executable -o:speed -no-type-assert -disable-assert -no-bounds-check

run: demo10

mkdir:
	$(call os_mkdir_build)

demo1: mkdir
	@odin run demos/demo1 -out:build/demo1${os_ext} ${debug_args}

demo2: mkdir
	@odin run demos/demo2 -out:build/demo2${os_ext} ${debug_args}

demo3: mkdir
	@odin run demos/demo3 -out:build/demo3${os_ext} ${debug_args}

demo4: mkdir
	@odin run demos/demo4 -out:build/demo4${os_ext} ${debug_args}

demo5: mkdir
	@odin run demos/demo5 -out:build/demo5${os_ext} ${debug_args}

demo6: mkdir
	@odin run demos/demo6 -out:build/demo6${os_ext} ${debug_args}

demo7: mkdir
	@odin run demos/demo7 -out:build/demo7${os_ext} ${debug_args}

demo8: mkdir
	@odin run demos/demo8 -out:build/demo8${os_ext} ${debug_args}

demo9: mkdir
	@odin run demos/demo9/build/desktop -out:build/demo9${os_ext} ${debug_args}

demo9_web:
	@cd demos\demo9\build && web.bat

demo10: mkdir
	@odin run demos/demo10/platform/desktop -out:build/demo10${os_ext} ${debug_args}

demo10_web:
	@cd demos\demo10\platform && build_web.bat
