@echo off

rem CAUTION:
rem  In case of usage the QtCreator there is set of special broken cases you have to avoid:
rem  1. Invalid characters in paths: `(`, `)` and `.`.
rem  2. Non english locale in paths.

if not defined NEST_LVL set NEST_LVL=0

call :CANONICAL_PATH PROJECT_ROOT "%%~dp0..\.."
call :CANONICAL_PATH CONTOOLS_ROOT "%%~dp0..\tools"
call :CANONICAL_PATH SCRIPTS_LOGS_ROOT "%%PROJECT_ROOT%%"

set "CONFIG_VARS_SYSTEM_FILE_IN=%PROJECT_ROOT%/_config/environment_system.vars.in"
set "CONFIG_VARS_SYSTEM_FILE=%PROJECT_ROOT%/_config/environment_system.vars"
set "CONFIG_VARS_USER_FILE_IN=%PROJECT_ROOT%/_config/environment_user.vars.in"
set "CONFIG_VARS_USER_FILE=%PROJECT_ROOT%/_config/environment_user.vars"

if not defined INIT_VERBOSE set INIT_VERBOSE=0
if not defined TOOLS_VERBOSE set TOOLS_VERBOSE=0
if not defined PRINT_VARS_SET set PRINT_VARS_SET=0

exit /b 0

:CANONICAL_PATH
set "%~1=%~dpf2"
call set "%%~1=%%%~1:\=/%%"
exit /b 0
