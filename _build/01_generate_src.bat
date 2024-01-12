@echo off

rem Source files generator script.

setlocal

if %IMPL_MODE%0 NEQ 0 goto IMPL

call "%%~dp0__init__/__init__.bat" || exit /b

call "%%TACKLELIB_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%* || exit /b

for %%i in (TACKLELIB_PROJECT_ROOT PROJECT_LOG_ROOT CONTOOLS_ROOT CONTOOLS_UTILITIES_BIN_ROOT) do (
  if not defined %%i (
    echo.%~nx0: error: `%%i` variable is not defined.
    exit /b 255
  ) >&2
)

call "%%CONTOOLS_ROOT%%/build/init_project_log.bat" "%%?~n0%%" || exit /b

call "%%CONTOOLS_ROOT%%/exec/exec_callf_prefix.bat" -- %%* || exit /b

exit /b 0

:IMPL
rem CAUTION: We must to reinit the builtin variables in case if `IMPL_MODE` was already setup outside.
call "%%CONTOOLS_ROOT%%/std/declare_builtins.bat" %%0 %%* || exit /b

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" %%?0%% %%*
call "%%CONTOOLS_ROOT%%/std/echo_var.bat" RETURN_VALUE ">"
echo.

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
