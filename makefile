run: demo4

demo1:
	@if not exist build mkdir build
	@odin run demos/demo1 -out:build/demo1.exe -debug -o:none

demo2:
	@if not exist build mkdir build
	@odin run demos/demo2 -out:build/demo2.exe -debug -o:none

demo3:
	@if not exist build mkdir build
	@odin run demos/demo3 -out:build/demo3.exe -debug -o:none

demo4:
	@if not exist build mkdir build
	@odin run demos/demo4 -out:build/demo4.exe -debug -o:none
