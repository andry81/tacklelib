@echo off

if defined TACKLELIB_PROJECT_BUILD_ROOT_INIT0_DIR if exist "%TACKLELIB_PROJECT_BUILD_ROOT_INIT0_DIR%\*" exit /b 0

call "%%~dp0..\..\__init__\__init__.bat" || exit /b
