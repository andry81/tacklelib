@echo off

if /i "%TACKLELIB_SCRIPTS_INIT0_DIR%" == "%~dp0" exit /b

call "%%~dp0__init__.bat" || exit

set "TACKLELIB_SCRIPTS_INIT0_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

call :CANONICAL_PATH TESTS_ROOT     "%%PROJECT_ROOT%%/python_tests"
call :CANONICAL_PATH TACKLELIB_ROOT "%%PROJECT_ROOT%%/python/tacklelib"
call :CANONICAL_PATH CMDOPLIB_ROOT  "%%PROJECT_ROOT%%/python/cmdoplib"

set "CONFIG_VARS_SYSTEM_FILE_IN=%PROJECT_ROOT%/python_tests/_config/environment_system.vars.in"
set "CONFIG_VARS_SYSTEM_FILE=%PROJECT_ROOT%/python_tests/_config/environment_system.vars"

if not defined INIT_VERBOSE set INIT_VERBOSE=0
if not defined TOOLS_VERBOSE set TOOLS_VERBOSE=0
if not defined PRINT_VARS_SET set PRINT_VARS_SET=0

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
set "RETURN_VALUE=%~dpf2"
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
if "%RETURN_VALUE:~-1%" == "/" set "RETURN_VALUE=%RETURN_VALUE:~0,-1%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
