@echo off

rem CAUTION:
rem  In case of usage the QtCreator there is set of special broken cases you have to avoid:
rem  1. Invalid characters in paths: `(`, `)` and `.`.
rem  2. Non english locale in paths.

if %SOURCE_ROOT_INIT2_BAT%0 NEQ 0 exit /b

set SOURCE_ROOT_INIT2_BAT=1

call "%%~dp0__init1__.bat" || exit /b

call "%%PROJECT_ROOT%%/_scripts/tools/make_output_directories.bat" "%%CMAKE_BUILD_TYPE%%" "%%GENERATOR_IS_MULTI_CONFIG%%" || exit /b

exit /b 0
