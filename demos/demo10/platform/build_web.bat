@echo off

:: ----------------------------------
set ODIN_DIR=c:\odin
set EMSCRIPTEN_DIR=c:\emsdk
set SPACELIB_DIR=..\..\..\src
set OUT_DIR=..\..\..\build\demo10_web
:: ----------------------------------

if not exist %OUT_DIR% mkdir %OUT_DIR%

:: Note RAYLIB_WASM_LIB=env.o -- env.o is an internal WASM object file. You can
:: see how RAYLIB_WASM_LIB is used inside <odin>/vendor/raylib/raylib.odin.
::
:: The emcc call will be fed the actual raylib library file. That stuff will end
:: up in env.o
::
:: Note that there is a rayGUI equivalent: -define:RAYGUI_WASM_LIB=env.o
odin build web ^
    -out:%OUT_DIR%\app.wasm.o ^
    -collection:spacelib=%SPACELIB_DIR% ^
    -o:speed ^
    -target:js_wasm32 ^
    -build-mode:obj ^
    -define:RAYLIB_WASM_LIB=env.o

if %ERRORLEVEL% neq 0 exit /b 1

copy %ODIN_DIR%\core\sys\wasm\js\odin.js %OUT_DIR%
copy %SPACELIB_DIR%\userfs\userfs.js %OUT_DIR%

set EMSDK_QUIET=1
call %EMSCRIPTEN_DIR%\emsdk_env.bat

:: Add `-g` to `emcc` (gives better error callstack in chrome)
::
:: Add `--preload-file assets` if assets folder is used
::
:: Add `%ODIN_DIR%\vendor\raylib\wasm\libraygui.a` when using Raylib GUI
::
:: This uses `cmd /c` to avoid emcc stealing the whole command prompt. Otherwise
:: it does not run the lines that follow it.
::
:: More at: https://emscripten.org/docs/tools_reference/settings_reference.html
cmd /c emcc ^
    -o %OUT_DIR%\index.html ^
    --shell-file web\index_template.html ^
    %OUT_DIR%\app.wasm.o ^
    %ODIN_DIR%\vendor\raylib\wasm\libraylib.a ^
    -sALLOW_MEMORY_GROWTH ^
    -sSTACK_SIZE=65536 ^
    -sINITIAL_HEAP=16777216 ^
    -sWASM_BIGINT ^
    -sWARN_ON_UNDEFINED_SYMBOLS=0 ^
    -sUSE_GLFW=3 ^
    -sEXPORTED_RUNTIME_METHODS=HEAPF32,requestFullscreen
    @REM -sASSERTIONS=2 ^
    @REM -sGL_ASSERTIONS ^
    @REM -sRUNTIME_DEBUG=2 ^
    @REM -sEMSCRIPTEN_TRACING

del %OUT_DIR%\app.wasm.o
