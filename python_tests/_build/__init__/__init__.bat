@echo off

if defined TACKLELIB_PYTHON_TESTS_ROOT_INIT0_DIR if exist "%TACKLELIB_PYTHON_TESTS_ROOT_INIT0_DIR%\*" exit /b 0

call "%%~dp0..\..\__init__\__init__.bat" || exit /b
