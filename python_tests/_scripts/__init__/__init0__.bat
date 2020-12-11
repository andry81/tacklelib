@echo off

rem CAUTION:
rem  In case of usage the QtCreator there is set of special broken cases you have to avoid:
rem  1. Invalid characters in paths: `(`, `)` and `.`.
rem  2. Non english locale in paths.

if /i "%TACKLELIB_SCRIPTS_INIT0_DIR%" == "%~dp0" exit /b

set "TACKLELIB_SCRIPTS_INIT0_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

call :CANONICAL_PATH PROJECT_ROOT "%%~dp0..\..\.."
call :CANONICAL_PATH CONTOOLS_ROOT "%%~dp0..\tools"
call :CANONICAL_PATH TESTS_ROOT "%%PROJECT_ROOT%%/python_tests"
call :CANONICAL_PATH TACKLELIB_ROOT "%%PROJECT_ROOT%%/python/tacklelib"
call :CANONICAL_PATH CMDOPLIB_ROOT "%%PROJECT_ROOT%%/python/cmdoplib"
call :CANONICAL_PATH SCRIPTS_LOGS_ROOT "%%TESTS_ROOT%%"

set "CONFIG_VARS_SYSTEM_FILE_IN=%PROJECT_ROOT%/python_tests/_config/environment_system.vars.in"
set "CONFIG_VARS_SYSTEM_FILE=%PROJECT_ROOT%/python_tests/_config/environment_system.vars"

if not defined INIT_VERBOSE set INIT_VERBOSE=0
if not defined TOOLS_VERBOSE set TOOLS_VERBOSE=0
if not defined PRINT_VARS_SET set PRINT_VARS_SET=0

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
