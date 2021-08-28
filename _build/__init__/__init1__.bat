@echo off

rem CAUTION:
rem  In case of usage the QtCreator there is set of special broken cases you have to avoid:
rem  1. Invalid characters in paths: `(`, `)` and `.`.
rem  2. Non english locale in paths.

if /i "%TACKLELIB_SCRIPTS_INIT1_DIR%" == "%~dp0" exit /b

set "TACKLELIB_SCRIPTS_INIT1_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

call "%%~dp0__init0__.bat" || exit /b

set "CHECK_CONFIG_VERSION_BARE_FLAGS="
if %IN_GENERATOR_SCRIPT%0 NEQ 0 set CHECK_CONFIG_VERSION_BARE_FLAGS=- optional_compare

call :CMD "%%CONTOOLS_ROOT%%/cmake/check_config_version.bat"%%CHECK_CONFIG_VERSION_BARE_FLAGS%% ^
  "%%CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CONFIG_VARS_SYSTEM_FILE%%" ^
  "%%CONFIG_VARS_USER_FILE_IN%%" "%%CONFIG_VARS_USER_FILE%%" || exit /b

exit /b 0

:CMD
if %INIT_VERBOSE%0 NEQ 0 echo.^>%*
(
  %*
)
exit /b
