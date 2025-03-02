run:
	@if not exist build mkdir build
	@odin run src -out:build\demo.exe -debug -o:none
