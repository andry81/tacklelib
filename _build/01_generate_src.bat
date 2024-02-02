@echo off

rem Source files generator script.

setlocal

call "%%~dp0__init__/script_init.bat" %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

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

set "CMD_LIST_FILE_IN=%TACKLELIB_PROJECT_INPUT_CONFIG_ROOT%\_build\%?~n0%\cmd_list%?~x0%.in"

rem load command line from file
for /F "usebackq eol=# tokens=1,* delims=|" %%i in ("%CMD_LIST_FILE_IN%") do (
  set "CMD_PATH=%%i"
  set "CMD_PARAMS=%%j"
  call :PROCESS_COMMAND
)

exit /b

:GENERATE_FILE
echo."%TACKLELIB_PROJECT_ROOT%/%FROM_FILE%" -^> "%TACKLELIB_PROJECT_ROOT%/%TO_FILE%"
(
  type "%TACKLELIB_PROJECT_ROOT:/=\%\%FROM_FILE:/=\%"
) > "%TACKLELIB_PROJECT_ROOT%/%TO_FILE%"

exit /b

:PROCESS_COMMAND
echo.^>"%TACKLELIB_PROJECT_ROOT%/%CMD_PATH%" %CMD_PARAMS%

call "%%TACKLELIB_PROJECT_ROOT%%/%%CMD_PATH%%" %CMD_PARAMS% || exit /b
echo.

exit /b 0
