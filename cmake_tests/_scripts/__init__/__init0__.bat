@echo off

call :CANONICAL_PATH PROJECT_ROOT "%%~dp0..\..\.."
call :CANONICAL_PATH TESTS_ROOT "%%PROJECT_ROOT%%/cmake_tests"

set "CONFIG_VARS_SYSTEM_FILE_IN=%PROJECT_ROOT%/cmake_tests/_config/environment_system.vars.in"
set "CONFIG_VARS_SYSTEM_FILE=%PROJECT_ROOT%/cmake_tests/_config/environment_system.vars"

if not defined INIT_VERBOSE set INIT_VERBOSE=0
if not defined TOOLS_VERBOSE set TOOLS_VERBOSE=0
if not defined PRINT_VARS_SET set PRINT_VARS_SET=0

exit /b 0

:CANONICAL_PATH
set "%~1=%~dpf2"
call set "%%~1=%%%~1:\=/%%"
exit /b 0
