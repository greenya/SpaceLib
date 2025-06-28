collection_args	= -collection:spacelib=src
checker_args 	= -strict-style -vet -vet-cast -vet-style -vet-semicolon
debug_args 		= ${collection_args} ${checker_args} -debug -o:none -keep-executable
release_args 	= ${collection_args} ${checker_args} -o:speed -keep-executable

run: demo9

mkdir:
	@if not exist build mkdir build

demo1: mkdir
	@odin run demos/demo1 -out:build/demo1.exe ${debug_args}

demo2: mkdir
	@odin run demos/demo2 -out:build/demo2.exe ${debug_args}

demo3: mkdir
	@odin run demos/demo3 -out:build/demo3.exe ${debug_args}

demo4: mkdir
	@odin run demos/demo4 -out:build/demo4.exe ${debug_args}

demo5: mkdir
	@odin run demos/demo5 -out:build/demo5.exe ${debug_args}

demo6: mkdir
	@odin run demos/demo6 -out:build/demo6.exe ${debug_args}

demo7: mkdir
	@odin run demos/demo7 -out:build/demo7.exe ${debug_args}

demo8: mkdir
	@odin run demos/demo8 -out:build/demo8.exe ${debug_args}

demo9: mkdir
	@odin run demos/demo9 -out:build/demo9.exe ${debug_args}
