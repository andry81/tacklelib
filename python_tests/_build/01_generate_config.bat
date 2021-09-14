@echo off

rem Configuration variable files generator script.

setlocal

set "?~0=%~0"
set "?~f0=%~f0"
set "?~dp0=%~dp0"
set "?~n0=%~n0"
set "?~nx0=%~nx0"
set "?~x0=%~x0"

call "%%~dp0__init__/__init__.bat" || exit /b

for %%i in (TESTS_PROJECT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%\wmi\get_wmic_local_datetime.bat"
set "PROJECT_LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set "PROJECT_LOG_DIR=%PROJECT_LOG_ROOT%\%PROJECT_LOG_FILE_NAME_SUFFIX%.%?~n0%"
set "PROJECT_LOG_FILE=%PROJECT_LOG_DIR%\%PROJECT_LOG_FILE_NAME_SUFFIX%.%?~n0%.log"

if not exist "%PROJECT_LOG_DIR%" ( mkdir "%PROJECT_LOG_DIR%" || exit /b )

"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe" ^
  /ret-child-exit /pause-on-exit /tee-stdout "%PROJECT_LOG_FILE%" /tee-stderr-dup 1 ^
  /v IMPL_MODE 1 /ra "%%" "%%?01%%" /v "?01" "%%" ^
  "${COMSPEC}" "/c \"@\"%?~f0%\" %*\""
exit /b

:IMPL
call :CMDINT "%%CONTOOLS_ROOT%%/cmake/check_config_version.bat" -optional_compare ^
  "%%CMAKE_CONFIG_VARS_SYSTEM_FILE_IN%%" "%%CMAKE_CONFIG_VARS_SYSTEM_FILE%%" || exit /b

set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

exit /b %LASTERROR%

:MAIN
set "CMDLINE_SYSTEM_FILE_IN=%TESTS_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\config.system%?~x0%.in"

for %%i in ("%CMDLINE_SYSTEM_FILE_IN%") do (
  set "CMDLINE_FILE_IN=%%i"
  call :GENERATE || exit /b
)

set "CMD_LIST_FILE_IN=%TESTS_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\cmd_list%?~x0%.in"

rem load command line from file
for /F "usebackq eol=# tokens=1,* delims=|" %%i in ("%CMD_LIST_FILE_IN%") do (
  set "CMD_PATH=%%i"
  set "CMD_PARAMS=%%j"
  call :PROCESS_COMMAND
)

exit /b

:GENERATE
rem for safe parse
setlocal ENABLEDELAYEDEXPANSION

rem load command line from file
set "CMAKE_CMD_LINE="
for /F "usebackq eol=# tokens=* delims=" %%i in (%CMDLINE_FILE_IN%) do (
  if defined CMAKE_CMD_LINE (
    set "CMAKE_CMD_LINE=!CMAKE_CMD_LINE! %%i"
  ) else (
    set "CMAKE_CMD_LINE=%%i"
  )
)

rem safe variable return over endlocal with delayed expansion
for /F "eol=# tokens=* delims=" %%i in ("!CMAKE_CMD_LINE!") do (
  endlocal
  set "CMAKE_CMD_LINE=%%i"
)

call :CMD cmake %CMAKE_CMD_LINE%
exit /b

:PROCESS_COMMAND
echo.^>"%TESTS_PROJECT_ROOT%/%CMD_PATH%" %CMD_PARAMS%

call "%%TESTS_PROJECT_ROOT%%/%%CMD_PATH%%" %CMD_PARAMS% || exit /b
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
