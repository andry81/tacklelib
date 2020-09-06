@echo off

if /i "%TACKLELIB_SCRIPTS_INIT2_DIR%" == "%~dp0" exit /b

call "%%~dp0__init1__.bat" || exit /b

set "TACKLELIB_SCRIPTS_INIT2_DIR=%~dp0"

call "%%CONTOOLS_ROOT%%/cmake/make_output_directories.bat" "%%CMAKE_BUILD_TYPE%%" "%%GENERATOR_IS_MULTI_CONFIG%%" || exit /b

exit /b 0
