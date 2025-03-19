run: demo3

demo1:
	@if not exist build mkdir build
	@odin run src/demo1 -out:build/demo1.exe -debug -o:none

demo2:
	@if not exist build mkdir build
	@odin run src/demo2 -out:build/demo2.exe -debug -o:none

demo3:
	@if not exist build mkdir build
	@odin run src/demo3 -out:build/demo3.exe -debug -o:none
