collection_args	= -collection:spacelib=d:/dev/SpaceLib/src
checker_args 	= -strict-style -vet -vet-cast -vet-style -vet-semicolon
debug_args 		= ${collection_args} ${checker_args} -debug -o:none
release_args 	= ${collection_args} ${checker_args} -o:speed

run: demo4

demo1:
	@if not exist build mkdir build
	@odin run demos/demo1 -out:build/demo1.exe ${debug_args}

demo2:
	@if not exist build mkdir build
	@odin run demos/demo2 -out:build/demo2.exe ${debug_args}

demo3:
	@if not exist build mkdir build
	@odin run demos/demo3 -out:build/demo3.exe ${debug_args}

demo4:
	@if not exist build mkdir build
	@odin run demos/demo4 -out:build/demo4.exe ${debug_args}
