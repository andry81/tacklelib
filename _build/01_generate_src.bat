@echo off

rem Source files generator script.

setlocal

call "%%~dp0__init__/__init__.bat" || exit /b

call "%%TACKLELIB_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

for %%i in (TACKLELIB_PROJECT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

"%CONTOOLS_UTILITIES_BIN_ROOT%/contools/callf.exe" ^
  /ret-child-exit /pause-on-exit /tee-stdout "%PROJECT_LOG_FILE%" /tee-stderr-dup 1 ^
  /v IMPL_MODE 1 /ra "%%" "%%?01%%" /v "?01" "%%" ^
  "${COMSPEC}" "/c \"@\"${?~f0}\" {*}\"" %* || exit /b

exit /b 0

:IMPL
set /A NEST_LVL+=1

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

set /A NEST_LVL-=1

exit /b %LASTERROR%

:MAIN
set "GEN_FILE_LIST_IN=%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\gen_file_list.in"

rem load command line from file
for /F "usebackq eol=# tokens=1,* delims=|" %%i in ("%GEN_FILE_LIST_IN%") do (
  set "FROM_FILE=%%i"
  set "TO_FILE=%%j"
  call :GENERATE_FILE
)

set "CMD_LIST_FILE_IN=%TESTS_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\cmd_list%?~x0%.in"

rem load command line from file
for /F "usebackq eol=# tokens=1,* delims=|" %%i in ("%CMD_LIST_FILE_IN%") do (
  set "CMD_PATH=%%i"
  set "CMD_PARAMS=%%j"
  call :PROCESS_COMMAND
)

exit /b

:GENERATE_FILE
echo."%PROJECT_ROOT%/%FROM_FILE%" -^> "%PROJECT_ROOT%/%TO_FILE%"
(
  type "%PROJECT_ROOT:/=\%\%FROM_FILE:/=\%"
) > "%PROJECT_ROOT%/%TO_FILE%"

exit /b

:PROCESS_COMMAND
echo.^>"%PROJECT_ROOT%/%CMD_PATH%" %CMD_PARAMS%

call "%%PROJECT_ROOT%%/%%CMD_PATH%%" %CMD_PARAMS% || exit /b
echo.

exit /b 0
