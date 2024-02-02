@echo off

rem Configuration variable files generator script.

setlocal

call "%%~dp0__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

call :CMDINT "%%CONTOOLS_ROOT%%/build/check_config_expiration.bat" -optional_compare ^
  -- "%%CMAKE_CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CMAKE_CONFIG_VARS_SYSTEM_FILE%%" || exit /b

call :CMDINT "%%CONTOOLS_ROOT%%/build/check_config_expiration.bat" -optional_compare ^
  -- "%%CMAKE_CONFIG_VARS_USER_0_FILE_IN%%" "%%CMAKE_CONFIG_VARS_USER_0_FILE%%" || exit /b

set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

exit /b %LASTERROR%

:MAIN
set "CMDLINE_SYSTEM_FILE_IN=%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\config.system%?~x0%.in"
set "CMDLINE_USER_FILE_IN=%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\config.0%?~x0%.in"

for %%i in ("%CMDLINE_SYSTEM_FILE_IN%" "%CMDLINE_USER_FILE_IN%") do (
  set "CMDLINE_FILE_IN=%%i"
  call :GENERATE || exit /b
)

set "CMD_LIST_FILE_IN=%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\cmd_list%?~x0%.in"

rem load command line from file
for /F "usebackq eol=# tokens=1,* delims=|" %%i in ("%CMD_LIST_FILE_IN%") do (
  set "COMMAND=%%i"
  set "CMD_ARGS=%%j"
  call :PROCESS_SCRIPTS
)

exit /b

:GENERATE
rem load command line from file
set "CMAKE_CMD_LINE="
for /F "usebackq eol=# tokens=* delims=" %%i in (%CMDLINE_FILE_IN%) do (
  if defined CMAKE_CMD_LINE (
    setlocal ENABLEDELAYEDEXPANSION & for /F "eol= tokens=* delims=" %%j in ("!CMAKE_CMD_LINE!") do endlocal & set "CMAKE_CMD_LINE=%%j %%i"
  ) else (
    set "CMAKE_CMD_LINE=%%i"
  )
)

call :CMD cmake %CMAKE_CMD_LINE%
exit /b

:PROCESS_SCRIPTS
echo.^>%COMMAND% %CMD_ARGS%

call %COMMAND% %CMD_ARGS% || exit /b
echo.

exit /b 0

:CMD
echo.^>%*
echo.
(
  %*
)
exit /b

:CMDINT
if %INIT_VERBOSE%0 NEQ 0 (
  echo.^>%*
  echo.
)
(
  %*
)
exit /b
