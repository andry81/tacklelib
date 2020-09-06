@echo off

if /i "%TACKLELIB_SCRIPTS_INIT1_DIR%" == "%~dp0" exit /b

call "%%~dp0__init0__.bat" || exit /b

set "TACKLELIB_SCRIPTS_INIT1_DIR=%~dp0"

if %IN_GENERATOR_SCRIPT%0 NEQ 0 (
  call :CMD "%%CONTOOLS_ROOT%%/cmake/check_config_version.bat" -optional_system_file_instance -optional_user_file_instance ^
    "%%CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CONFIG_VARS_SYSTEM_FILE%%" ^
    "%%CONFIG_VARS_USER_FILE_IN%%" "%%CONFIG_VARS_USER_FILE%%" || exit /b
) else (
  call :CMD "%%CONTOOLS_ROOT%%/cmake/check_config_version.bat" ^
    "%%CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CONFIG_VARS_SYSTEM_FILE%%" ^
    "%%CONFIG_VARS_USER_FILE_IN%%" "%%CONFIG_VARS_USER_FILE%%" || exit /b
)

exit /b 0

:CMD
if %INIT_VERBOSE%0 NEQ 0 echo.^>%*
(
  %*
)
exit /b
