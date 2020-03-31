@echo off

rem CAUTION:
rem  In case of usage the QtCreator there is set of special broken cases you have to avoid:
rem  1. Invalid characters in paths: `(`, `)` and `.`.
rem  2. Non english locale in paths.

if %SOURCE_ROOT_INIT1_BAT%0 NEQ 0 exit /b

set SOURCE_ROOT_INIT1_BAT=1

if not defined NEST_LVL set NEST_LVL=0

call "%%~dp0__init0__.bat" || exit /b

call :CMD "%%PROJECT_ROOT%%/_scripts/tools/check_config_version.bat" "%%IN_GENERATOR_SCRIPT%%" ^
  "%%CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CONFIG_VARS_SYSTEM_FILE%%" ^
  "%%CONFIG_VARS_USER_FILE_IN%%" "%%CONFIG_VARS_USER_FILE%%" || exit /b

exit /b 0

:CMD
if %INIT_VERBOSE%0 NEQ 0 echo.^>%*
(
  %*
)
exit /b
