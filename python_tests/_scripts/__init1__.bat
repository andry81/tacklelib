@echo off

if not defined NEST_LVL set NEST_LVL=0

call "%%~dp0__init0__.bat" || exit /b

call :CMD "%%PROJECT_ROOT%%/python_tests/_scripts/tools/check_config_version.bat" "%%IN_GENERATOR_SCRIPT%%" ^
  "%%CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CONFIG_VARS_SYSTEM_FILE%%" || exit /b

exit /b 0

:CMD
if %INIT_VERBOSE%0 NEQ 0 echo.^>%*
(
  %*
)
exit /b
