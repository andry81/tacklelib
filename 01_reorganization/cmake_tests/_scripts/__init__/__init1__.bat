@echo off

if /i "%TACKLELIB_CMAKE_TESTS_SCRIPTS_INIT1_DIR%" == "%~dp0" exit /b

call "%%~dp0__init0__.bat" || exit /b

set "TACKLELIB_CMAKE_TESTS_SCRIPTS_INIT1_DIR=%~dp0"

if %IN_GENERATOR_SCRIPT%0 NEQ 0 (
  call :CMD "%%PROJECT_ROOT%%/cmake_tests/_scripts/tools/check_config_version.bat" -optional_system_file_instance -optional_user_file_instance ^
    "%%CMAKE_CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CMAKE_CONFIG_VARS_SYSTEM_FILE%%" || exit /b
) else (
  call :CMD "%%PROJECT_ROOT%%/cmake_tests/_scripts/tools/check_config_version.bat" ^
    "%%CMAKE_CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CMAKE_CONFIG_VARS_SYSTEM_FILE%%" || exit /b
)

exit /b 0

:CMD
if %INIT_VERBOSE%0 NEQ 0 echo.^>%*
(
  %*
)
exit /b
